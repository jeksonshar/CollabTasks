import * as admin from "firebase-admin";
import {onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

const FALLBACK_STALE_MS = 2 * 60 * 1000;
const FAST_RECONCILIATION_STALE_MS = 30 * 1000;

type ParticipantData = { userId?: string; status?: string };
type CallData = {
    status?: string;
    isGroup?: boolean;
    callerId?: string;
    calleeIds?: unknown[];
    participantsByUser?: Record<string, ParticipantData>;
};

/**
 * Normalizes emails while preserving the case-sensitive Firebase UID form.
 * @param {string} value Raw participant identifier.
 * @return {string} Normalized identifier.
 */
function normalizeIdentity(value: string): string {
    const trimmed = value.trim();
    return trimmed.includes("@") ? trimmed.toLowerCase() : trimmed;
}

/**
 * Returns the keyed participant records for a call document.
 * @param {CallData} call Firestore call data.
 * @return {Record<string, ParticipantData>} Keyed participant data.
 */
function participantMap(call: CallData): Record<string, ParticipantData> {
    const value = call.participantsByUser;
    return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

/**
 * Tests a stored participant identifier against authenticated identities.
 * @param {unknown} candidate Stored identifier.
 * @param {Set<string>} identities Authenticated user identifiers.
 * @return {boolean} Whether the identifier belongs to the authenticated user.
 */
function isIdentityMatch(candidate: unknown, identities: Set<string>): boolean {
    return typeof candidate === "string" && identities.has(normalizeIdentity(candidate));
}

/**
 * Seeds a participant heartbeat when a call transition marks them connected.
 *
 * @param {string} callId Firestore call document ID.
 * @param {string} participantId Canonical participant map key.
 * @param {admin.firestore.Timestamp} observedAt Time the call change occurred.
 * @return {Promise<void>} Resolves after the heartbeat is stored or logs failure.
 */
export async function seedConnectedParticipantHeartbeat(
    callId: string,
    participantId: string,
    observedAt: admin.firestore.Timestamp
): Promise<void> {
    const heartbeatRef = admin.firestore().collection("calls").doc(callId)
        .collection("heartbeats").doc(participantId);
    try {
        await admin.firestore().runTransaction(async (transaction) => {
            const snapshot = await transaction.get(heartbeatRef);
            const lastSeenAt = snapshot.data()?.lastSeenAt;
            if (lastSeenAt instanceof admin.firestore.Timestamp &&
                lastSeenAt.toMillis() >= observedAt.toMillis()) return;
            transaction.set(heartbeatRef, {lastSeenAt: observedAt});
        });
    } catch (error) {
        // Liveness bookkeeping must never prevent incoming-call push delivery.
        console.error(`[callHeartbeat] Failed to seed ${participantId} for ${callId}:`, error);
    }
}

/**
 * Reconciles connected participants against server-written heartbeats. A live
 * client can invoke this periodically, so cleanup does not depend on Agora's
 * delayed onUserOffline callback.
 */
export const reconcileStaleCallParticipants = onRequest(
    {cors: true, region: "europe-central2"},
    async (req, res) => {
        if (req.method !== "POST") {
            res.status(405).json({error: "Method not allowed"});
            return;
        }
        const authHeader = req.headers.authorization || "";
        if (!authHeader.startsWith("Bearer ")) {
            res.status(401).json({error: "Missing or invalid Authorization header"});
            return;
        }

        let decodedToken: admin.auth.DecodedIdToken;
        try {
            decodedToken = await admin.auth().verifyIdToken(authHeader.substring(7));
        } catch (error) {
            console.warn("[reconcileStaleCallParticipants] Invalid Firebase ID token", error);
            res.status(401).json({error: "Unauthorized"});
            return;
        }

        const body = req.body as { callId?: unknown };
        const callId = typeof body?.callId === "string" ? body.callId.trim() : "";
        if (!callId) {
            res.status(400).json({error: "callId is required"});
            return;
        }

        const actorIdentities = new Set<string>([decodedToken.uid]);
        if (typeof decodedToken.email === "string" && decodedToken.email.trim()) {
            actorIdentities.add(normalizeIdentity(decodedToken.email));
        }
        const callRef = admin.firestore().collection("calls").doc(callId);
        const staleBeforeMillis = Date.now() - FAST_RECONCILIATION_STALE_MS;

        try {
            const updatedParticipantIds = await admin.firestore().runTransaction(async (transaction) => {
                const callSnapshot = await transaction.get(callRef);
                if (!callSnapshot.exists) return [] as string[];
                const call = callSnapshot.data() as CallData | undefined;
                if (!call || call.status !== "active") return [] as string[];

                const participants = participantMap(call);
                const actorEntry = Object.entries(participants).find(([key, participant]) =>
                    participant?.status === "connected" &&
                    (isIdentityMatch(key, actorIdentities) ||
                        isIdentityMatch(participant.userId, actorIdentities))
                );
                if (!actorEntry) return [] as string[];
                const otherConnectedEntries = Object.entries(participants).filter(([key, participant]) =>
                    participant?.status === "connected" &&
                    !isIdentityMatch(key, actorIdentities) &&
                    !isIdentityMatch(participant.userId, actorIdentities)
                );
                const heartbeatRefs = otherConnectedEntries.map(([key]) =>
                    callRef.collection("heartbeats").doc(key));
                const heartbeatSnapshots = await Promise.all(heartbeatRefs.map((ref) =>
                    transaction.get(ref)));
                const staleEntries = otherConnectedEntries.filter((_, index) => {
                    const lastSeenAt = heartbeatSnapshots[index]?.data()?.lastSeenAt;
                    return lastSeenAt instanceof admin.firestore.Timestamp &&
                        lastSeenAt.toMillis() <= staleBeforeMillis;
                });
                if (staleEntries.length === 0) return [] as string[];

                if (call.isGroup === true) {
                    const updatedParticipants = {
                        ...participants,
                        ...Object.fromEntries(staleEntries.map(([key, participant]) =>
                            [key, {...participant, status: "left"}])),
                    };
                    const targetIdentities = new Set(staleEntries.flatMap(([key, participant]) => [
                        normalizeIdentity(key),
                        ...(typeof participant.userId === "string" ?
                            [normalizeIdentity(participant.userId)] : []),
                    ]));
                    const calleeIds = Array.isArray(call.calleeIds) ?
                        call.calleeIds.filter((id) => !isIdentityMatch(id, targetIdentities)) : [];
                    transaction.update(callRef, {participantsByUser: updatedParticipants, calleeIds});
                } else {
                    transaction.update(callRef, {status: "ended", endedAtMillis: Date.now()});
                }
                for (const [key] of staleEntries) {
                    transaction.delete(callRef.collection("heartbeats").doc(key));
                }
                return staleEntries.map(([key]) => key);
            });
            res.status(200).json({updatedParticipantIds});
        } catch (error) {
            console.error(`[reconcileStaleCallParticipants] Failed for ${callId}:`, error);
            res.status(500).json({error: "Failed to reconcile call participant"});
        }
    }
);

/**
 * Fallback cleanup for calls with no surviving client able to reconcile the
 * call (for example, when every client process was killed).
 */
export const expireStaleCallParticipants = onSchedule(
    {schedule: "every 1 minutes", region: "europe-central2"},
    async () => {
        const db = admin.firestore();
        const staleBefore = admin.firestore.Timestamp.fromMillis(Date.now() - FALLBACK_STALE_MS);
        const staleHeartbeats = await db.collectionGroup("heartbeats")
            .where("lastSeenAt", "<=", staleBefore)
            .limit(500)
            .get();

        for (const heartbeat of staleHeartbeats.docs) {
            const callRef = heartbeat.ref.parent.parent;
            if (!callRef || callRef.parent.id !== "calls") continue;
            const participantId = heartbeat.id;
            try {
                await db.runTransaction(async (transaction) => {
                    const [callSnapshot, heartbeatSnapshot] = await Promise.all([
                        transaction.get(callRef),
                        transaction.get(heartbeat.ref),
                    ]);
                    if (!heartbeatSnapshot.exists) return;
                    const call = callSnapshot.data() as CallData | undefined;
                    const heartbeatData = heartbeatSnapshot.data();
                    if (!call) {
                        transaction.delete(heartbeat.ref);
                        return;
                    }
                    const lastSeenAt = heartbeatData?.lastSeenAt;
                    if (!(lastSeenAt instanceof admin.firestore.Timestamp) ||
                        lastSeenAt.toMillis() > Date.now() - FALLBACK_STALE_MS) return;

                    const participants = participantMap(call);
                    const participant = participants[participantId];
                    if (call.status !== "active" || participant?.status !== "connected") {
                        transaction.delete(heartbeat.ref);
                        return;
                    }
                    if (call.isGroup === true) {
                        const updatedParticipants = {
                            ...participants,
                            [participantId]: {...participant, status: "left"},
                        };
                        const targetIds = new Set([
                            normalizeIdentity(participantId),
                            ...(typeof participant.userId === "string" ?
                                [normalizeIdentity(participant.userId)] : []),
                        ]);
                        const calleeIds = Array.isArray(call.calleeIds) ?
                            call.calleeIds.filter((id) => !isIdentityMatch(id, targetIds)) : [];
                        transaction.update(callRef, {
                            participantsByUser: updatedParticipants,
                            calleeIds,
                        });
                    } else {
                        transaction.update(callRef, {status: "ended", endedAtMillis: Date.now()});
                    }
                    transaction.delete(heartbeat.ref);
                });
            } catch (error) {
                console.error(`[expireStaleCallParticipants] Failed to expire ${participantId} in ${callRef.id}:`, error);
            }
        }
        console.log(`[expireStaleCallParticipants] Processed ${staleHeartbeats.size} stale heartbeat(s)`);
    }
);

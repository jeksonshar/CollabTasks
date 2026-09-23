import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {RtcTokenBuilder, RtcRole} from "agora-token";

admin.initializeApp();

// ============================================================================
// 0. AGORA RTC TOKEN GENERATOR
// ============================================================================
//
// POST https://us-central1-collabtasks-fda3f.cloudfunctions.net/getAgoraRtcToken
//
// Headers:
//   Authorization: Bearer <Firebase ID token>
//   Content-Type: application/json
//
// Body: { "channelName": "<callId>", "uid": 0 }
//
// Response: { "token": "<Agora AccessToken2>", "uid": 0, "channelName": "..." }
//
export const getAgoraRtcToken = onRequest(
    {cors: true},
    async (req, res) => {
        // Only allow POST
        if (req.method !== "POST") {
            res.status(405).json({error: "Method not allowed"});
            return;
        }

        // Verify Firebase ID token from Authorization header
        const authHeader = req.headers.authorization || "";
        if (!authHeader.startsWith("Bearer ")) {
            res.status(401).json({error: "Missing or invalid Authorization header"});
            return;
        }

        const idToken = authHeader.split("Bearer ")[1];
        try {
            await admin.auth().verifyIdToken(idToken);
        } catch (err) {
            console.error("[getAgoraRtcToken] Invalid ID token:", err);
            res.status(401).json({error: "Unauthorized"});
            return;
        }

        // Read Agora credentials from process.env
        // Set these in functions/.env.collabtasks-fda3f (never commit to git!)
        const appId = (process.env.AGORA_APP_ID || "").trim();
        const appCertificate = (process.env.AGORA_APP_CERTIFICATE || "").trim();

        if (!appId || !appCertificate) {
            console.error("[getAgoraRtcToken] AGORA_APP_ID or AGORA_APP_CERTIFICATE not set");
            res.status(500).json({error: "Agora credentials not configured on server"});
            return;
        }

        const body = req.body as {channelName?: string; uid?: number | string};
        const channelName = (body.channelName || "").trim();
        const uid = typeof body.uid === "number" ? body.uid : (parseInt(String(body.uid || 0), 10) || 0);

        if (!channelName) {
            res.status(400).json({error: "channelName is required"});
            return;
        }

        // Token and privilege expiry duration in seconds from NOW (max 24 hours = 86400 seconds)
        const expirationInSeconds = 86400;

        try {
            const token = RtcTokenBuilder.buildTokenWithUid(
                appId,
                appCertificate,
                channelName,
                uid,
                RtcRole.PUBLISHER,
                expirationInSeconds,
                expirationInSeconds,
            );

            if (!token) {
                console.error("[getAgoraRtcToken] Token build returned empty string. Verify AGORA_APP_ID and AGORA_APP_CERTIFICATE are valid 32-hex UUIDs.");
                res.status(500).json({error: "Failed to generate token - invalid App ID or Certificate format"});
                return;
            }

            console.log(`[getAgoraRtcToken] Token generated for channel=${channelName}, uid=${uid}, length=${token.length}`);
            res.status(200).json({token, uid, channelName});
        } catch (err) {
            console.error("[getAgoraRtcToken] Token build error:", err);
            res.status(500).json({error: "Failed to generate token"});
        }
    }
);

// ============================================================================
// 1. ТРИГГЕР ДЛЯ ЛИЧНЫХ ЧАТОВ (Остался без изменений)
// ============================================================================
export const onNewMessageSent = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return;

        const messageData = snapshot.data();
        if (!messageData) return;

        const chatId = event.params.chatId;
        const senderId = messageData.senderId;
        const text = messageData.text || "Изображение или файл";

        try {
            const chatDoc = await admin.firestore()
                .collection("chats")
                .doc(chatId)
                .get();
            const chatData = chatDoc.data();
            if (!chatData) return;

            const participantIds: string[] = chatData.participantIds || [];

            const recipientEmail = participantIds.find((id) => id !== senderId);
            if (!recipientEmail) {
                console.log(`Получатель не найден в чате ${chatId}`);
                return;
            }

            const userQuery = await admin.firestore()
                .collection("users")
                .where("email", "==", recipientEmail)
                .limit(1)
                .get();

            if (userQuery.empty) {
                console.log(`Email ${recipientEmail} не найден в Firestore`);
                return;
            }

            const recipientUid = userQuery.docs[0].id;

            const tokensSnapshot = await admin.firestore()
                .collection("users")
                .doc(recipientUid)
                .collection("tokens")
                .get();

            if (tokensSnapshot.empty) {
                console.log(`Нет FCM-токенов для UID: ${recipientUid}`);
                return;
            }

            const tokens: string[] = [];
            tokensSnapshot.forEach((doc) => {
                const token = doc.data().token;
                if (token) tokens.push(token);
            });

            if (tokens.length === 0) return;

            let senderName = "Новое сообщение";

            const senderQuery = await admin.firestore()
                .collection("users")
                .where("email", "==", senderId)
                .limit(1)
                .get();

            if (!senderQuery.empty) {
                senderName = senderQuery.docs[0].data()?.name || "Новое сообщение";
            }

            const messagePayload: admin.messaging.MulticastMessage = {
                tokens: tokens,
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    chatId: chatId,
                    type: "chat_message",
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "chats_messages_channel",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            const response = await admin.messaging()
                .sendEachForMulticast(messagePayload);
            console.log(`Отправлено личных уведомлений: ${response.successCount}`);
        } catch (error) {
            console.error("Ошибка при обработке триггера личного чата:", error);
        }
    }
);

// ============================================================================
// 2. ТРИГГЕР ДЛЯ ГРУППОВЫХ ЧАТОВ (Working Groups)
// ============================================================================
export const onNewGroupMessageSent = onDocumentCreated(
    "workingGroups/{groupId}/messages/{messageId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return;

        const messageData = snapshot.data();
        if (!messageData) return;

        const groupId = event.params.groupId;
        // Оставляем оригинальный senderId (регистр может быть важен)
        const senderId = String(messageData.senderId || "").trim();
        const senderIdLower = senderId.toLowerCase();
        const senderName = messageData.senderName || "Участник группы";
        const text = messageData.text || "Изображение или файл";

        try {
            const groupDocRef = admin.firestore().collection("workingGroups").doc(groupId);
            const groupDoc = await groupDocRef.get();
            if (!groupDoc.exists) return;

            const groupData = groupDoc.data() || {};
            let recipientIdentifiers: string[] = [];

            if (Array.isArray(groupData.participantIds) && groupData.participantIds.length > 0) {
                recipientIdentifiers = groupData.participantIds;
            } else {
                const participantsSnapshot = await groupDocRef.collection("participants").get();
                participantsSnapshot.forEach((doc) => {
                    const data = doc.data();
                    if (doc.id) recipientIdentifiers.push(doc.id);
                    if (data.email) recipientIdentifiers.push(data.email);
                    if (data.userId) recipientIdentifiers.push(data.userId);
                });
            }

            // Находим UID отправителя (если senderId — это email)
            let senderUid = "";
            if (senderIdLower.includes("@")) {
                const senderQuery = await admin.firestore()
                    .collection("users")
                    .where("email", "==", senderIdLower)
                    .limit(1)
                    .get();
                if (!senderQuery.empty) {
                    senderUid = senderQuery.docs[0].id; // Сохраняем ТОЧНЫЙ регистр UID
                }
            } else {
                senderUid = senderId;
            }

            // Точная фильтрация без использования риска includes()
            const filteredRecipients = recipientIdentifiers.filter((id) => {
                const cleanId = String(id).trim();
                if (!cleanId) return false;

                const cleanIdLower = cleanId.toLowerCase();

                // Фильтруем точное совпадение по email или UID
                if (cleanIdLower === senderIdLower) return false;
                return !(senderUid && cleanId === senderUid);
            });

            const uniqueRecipients = [...new Set(filteredRecipients)];

            if (uniqueRecipients.length === 0) {
                console.log("[GroupPush] Все получатели отфильтрованы как отправитель");
                return;
            }

            const tokens: string[] = [];

            for (const recipient of uniqueRecipients) {
                console.log(`[GroupPush] Ищем токены для: ${recipient}`);

                const targetUids: string[] = [recipient];

                if (recipient.includes("@")) {
                    const userQuery = await admin.firestore()
                        .collection("users")
                        .where("email", "==", recipient.toLowerCase())
                        .limit(1)
                        .get();

                    if (!userQuery.empty) {
                        targetUids.push(userQuery.docs[0].id); // Важно: берем реальный doc.id с сохранением регистра
                    }
                }

                const uniqueTargetUids = [...new Set(targetUids)];

                for (const uid of uniqueTargetUids) {
                    const tokensSnapshot = await admin.firestore()
                        .collection("users")
                        .doc(uid) // Теперь UID передается с верным регистром (5CKGjy...)
                        .collection("tokens")
                        .get();

                    tokensSnapshot.forEach((doc) => {
                        const data = doc.data();
                        // Берем токен из поля data.token ИЛИ из doc.id (если сам ID является токеном)
                        const token = data.token || doc.id;
                        if (token && token.length > 20) { // Простая валидация на длину токена FCM
                            tokens.push(token);
                        }
                    });
                }
            }

            const uniqueTokens = [...new Set(tokens)];

            if (uniqueTokens.length === 0) {
                console.log(`Нет FCM-токенов для участников группы ${groupId}. Искали по получателям: ${uniqueRecipients.join(", ")}`);
                return;
            }

            const messagePayload: admin.messaging.MulticastMessage = {
                tokens: uniqueTokens,
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    groupId: groupId,
                    type: "group_chat_message",
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "chats_messages_channel",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            const response = await admin.messaging().sendEachForMulticast(messagePayload);
            console.log(`Отправлено групповых уведомлений: ${response.successCount} из ${uniqueTokens.length}`);
        } catch (error) {
            console.error("Ошибка при обработке триггера:", error);
        }
    }
);
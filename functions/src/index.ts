import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

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
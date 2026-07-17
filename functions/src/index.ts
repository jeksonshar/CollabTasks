import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

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
            console.log(`Отправлено уведомлений: ${response.successCount}`);
        } catch (error) {
            console.error("Ошибка при обработке триггера чата:", error);
        }
    }
);
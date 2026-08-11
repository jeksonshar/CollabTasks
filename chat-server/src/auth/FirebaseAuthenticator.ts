// ============================================================
// src/auth/FirebaseAuthenticator.ts
// Реализация IAuthenticator для Firebase Authentication (ID-token)
// ============================================================

import * as admin from 'firebase-admin';
import { IAuthenticator, AuthUser } from './IAuthenticator';

export class FirebaseAuthenticator implements IAuthenticator {
  constructor() {
    // Firebase Admin SDK должен быть инициализирован до вызова validateToken.
    // Инициализацию выполняет initializeFirebase() из pushNotificationService.ts.
    // Если SDK ещё не инициализирован — verifyIdToken выбросит ошибку с понятным сообщением.
  }

  async validateToken(token: string): Promise<AuthUser> {
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(token);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new Error(`[Firebase] Невалидный ID-token: ${msg}`);
    }

    // Firebase ID-token содержит:
    //   uid   — уникальный идентификатор пользователя (userId)
    //   email — email пользователя (может отсутствовать для анонимных)
    const userId = decodedToken.uid;
    const email = decodedToken.email ?? userId;

    return { userId, email };
  }
}

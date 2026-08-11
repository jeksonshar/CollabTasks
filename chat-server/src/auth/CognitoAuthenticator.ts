// ============================================================
// src/auth/CognitoAuthenticator.ts
// Реализация IAuthenticator для AWS Cognito (access-token JWT)
// ============================================================

import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { IAuthenticator, AuthUser } from './IAuthenticator';

// ─────────────────────────────────────────────────────────────
// Вспомогательный тип для доступа к расширенным claims Cognito
// ─────────────────────────────────────────────────────────────

type CognitoPayloadExtra = Record<string, unknown>;

export class CognitoAuthenticator implements IAuthenticator {
  private readonly verifier: ReturnType<typeof CognitoJwtVerifier.create>;

  constructor() {
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const clientId = process.env.COGNITO_CLIENT_ID;

    if (!userPoolId || !clientId) {
      throw new Error(
        '[CognitoAuthenticator] Переменные окружения COGNITO_USER_POOL_ID и ' +
          'COGNITO_CLIENT_ID обязательны!'
      );
    }

    /**
     * Верификатор JWT AWS Cognito.
     * Автоматически загружает JWKS по URI пула и кэширует публичные ключи.
     * tokenUse: 'access' — принимаем access-token, выданный Cognito.
     */
    this.verifier = CognitoJwtVerifier.create({
      userPoolId,
      clientId,
      tokenUse: 'access',
    });
  }

  async validateToken(token: string): Promise<AuthUser> {
    let payload: CognitoPayloadExtra;
    try {
      payload = (await this.verifier.verify(token)) as CognitoPayloadExtra;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new Error(`[Cognito] Невалидный JWT токен: ${msg}`);
    }

    // Cognito access-token содержит:
    //   sub      — UUID пользователя (userId)
    //   username — имя пользователя (может быть email или UUID)
    //   email    — если запрошен в scope (опционально в access token)
    const userId = payload['sub'] as string;
    const rawUsername = payload['username'] as string | undefined;
    const email =
      (payload['email'] as string | undefined) ?? rawUsername ?? userId;

    return { userId, email };
  }
}

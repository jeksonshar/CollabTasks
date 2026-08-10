// ============================================================
// src/middleware/authMiddleware.ts
// Валидация AWS Cognito JWT при WS-handshake
// ============================================================

import { IncomingMessage } from 'http';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { AuthenticatedUser } from '../models/types';

// ─────────────────────────────────────────────────────────────
// Конфигурация верификатора (создаётся один раз при запуске)
// ─────────────────────────────────────────────────────────────

const userPoolId = process.env.COGNITO_USER_POOL_ID;
const clientId = process.env.COGNITO_CLIENT_ID;

if (!userPoolId || !clientId) {
  throw new Error(
    '[AuthMiddleware] Переменные окружения COGNITO_USER_POOL_ID и COGNITO_CLIENT_ID обязательны!'
  );
}

/**
 * Верификатор JWT AWS Cognito.
 * Автоматически загружает JWKS по URI пула и кэширует публичные ключи.
 * tokenUse: 'access' — принимаем access-token, выданный Cognito.
 */
const verifier = CognitoJwtVerifier.create({
  userPoolId,
  clientId,
  tokenUse: 'access',
});

// ─────────────────────────────────────────────────────────────
// Вспомогательная функция: извлечь Bearer-токен из запроса
// ─────────────────────────────────────────────────────────────

/**
 * Извлекает JWT из следующих мест (в порядке приоритета):
 * 1. Query-параметр ?token=<jwt>
 * 2. Заголовок Authorization: Bearer <jwt>
 * 3. Заголовок Sec-WebSocket-Protocol: <jwt>  (совместимость с Flutter web)
 */
function extractToken(req: IncomingMessage): string | null {
  // 1. Query string
  const url = req.url ?? '';
  const queryMatch = url.match(/[?&]token=([^&]+)/);
  if (queryMatch) {
    return decodeURIComponent(queryMatch[1]);
  }

  // 2. Authorization header
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7);
  }

  // 3. Sec-WebSocket-Protocol (Flutter отправляет token через этот заголовок
  //    когда использует subprotocols: ['<jwt>'])
  const wsProtocol = req.headers['sec-websocket-protocol'];
  if (wsProtocol) {
    // Может быть несколько значений через запятую; берём первое
    const firstProtocol = wsProtocol.split(',')[0].trim();
    if (firstProtocol && firstProtocol !== 'chat') {
      return firstProtocol;
    }
  }

  return null;
}

// ─────────────────────────────────────────────────────────────
// Основная функция аутентификации
// ─────────────────────────────────────────────────────────────

/**
 * Верифицирует JWT токен Cognito из HTTP-запроса апгрейда WS.
 *
 * @returns AuthenticatedUser — если токен валиден
 * @throws Error — если токен отсутствует или невалиден (соединение должно быть закрыто)
 */
export async function authenticateRequest(req: IncomingMessage): Promise<AuthenticatedUser> {
  const token = extractToken(req);

  if (!token) {
    throw new Error('Отсутствует JWT токен. Подключение отклонено.');
  }

  try {
    const payload = await verifier.verify(token);

    // Cognito access-token содержит:
    //   sub       — UUID пользователя (userId)
    //   username  — имя пользователя (может быть email или UUID)
    //   email     — если запрошен в scope (опционально в access token)
    const userId = payload.sub;
    // username в Cognito access token — строка
    const rawUsername = (payload as Record<string, unknown>)['username'] as string | undefined;
    const email = (payload as Record<string, unknown>)['email'] as string | undefined
      ?? rawUsername
      ?? userId;

    // Имя берём из custom атрибута или fallback к email
    const name = (payload as Record<string, unknown>)['name'] as string | undefined
      ?? (payload as Record<string, unknown>)['given_name'] as string | undefined
      ?? email;

    return {
      userId,
      email,
      name: name ?? email,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`Невалидный JWT токен: ${message}`);
  }
}

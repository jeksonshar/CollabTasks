// ============================================================
// src/middleware/authMiddleware.ts
// Auth-фабрика: выбирает провайдер по AUTH_PROVIDER из .env,
// инстанциирует нужный IAuthenticator, экспортирует единую точку входа.
// Валидационная логика полностью вынесена в src/auth/*.ts
// ============================================================

import { IncomingMessage } from 'http';
import { IAuthenticator } from '../auth/IAuthenticator';
import { CognitoAuthenticator } from '../auth/CognitoAuthenticator';
import { FirebaseAuthenticator } from '../auth/FirebaseAuthenticator';
import { AuthenticatedUser } from '../models/types';

// ─────────────────────────────────────────────────────────────
// Фабрика: создаём экземпляр нужного провайдера один раз при старте
// ─────────────────────────────────────────────────────────────

const provider = (process.env.AUTH_PROVIDER ?? 'cognito').toLowerCase();

let authenticator: IAuthenticator;

switch (provider) {
  case 'firebase':
    authenticator = new FirebaseAuthenticator();
    console.log('[AuthMiddleware] Провайдер аутентификации: Firebase');
    break;

  case 'cognito':
    authenticator = new CognitoAuthenticator();
    console.log('[AuthMiddleware] Провайдер аутентификации: AWS Cognito');
    break;

  default:
    throw new Error(
      `[AuthMiddleware] Неизвестный AUTH_PROVIDER="${provider}". ` +
        'Допустимые значения: "cognito", "firebase".'
    );
}

// ─────────────────────────────────────────────────────────────
// Вспомогательная функция: извлечь Bearer-токен из WS handshake
// ─────────────────────────────────────────────────────────────

/**
 * Извлекает JWT из следующих мест (в порядке приоритета):
 * 1. Query-параметр  ?token=<jwt>
 * 2. Заголовок       Authorization: Bearer <jwt>
 * 3. Заголовок       Sec-WebSocket-Protocol: <jwt>  (совместимость с Flutter web)
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
// Основная функция аутентификации (публичный API)
// ─────────────────────────────────────────────────────────────

/**
 * Извлекает токен из HTTP-запроса апгрейда WS и делегирует проверку
 * активному IAuthenticator (Cognito или Firebase).
 *
 * Возвращает: AuthenticatedUser — если токен валиден.
 * Бросает:    Error            — если токен отсутствует или невалиден.
 *
 * @remarks
 * Поле `name` в AuthenticatedUser заполняется из email как fallback,
 * так как IAuthenticator.AuthUser намеренно не содержит display-name
 * (не все провайдеры его гарантируют).
 */
export async function authenticateRequest(
  req: IncomingMessage
): Promise<AuthenticatedUser> {
  const token = extractToken(req);

  if (!token) {
    throw new Error('Отсутствует JWT токен. Подключение отклонено.');
  }

  // Делегируем провайдеру — выбрасывает Error при невалидном токене
  const authUser = await authenticator.validateToken(token);

  // Маппинг AuthUser → AuthenticatedUser (добавляем name как fallback к email)
  return {
    userId: authUser.userId,
    email: authUser.email,
    name: authUser.email, // display-name берётся из профиля на уровне приложения
  };
}

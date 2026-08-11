export interface AuthUser {
    userId: string; // Единый ID пользователя для вашей системы чатов
    email: string;
}

export interface IAuthenticator {
    // Принимает сырой токен, возвращает стандартизированного пользователя или кидает ошибку
    validateToken(token: string): Promise<AuthUser>;
}
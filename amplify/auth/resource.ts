import {defineAuth, secret} from '@aws-amplify/backend';

export const auth = defineAuth({
    loginWith: {
        email: true,
        externalProviders: {
            google: {
                clientId: secret('GOOGLE_CLIENT_ID'),
                clientSecret: secret('GOOGLE_CLIENT_SECRET'),
            },
            scopes: ['PHONE', 'EMAIL', 'OPENID', 'PROFILE', 'COGNITO_ADMIN'],
            callbackUrls: [
                'http://localhost:3000/',
                'collabtasks://callback/',
            ],
            logoutUrls: [
                'http://localhost:3000/',
                'collabtasks://callback/',
            ],
        },
    },
    multifactor: {
        mode: 'OFF',
    },
});
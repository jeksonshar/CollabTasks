import { util } from '@aws-appsync/utils';

export function request(ctx) {
    const email = ctx.args.email.trim().toLowerCase();
    // Получаем текущий timestamp через поддерживаемую AppSync утилиту
    const nowMillis = util.time.nowEpochMilliSeconds();

    return {
        operation: 'UpdateItem',
        key: util.dynamodb.toMapValues({ id: ctx.args.groupId }),
        update: {
            expression: 'SET participantEmails = list_append(if_not_exists(participantEmails, :empty), :email), updatedAtMillis = :updatedAtMillis',
            expressionValues: {
                // Правильный маппинг пустого списка и списка с одним email для DynamoDB
                ':empty': { L: [] },
                ':email': { L: [util.dynamodb.toDynamoDB(email)] },
                ':updatedAtMillis': util.dynamodb.toDynamoDB(nowMillis),
            },
        },
    };
}

export function response(ctx) {
    if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type);
    }
    // Возвращаем результат обновления (модель WorkingGroup)
    return ctx.result;
}

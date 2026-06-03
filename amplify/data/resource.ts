import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  // Описываем кастомный объект подзадачи
  Subtask: a.customType({
    id: a.id().required(),
    title: a.string().required(),
    isCompleted: a.boolean().required(),
  }),

  // Описываем кастомный объект метаданных файла
  FileMeta: a.customType({
    id: a.id().required(),
    name: a.string().required(),
    storageKey: a.string().required(),
  }),

  // Основная модель Задачи
  Task: a
      .model({
        id: a.id().required(),
        title: a.string().required(),
        description: a.string(),
        deadline: a.integer(), // Unix timestamp (int)
        isCompleted: a.boolean().required(),
        priority: a.string().required(), // low, medium, high, urgent
        subtasks: a.ref('Subtask').array(), // Список подзадач
        files: a.ref('FileMeta').array(),   // Список файлов
        updatedAt: a.integer().required(),  // Важно для твоей синхронизации
      })
      .authorization((allow) => [
        // Правило: доступ имеет только владелец записи (owner) через Cognito
        allow.owner(),
      ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool', // Авторизация через Cognito User Pools
  },
});
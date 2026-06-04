import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  // Describing a custom subtask object
  Subtask: a.customType({
    id: a.id().required(),
    title: a.string().required(),
    isCompleted: a.boolean().required(),
  }),

  // Describing a custom file metadata object
  FileMeta: a.customType({
    id: a.id().required(),
    name: a.string().required(),
    storageKey: a.string().required(),
  }),

  // Basic Model Tasks
  Task: a
      .model({
        id: a.id().required(),
        title: a.string().required(),
        description: a.string(),
        deadline: a.float(), // Unix timestamp (int)
        isCompleted: a.boolean().required(),
        priority: a.string().required(), // low, medium, high, no priority
        subtasks: a.ref('Subtask').array(), // List of subtasks
        files: a.ref('FileMeta').array(),   // List of files
        updatedAtMillis: a.float(), // Important for synchronization
      })
      .authorization((allow) => [
        // Rule: Only the owner of the record has access via Cognito
        allow.owner(),
      ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool', // Authorization via Cognito User Pools
  },
});

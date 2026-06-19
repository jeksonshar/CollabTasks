import {a, type ClientSchema, defineData} from '@aws-amplify/backend';

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
        sizeBytes: a.float(),
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

    WorkingGroup: a
        .model({
            id: a.id().required(),
            title: a.string().required(),
            description: a.string(),
            avatarUrl: a.string(),
            participantUserIds: a.string().array(),
            participantEmails: a.email().array(),
            updatedAtMillis: a.float(),
        })
        .authorization((allow) => [
            // Group records are additionally filtered by participantUserIds/participantEmails in client queries.
            allow.authenticated(),
        ]),

    GroupParticipant: a
        .model({
            id: a.id().required(),
            groupId: a.id().required(),
            userId: a.string().required(),
            name: a.string().required(),
            avatarUrl: a.string(),
            updatedAtMillis: a.float(),
        })
        .authorization((allow) => [
            allow.authenticated(),
        ]),

    GroupTask: a
        .model({
            id: a.id().required(),
            groupId: a.id().required(),
            title: a.string().required(),
            description: a.string(),
            deadline: a.float(),
            isCompleted: a.boolean().required(),
            priority: a.string().required(),
            subtasks: a.ref('Subtask').array(),
            files: a.ref('FileMeta').array(),
            isPinned: a.boolean(),
            assignedUserId: a.string(),
            updatedAtMillis: a.float(),
        })
        .authorization((allow) => [
            allow.authenticated(),
        ]),

    inviteWorkingGroupParticipant: a
        .mutation()
        .arguments({
            groupId: a.id().required(),
            email: a.email().required(),
        })
        .returns(a.ref('WorkingGroup'))
        .authorization((allow) => [
            allow.authenticated(),
        ])
        .handler(a.handler.custom({
            dataSource: a.ref('WorkingGroup'),
            entry: './invite-working-group-participant.js',
        })),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
    schema,
    authorizationModes: {
        defaultAuthorizationMode: 'userPool', // Authorization via Cognito User Pools
    },
});

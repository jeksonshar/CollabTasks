import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
    name: 'collabTasksFiles',
    access: (allow) => ({
        // We set up a path like this: private/{user_id}/*
        'private/{entity_id}/*': [
            allow.entity('identity').to(['read', 'write', 'delete'])
        ]
    })
});
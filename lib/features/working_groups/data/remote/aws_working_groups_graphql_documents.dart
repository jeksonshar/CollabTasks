class AwsWorkingGroupsGraphqlDocuments {
  const AwsWorkingGroupsGraphqlDocuments._();

  static const String listGroups = r'''
query ListWorkingGroups {
  listWorkingGroups {
    items {
      id
      title
      description
      participantUserIds
      createdAt
      updatedAtMillis
    }
  }
}
''';

  static const String listParticipants = r'''
query ListGroupParticipants($groupId: ID!) {
  listGroupParticipants(filter: { groupId: { eq: $groupId } }) {
    items {
      id
      groupId
      userId
      name
      avatarUrl
      updatedAtMillis
    }
  }
}
''';

  static const String listTasks = r'''
query ListGroupTasks($groupId: ID!) {
  listGroupTasks(filter: { groupId: { eq: $groupId } }) {
    items {
      id
      groupId
      title
      description
      priority
      files {
        id
        name
        storageKey
        sizeBytes
      }
      subtasks {
        id
        title
        isCompleted
      }
      isCompleted
      deadline
      isPinned
      assignedUserId
      createdAt
      updatedAtMillis
    }
  }
}
''';

  static const String createGroup = r'''
mutation CreateWorkingGroup($input: CreateWorkingGroupInput!) {
  createWorkingGroup(input: $input) { id }
}
''';

  static const String updateGroup = r'''
mutation UpdateWorkingGroup($input: UpdateWorkingGroupInput!) {
  updateWorkingGroup(input: $input) { id }
}
''';

  static const String createParticipant = r'''
mutation CreateGroupParticipant($input: CreateGroupParticipantInput!) {
  createGroupParticipant(input: $input) { id }
}
''';

  static const String updateParticipant = r'''
mutation UpdateGroupParticipant($input: UpdateGroupParticipantInput!) {
  updateGroupParticipant(input: $input) { id }
}
''';

  static const String createTask = r'''
mutation CreateGroupTask($input: CreateGroupTaskInput!) {
  createGroupTask(input: $input) { id }
}
''';

  static const String updateTask = r'''
mutation UpdateGroupTask($input: UpdateGroupTaskInput!) {
  updateGroupTask(input: $input) { id }
}
''';

  static const String deleteTask = r'''
mutation DeleteGroupTask($input: DeleteGroupTaskInput!) {
  deleteGroupTask(input: $input) { id }
}
''';

  static const String onGroupChanged = r'''
subscription OnWorkingGroupChanged {
  onCreateWorkingGroup {
    id
      title
      description
      participantUserIds
      createdAt
      updatedAtMillis
  }
}
''';

  static const String onParticipantChanged = r'''
subscription OnGroupParticipantChanged($groupId: ID!) {
  onCreateGroupParticipant(filter: { groupId: { eq: $groupId } }) {
    id
    groupId
    userId
    name
    avatarUrl
    updatedAtMillis
  }
}
''';

  static const String onTaskChanged = r'''
subscription OnGroupTaskCreated($groupId: ID!) {
  onCreateGroupTask(filter: { groupId: { eq: $groupId } }) {
    id
    groupId
    title
    description
    priority
    files {
      id
      name
      storageKey
      sizeBytes
    }
    subtasks {
      id
      title
      isCompleted
    }
    isCompleted
    deadline
    isPinned
    assignedUserId
    createdAt
    updatedAtMillis
  }
}
''';

  static const String onTaskUpdated = r'''
subscription OnGroupTaskUpdated($groupId: ID!) {
  onUpdateGroupTask(filter: { groupId: { eq: $groupId } }) {
    id
    groupId
    title
    description
    priority
    files {
      id
      name
      storageKey
      sizeBytes
    }
    subtasks {
      id
      title
      isCompleted
    }
    isCompleted
    deadline
    isPinned
    assignedUserId
    createdAt
    updatedAtMillis
  }
}
''';
}

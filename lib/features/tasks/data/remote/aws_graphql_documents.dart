class AwsTaskGraphqlDocuments {
  const AwsTaskGraphqlDocuments._();

  static const String listTasks = r'''
query ListTasks {
  listTasks {
    items {
      id
      title
      description
      deadline
      isCompleted
      priority
      subtasks {
        id
        title
        isCompleted
      }
      files {
        id
        name
        storageKey
      }
      createdAt
      updatedAtMillis
    }
  }
}
''';

  static const String getTask = r'''
query GetTask($id: ID!) {
  getTask(id: $id) {
    id
    title
    description
    deadline
    isCompleted
    priority
    subtasks {
      id
      title
      isCompleted
    }
    files {
      id
      name
      storageKey
    }
    createdAt
    updatedAtMillis
  }
}
''';

  static const String createTask = r'''
mutation CreateTask($input: CreateTaskInput!) {
  createTask(input: $input) {
    id
    title
    description
    deadline
    isCompleted
    priority
    subtasks {
      id
      title
      isCompleted
    }
    files {
      id
      name
      storageKey
    }
    createdAt
    updatedAtMillis
  }
}
''';

  static const String updateTask = r'''
mutation UpdateTask($input: UpdateTaskInput!) {
  updateTask(input: $input) {
    id
    title
    description
    deadline
    isCompleted
    priority
    subtasks {
      id
      title
      isCompleted
    }
    files {
      id
      name
      storageKey
    }
    createdAt
    updatedAtMillis
  }
}
''';

  static const String deleteTask = r'''
mutation DeleteTask($input: DeleteTaskInput!) {
  deleteTask(input: $input) {
    id
  }
}
''';
}

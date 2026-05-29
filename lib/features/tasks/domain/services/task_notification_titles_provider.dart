class TaskNotificationTitles {
  const TaskNotificationTitles({required this.reminderTitle, required this.deadlineTitle});

  final String reminderTitle;
  final String deadlineTitle;
}

abstract class TaskNotificationTitlesProvider {
  Future<TaskNotificationTitles> getTitles();
}

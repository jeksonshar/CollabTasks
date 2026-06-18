class GroupTaskAssignmentException implements Exception {
  const GroupTaskAssignmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

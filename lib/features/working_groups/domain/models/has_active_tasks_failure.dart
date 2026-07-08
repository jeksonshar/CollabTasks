class HasActiveTasksFailure implements Exception {
  const HasActiveTasksFailure();

  @override
  String toString() => 'Cannot leave a working group with active assigned tasks.';
}

extension StringExtensions on String {
  String substringAfterLast(String delimiter) {
    final index = lastIndexOf(delimiter);
    return index == -1 ? this : substring(index + delimiter.length);
  }
}

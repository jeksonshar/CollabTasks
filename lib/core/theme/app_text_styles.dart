import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle bold16Roboto(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.titleMedium?.color,
      fontFamily: 'Roboto',
    );
  }
}

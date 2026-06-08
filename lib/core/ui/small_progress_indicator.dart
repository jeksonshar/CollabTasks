import 'package:flutter/material.dart';

class SmallProgressIndicator extends StatelessWidget {
  final double padding;

  const SmallProgressIndicator({super.key, this.padding = 12.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

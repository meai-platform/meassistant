import 'package:flutter/material.dart';

/// Separator line widget
class SeparatorLineWidget extends StatelessWidget {
  const SeparatorLineWidget({
    super.key,
    this.color = const Color(0xffD9D9E5), // lineColor
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}


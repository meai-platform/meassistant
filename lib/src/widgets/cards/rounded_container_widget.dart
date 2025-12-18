import 'package:flutter/material.dart';

/// Rounded container widget for card content
class RoundedContainerWidget extends StatelessWidget {
  final Widget content;
  final double paddingVertical;
  final double paddingHorizontal;
  final double borderRadius;
  final Color color;
  final Color? borderColor;

  const RoundedContainerWidget({
    super.key,
    required this.content,
    this.paddingVertical = 16,
    this.paddingHorizontal = 16,
    this.borderRadius = 16,
    this.color = const Color(0xfff6f4fe), // mePurple25
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1) : null,
      ),
      child: content,
    );
  }
}


import 'package:flutter/material.dart';

/// Recurring icon widget with image and recurring badge
class RecurringIcon extends StatelessWidget {
  final String img;
  final bool isLarge;
  final double? avatarPadding;

  const RecurringIcon({
    super.key,
    required this.img,
    this.isLarge = false,
    this.avatarPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _getLargerSize(45),
      height: _getLargerSize(45),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _getImage(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _getRecurringIcon(isSmall: true),
          ),
        ],
      ),
    );
  }

  Widget _getImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_getLargerSize(20)),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_getLargerSize(20)),
        child: Padding(
          padding: EdgeInsets.all(_getLargerSize((avatarPadding ?? 0) / 2)),
          child: Image.network(
            img,
            width: _getLargerSize(38) - _getLargerSize((avatarPadding ?? 0)),
            height: _getLargerSize(38) - _getLargerSize((avatarPadding ?? 0)),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: _getLargerSize(38) - _getLargerSize((avatarPadding ?? 0)),
                height: _getLargerSize(38) - _getLargerSize((avatarPadding ?? 0)),
                decoration: BoxDecoration(
                  color: const Color(0xfff6f4fe),
                  borderRadius: BorderRadius.circular(_getLargerSize(20)),
                ),
                child: const Icon(Icons.store, size: 20),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getRecurringIcon({bool isSmall = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_getLargerSize(20)),
        border: Border.all(
          color: isSmall ? const Color(0xfff6f4fe) : Colors.white,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_getLargerSize(20)),
        child: Container(
          width: _getLargerSize(isSmall ? 20 : 40),
          height: _getLargerSize(isSmall ? 20 : 40),
          decoration: BoxDecoration(
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(_getLargerSize(20)),
          ),
          child: const Icon(
            Icons.repeat,
            color: Colors.orange,
            size: 12,
          ),
        ),
      ),
    );
  }

  double _getLargerSize(double value) {
    return value * (isLarge ? 2 : 1);
  }
}


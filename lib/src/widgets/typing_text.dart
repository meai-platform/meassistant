import 'dart:async';
import 'package:flutter/material.dart';

/// Widget that displays text with a typing animation effect
class TypingText extends StatefulWidget {
  final String fullText;
  final Duration speed;
  final TextStyle? style;
  final ScrollController scrollController;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final bool showFullContentImmediately;

  const TypingText({
    super.key,
    required this.fullText,
    required this.scrollController,
    this.speed = const Duration(milliseconds: 35),
    this.style,
    this.onComplete,
    this.onStart,
    this.showFullContentImmediately = false,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  late String _visibleText;
  Timer? _timer;
  int _index = 0;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _visibleText = '';
    if (widget.showFullContentImmediately) {
      _visibleText = widget.fullText;
      _completed = true;
    } else {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!_started) {
        _started = true;
        widget.onStart?.call();
      }

      if (_index < widget.fullText.length) {
        final currentChar = widget.fullText[_index];

        setState(() {
          _visibleText += currentChar;
          _index++;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        timer.cancel();
        if (!_completed) {
          _completed = true;
          widget.onComplete?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleText,
      style: widget.style ?? const TextStyle(fontSize: 16),
    );
  }
}


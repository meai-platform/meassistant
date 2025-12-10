import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/assistant_config.dart';
import '../services/assistant_service.dart';

/// Floating button widget for opening the assistant
class AssistantFloatingButton extends StatefulWidget {
  final AssistantConfig config;
  final AssistantService assistantService;

  const AssistantFloatingButton({
    Key? key,
    required this.config,
    required this.assistantService,
  }) : super(key: key);

  @override
  State<AssistantFloatingButton> createState() =>
      _AssistantFloatingButtonState();
}

class _AssistantFloatingButtonState extends State<AssistantFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.assistantService,
      builder: (context, child) {
        final service = widget.assistantService;

        if (service.isVisible &&
            _animationController.status != AnimationStatus.forward) {
          _animationController.forward();
        } else if (!service.isVisible &&
            _animationController.status != AnimationStatus.reverse) {
          _animationController.reverse();
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (_animationController.value == 0.0) {
              return const SizedBox.shrink();
            }

            return SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildButton(service),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButton(AssistantService service) {
    // Check if floatingButtonColor is explicitly provided (not just default)
    final hasCustomFloatingButtonColor = widget.config.floatingButtonColor != null || widget.config.colorScheme != null;
    final floatingButtonColor = widget.config.effectiveColorScheme.floatingButtonColor;
    
    return GestureDetector(
      onTap: () => service.showModal(),
      child: Container(
        width: 55,
        height: 55,
        child: Stack(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.0),
                    ),
                  ),
                ),
              ),
            ),
            // Use circular container if floatingButtonColor is provided, otherwise use container image
            hasCustomFloatingButtonColor
                ? Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: floatingButtonColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : Image.asset(
                    widget.config.floatingButtonContainerPath ?? "packages/meai_assistant/assets/images/ai_button_container.png",
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: floatingButtonColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
            Center(
              child: _buildImage(
                widget.config.floatingLogoPath ?? widget.config.suggestionIconPath ?? "packages/meai_assistant/assets/images/ic_ai.png",
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path, {double? size}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        color: widget.config.effectiveColorScheme.floatingButtonIconColor,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            widget.config.suggestionIconPath ?? 'packages/meai_assistant/assets/images/ic_ai.png',
            width: size,
            height: size,
            color: widget.config.effectiveColorScheme.floatingButtonIconColor,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.chat_bubble_outline,
                size: size,
                color: widget.config.effectiveColorScheme.floatingButtonIconColor,
              );
            },
          );
        },
      );
    } else {
      return Image.asset(
        path,
        width: size,
        height: size,
        color: widget.config.effectiveColorScheme.floatingButtonIconColor,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            widget.config.suggestionIconPath ?? 'packages/meai_assistant/assets/images/ic_ai.png',
            width: size,
            height: size,
            color: widget.config.effectiveColorScheme.floatingButtonIconColor,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.chat_bubble_outline,
                size: size,
                color: widget.config.effectiveColorScheme.floatingButtonIconColor,
              );
            },
          );
        },
      );
    }
  }
}


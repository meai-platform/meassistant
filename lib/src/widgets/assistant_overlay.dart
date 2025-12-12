import 'package:flutter/material.dart';
import '../config/assistant_config.dart';
import '../services/assistant_service.dart';
import '../stores/assistant_store.dart';
import 'assistant_floating_button.dart';
import 'assistant_modal.dart';

/// Overlay widget that wraps your app content and adds the assistant UI
class AssistantOverlay extends StatelessWidget {
  final Widget child;
  final AssistantConfig config;
  final AssistantService assistantService;
  final AssistantStore assistantStore;

  const AssistantOverlay({
    super.key,
    required this.child,
    required this.config,
    required this.assistantService,
    required this.assistantStore,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          child,
          AnimatedBuilder(
            animation: assistantService,
            builder: (context, child) {
              return Positioned(
                bottom: config.floatingButtonBottomSpacing,
                right: config.floatingButtonRightSpacing,
                child: AssistantFloatingButton(
                  config: config,
                  assistantService: assistantService,
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: assistantService,
            builder: (context, child) {
              if (assistantService.isModalOpen) {
                return AssistantModal(
                  config: config,
                  assistantStore: assistantStore,
                  assistantService: assistantService,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}


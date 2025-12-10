import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/assistant_config.dart';
import 'services/api_service.dart';
import 'services/assistant_api_service.dart';
import 'services/assistant_service.dart';
import 'services/sdk_auth_service.dart';
import 'stores/assistant_store.dart';
import 'widgets/assistant_overlay.dart';

/// Main class for initializing and managing the assistant plugin
class MeaiAssistant {
  final AssistantConfig config;
  late final SdkAuthService? _sdkAuthService;
  late final ApiService _apiService;
  late final AssistantApiService _assistantApiService;
  late final AssistantService _assistantService;
  late final AssistantStore _assistantStore;

  MeaiAssistant({required this.config}) {
    // Initialize SDK authentication service if credentials are provided
    // Package name is automatically read from the app
    if (config.clientId != null && config.getHmac != null) {
      _sdkAuthService = SdkAuthService(
        baseUrl: config.baseUrl,
        clientId: config.clientId,
        getHmac: config.getHmac!,
        customerId: config.customerId,
        debug: config.debug,
      );
    } else {
      _sdkAuthService = null;
    }

    _apiService = ApiService(config, _sdkAuthService);
    _assistantApiService = AssistantApiService(_apiService, config);
    _assistantService = AssistantService();
    _assistantStore = AssistantStore(_assistantApiService, _assistantService);
  }

  /// Get the assistant service instance
  AssistantService get assistantService => _assistantService;

  /// Get the assistant store instance
  AssistantStore get assistantStore => _assistantStore;

  /// Wrap your app with the assistant overlay
  Widget wrapApp(Widget app) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _assistantService),
        Provider.value(value: _assistantStore),
      ],
      child: AssistantOverlay(
        config: config,
        assistantService: _assistantService,
        assistantStore: _assistantStore,
        child: app,
      ),
    );
  }

  /// Show the assistant floating button
  void showAssistant() {
    _assistantService.showAssistant();
  }

  /// Hide the assistant floating button
  void hideAssistant() {
    _assistantService.hideAssistant();
  }

  /// Show the assistant modal
  void showModal() {
    _assistantService.showModal();
  }

  /// Hide the assistant modal
  void hideModal() {
    _assistantService.hideModal();
  }

  /// Set bottom spacing for the floating button
  void setBottomSpacing(double spacing) {
    _assistantService.setBottomSpacing(spacing);
  }

  /// Clear all chat messages
  void clearMessages() {
    _assistantStore.clearMessages();
  }
}


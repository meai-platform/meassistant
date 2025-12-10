import 'package:flutter/material.dart';

/// Service for managing assistant visibility and modal state
class AssistantService extends ChangeNotifier {
  static final Map<String, AssistantService> _instances = {};

  final String instanceId;

  AssistantService._internal(this.instanceId);

  factory AssistantService({String? instanceId}) {
    final id = instanceId ?? 'default';
    _instances[id] ??= AssistantService._internal(id);
    return _instances[id]!;
  }

  bool _isVisible = false;
  bool _isModalOpen = false;
  double _bottomSpacing = 100.0;

  bool get isVisible => _isVisible;
  bool get isModalOpen => _isModalOpen;
  double get bottomSpacing => _bottomSpacing;

  void showAssistant() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hideAssistant() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  void showModal() {
    _isModalOpen = true;
    notifyListeners();
  }

  void hideModal() {
    _isModalOpen = false;
    notifyListeners();
  }

  void setBottomSpacing(double spacing) {
    if (_bottomSpacing != spacing) {
      _bottomSpacing = spacing;
      notifyListeners();
    }
  }

  void resetBottomSpacing() {
    setBottomSpacing(100.0);
  }
}


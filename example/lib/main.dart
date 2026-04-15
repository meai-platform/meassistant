import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meai_assistant/meai_assistant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lang = 'en';

  MeaiAssistant _buildAssistant(String lang) {
    return MeaiAssistant(
      config: AssistantConfig(
        assistantName: 'meAssistant',
        baseUrl: 'https://demobank-api.meplatform.ai/',
        customerId: Platform.isAndroid ? 'customer1234' : 'customer123',
        lang: lang,
        clientId: Platform.isAndroid ? 'client-test-1234' : 'client-test-123',
        getHmac: (timestamp, clientId, packageName, customerId) async {
          return 'calculated-hmac-from-backend';
        },
        fontFamily: 'ReadexPro',
        debug: true,
      ),
    );
  }

  void _setLang(String lang) {
    if (lang == _lang) return;
    setState(() {
      _lang = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assistant = _buildAssistant(_lang);

    return MaterialApp(
      title: 'Me.Ai Assistant Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: assistant.wrapApp(
        MyHomePage(
          assistant: assistant,
          selectedLang: _lang,
          onLangChanged: _setLang,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MeaiAssistant assistant;
  final String selectedLang;
  final ValueChanged<String> onLangChanged;

  const MyHomePage({
    Key? key,
    required this.assistant,
    required this.selectedLang,
    required this.onLangChanged,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      widget.assistant.showAssistant();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.selectedLang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مثال مساعد MeAI' : 'MeAI Assistant Example'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _LangToggle(
              selected: widget.selectedLang,
              onChanged: widget.onLangChanged,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              isAr ? 'مرحباً بك في مساعد MeAI' : 'Welcome to MeAI Assistant',
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ActionButton(
              label: isAr ? 'فتح المساعد' : 'Open Assistant',
              icon: Icons.chat_bubble_outline,
              onTap: () => widget.assistant.showModal(),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: isAr ? 'إخفاء الزر العائم' : 'Hide Floating Button',
              icon: Icons.visibility_off_outlined,
              onTap: () => widget.assistant.hideAssistant(),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: isAr ? 'إظهار الزر العائم' : 'Show Floating Button',
              icon: Icons.visibility_outlined,
              onTap: () => widget.assistant.showAssistant(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented EN / AR toggle button.
class _LangToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LangToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangOption(
              label: 'EN', value: 'en', selected: selected, onTap: onChanged),
          Container(width: 1, height: 24, color: Colors.blue.shade200),
          _LangOption(
              label: 'AR', value: 'ar', selected: selected, onTap: onChanged),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _LangOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}

/// Consistent button used in the home page body.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

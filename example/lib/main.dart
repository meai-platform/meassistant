import 'package:flutter/material.dart';
import 'package:meai_assistant/meai_assistant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  //
  //
  // AssistantConfig(
  // // Required
  // assistantName: 'My Assistant',  // Name displayed in UI
  // baseUrl: 'https://api.example.com/',  // API base URL
  //
  // // Optional - Appearance
  // logoPath: 'assets/images/assistant_logo.png',  // Main logo (asset or URL)
  // floatingLogoPath: 'assets/images/floating_logo.png',  // Floating button logo
  // colorScheme: AssistantColorScheme.purple,  // Color scheme
  //
  // // Optional - Text
  // introText: "Hello! I'm your smart money assistant.",  // Welcome message
  // textFieldHint: "Ask something...",  // Input field hint
  //
  // // Optional - Authentication
  // getAuthToken: () async => await getToken(),  // Function to get auth token
  // getUserId: () async => await getUserId(),  // Function to get user ID
  //
  // // Optional - Additional
  // additionalHeaders: {'Custom-Header': 'value'},  // Extra HTTP headers
  // floatingButtonBottomSpacing: 100.0,  // Bottom spacing for button
  // floatingButtonRightSpacing: 20.0,  // Right spacing for button
  // suggestionPrompts: [  // Welcome screen suggestions
  // 'What is my spending average?',
  // 'How much can I save?',
  // ],
  // )
  @override
  Widget build(BuildContext context) {
    // Create assistant configuration
    final assistant = MeaiAssistant(
      config: AssistantConfig(
        assistantName: 'meAssistant',
        baseUrl: 'https://[bank-unique-code]-api.meplatform.ai/',
        customerId: 'customer123', // Required: Customer ID for API requests
        lang: 'en', // Language preference: 'en' or 'ar'
        // SDK Authentication credentials (required for mebank SDK)
        clientId: 'client-test-123',
        // HMAC is calculated by your backend
        // Backend should calculate: HMAC-SHA256(clientSecret, timestamp + clientId + packageName + customerId)
        getHmac: (timestamp, clientId, packageName, customerId) async {
          // Call your backend to calculate HMAC
          // Example:
          // final response = await http.post(
          //   Uri.parse('https://your-backend.com/calculate-hmac'),
          //   body: {
          //     'timestamp': timestamp.toString(),
          //     'clientId': clientId,
          //     'packageName': packageName,
          //     'customerId': customerId ?? '',
          //   },
          // );
          // return response.body;
          
          // For testing, return a placeholder (replace with actual backend call)
          return 'calculated-hmac-from-backend';
        },
        // Package name and app hash are automatically read/calculated from the app
        // Default branding uses meAi logo, colors, and ReadexPro font
        // logoPath and floatingLogoPath default to meAi logo
        
        introText: "Hello! I'm your smart\nmoney assistant.",
        textFieldHint: "Ask something...",
        debug: true,
        // colorScheme: AssistantColorScheme.green
        // floatingButtonColor: Colors.red,
        // floatingLogoPath: "assets/images/me-logo.png",
      ),
    );

    return MaterialApp(
      title: 'MeAI Assistant Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: assistant.wrapApp(
        MyHomePage(assistant: assistant),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MeaiAssistant assistant;

  const MyHomePage({Key? key, required this.assistant}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Show the assistant after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      widget.assistant.showAssistant();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeAI Assistant Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to MeAI Assistant',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.assistant.showModal();
              },
              child: const Text('Open Assistant'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.assistant.hideAssistant();
              },
              child: const Text('Hide Floating Button'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.assistant.showAssistant();
              },
              child: const Text('Show Floating Button'),
            ),
          ],
        ),
      ),
    );
  }
}


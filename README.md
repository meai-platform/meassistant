# MeAI Assistant Plugin

A Flutter plugin designed specifically for banks and financial institutions to embed an intelligent AI assistant into their mobile banking applications. MeAI Assistant enables banks to provide 24/7 customer support, financial guidance, and personalized banking assistance directly within their apps.

## Features

- 🏦 **Banking-Focused**: Purpose-built for financial institutions with secure authentication and compliance-ready architecture
- 💬 **Intelligent Chat Interface**: Beautiful, conversational UI that helps customers with account inquiries, transaction history, spending analysis, and financial advice
- 🎯 **Always Accessible**: Floating action button ensures customers can get help anytime, anywhere within the banking app
- 🔒 **Secure & Compliant**: Built-in support for JWT authentication and SDK authentication with HMAC-SHA256, ensuring secure communication with banking APIs
- 🎨 **Brand Customization**: Fully customizable to match your bank's branding with custom logos, colors, fonts, and messaging
- 📊 **Financial Insights**: Display spending patterns, account summaries, recurring transactions, and personalized financial recommendations
- 📱 **Responsive Design**: Seamlessly works across all device sizes and screen orientations
- ⌨️ **Keyboard Aware**: Automatically adjusts UI when keyboard appears for optimal user experience
- 🔄 **State Management**: Robust MobX-based state management for reliable performance
- 🎭 **Pre-built Themes**: Ready-to-use color schemes or create custom themes that match your bank's visual identity

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  meai_assistant: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Basic Setup

```dart
import 'package:meai_assistant/meai_assistant.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create assistant configuration
    final assistant = MeaiAssistant(
      config: AssistantConfig(
        assistantName: 'My Assistant',
        baseUrl: 'https://your-dedicated-meai-api-url.com/',
        colorScheme: AssistantColorScheme.purple,
        introText: "Hello! I'm your smart money assistant.",
        textFieldHint: "Ask something...",
        getAuthToken: () async => 'your-auth-token',
        getUserId: () async => 123,
      ),
    );

    return MaterialApp(
      home: assistant.wrapApp(MyHomePage()),
    );
  }
}
```

### 2. Show/Hide Assistant

```dart
// Get assistant instance
final assistant = MeaiAssistant(config: config);

// Show the floating button
assistant.showAssistant();

// Hide the floating button
assistant.hideAssistant();

// Show the modal directly
assistant.showModal();

// Hide the modal
assistant.hideModal();
```

## Configuration

### AssistantConfig

The `AssistantConfig` class allows you to customize all aspects of the assistant:

```dart
AssistantConfig(
  // Required
  assistantName: 'My Assistant',  // Name displayed in UI
  baseUrl: 'https://api.example.com/',  // API base URL
  
  // Optional - Appearance
  logoPath: 'assets/images/assistant_logo.png',  // Main logo (asset or URL)
  floatingLogoPath: 'assets/images/floating_logo.png',  // Floating button logo
  colorScheme: AssistantColorScheme.purple,  // Color scheme
  
  // Optional - Text
  introText: "Hello! I'm your smart money assistant.",  // Welcome message
  textFieldHint: "Ask something...",  // Input field hint
  
  // Optional - Authentication
  getAuthToken: () async => await getToken(),  // Function to get auth token
  getUserId: () async => await getUserId(),  // Function to get user ID
  
  // Optional - Additional
  additionalHeaders: {'Custom-Header': 'value'},  // Extra HTTP headers
  floatingButtonBottomSpacing: 100.0,  // Bottom spacing for button
  floatingButtonRightSpacing: 20.0,  // Right spacing for button
  suggestionPrompts: [  // Welcome screen suggestions
    'What is my spending average?',
    'How much can I save?',
  ],
)
```

### Color Schemes

#### Pre-built Schemes

```dart
// Purple theme (default)
AssistantColorScheme.purple

// Blue theme
AssistantColorScheme.blue

// Green theme
AssistantColorScheme.green
```

#### Custom Color Scheme

```dart
AssistantColorScheme(
  primaryColor: Color(0xFF6310D1),
  secondaryColor: Color(0xFFAF79F5),
  backgroundColor: Colors.white,
  textColor: Color(0xFF0F0F0F),
  hintTextColor: Color(0xFF9292A0),
  userMessageColor: Color(0x0A000000),
  assistantMessageColor: Color(0xFF42424C),
  borderColor: Color(0x0A000000),
  floatingButtonColor: Color(0xFF6310D1),
  floatingButtonIconColor: Colors.white,
)
```

## API Integration

### API Endpoint

The plugin expects your API to have an endpoint at `api/ai-chat` that accepts POST requests with the following format:

**Request:**
```json
{
  "sessionId": 12345678,
  "userId": 1,
  "prompt": "User's message"
}
```

**Response:**
```json
{
  "textResponse": "Assistant's response text",
  "customObjectsTypes": null,
  "customObjects": null,
  "suggestedResponses": [
    "Suggestion 1",
    "Suggestion 2"
  ]
}
```

### Authentication

The plugin supports Bearer token authentication. Provide a function to get the token:

```dart
getAuthToken: () async {
  // Get token from your storage
  return await secureStorage.read(key: 'auth_token');
}
```

The token will be automatically added to the `Authorization` header as `Bearer {token}`.

### Custom Headers

You can add custom headers to all requests:

```dart
additionalHeaders: {
  'AppVersion': '1.0.0',
  'DeviceModel': 'iPhone 12',
  'DeviceOS': 'iOS 15.0',
}
```

## Advanced Usage

### Programmatic Control

```dart
final assistant = MeaiAssistant(config: config);


// Adjust floating button position
assistant.setBottomSpacing(150.0);

// Clear chat history
assistant.clearMessages();
```

### Accessing Store Directly

```dart
final assistant = MeaiAssistant(config: config);
final store = assistant.assistantStore;

// Access messages
print(store.messages.length);

// Check loading state
print(store.isLoadingAssistantResponse);

// Send message programmatically
await store.sendPrompt("Hello!");
```

### Multiple Instances

If you need multiple assistant instances, you can create them with different configurations:

```dart
final assistant1 = MeaiAssistant(
  config: AssistantConfig(
    assistantName: 'Assistant 1',
    baseUrl: 'https://api1.example.com/',
    // ...
  ),
);

final assistant2 = MeaiAssistant(
  config: AssistantConfig(
    assistantName: 'Assistant 2',
    baseUrl: 'https://api2.example.com/',
    // ...
  ),
);
```

## Customization Examples

### Example 1: Custom Branding

```dart
AssistantConfig(
  assistantName: 'Brand Assistant',
  logoPath: 'assets/brand_logo.png',
  floatingLogoPath: 'assets/brand_icon.png',
  colorScheme: AssistantColorScheme(
    primaryColor: Color(0xFF1E88E5),  // Brand blue
    secondaryColor: Color(0xFF42A5F5),
    floatingButtonColor: Color(0xFF1E88E5),
  ),
  introText: "Welcome! How can I help you today?",
  textFieldHint: "Type your question...",
)
```

### Example 2: Network Images

```dart
AssistantConfig(
  assistantName: 'Cloud Assistant',
  logoPath: 'https://example.com/logo.png',  // Network URL
  floatingLogoPath: 'https://example.com/icon.png',
  // ...
)
```

### Example 3: Custom Suggestions

```dart
AssistantConfig(
  // ...
  suggestionPrompts: [
    'Show me my account balance',
    'What are my recent transactions?',
    'Help me set a budget',
    'Explain my spending patterns',
  ],
)
```

## Widget Structure

The plugin provides several widgets you can use directly:

- `AssistantOverlay`: Wraps your app and provides the assistant UI
- `AssistantModal`: The chat modal interface
- `AssistantFloatingButton`: The floating action button
- `AssistantService`: Manages visibility and modal state
- `AssistantStore`: Manages messages and API calls

## State Management

The plugin uses MobX for state management. The store is automatically set up when you use `wrapApp()`. If you need to access the store in your widgets:

```dart
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<AssistantStore>(context);
    
    return Observer(
      builder: (_) {
        return Text('Messages: ${store.messages.length}');
      },
    );
  }
}
```

## Error Handling

The plugin includes built-in error handling:

- Network errors are caught and a default error message is shown
- Invalid responses are handled gracefully
- Missing assets fall back to default icons

You can customize error handling by modifying the `AssistantStore.sendPrompt()` method.

## Dependencies

The plugin uses the following dependencies:

- `dio`: HTTP client
- `provider`: Dependency injection
- `mobx` & `flutter_mobx`: State management
- `lottie`: Animations (optional, for custom animations)
- `flutter_keyboard_visibility`: Keyboard detection
- `animate_do`: Animations

## Troubleshooting

### Issue: Floating button not showing

**Solution:** Make sure you call `assistant.showAssistant()` after initialization.

### Issue: API calls failing

**Solution:** 
1. Check your `baseUrl` is correct
2. Verify authentication token is being returned
3. Check network permissions in your app

### Issue: Images not loading

**Solution:**
1. For asset images, ensure they're declared in `pubspec.yaml`
2. For network images, check internet connectivity
3. The plugin will fall back to default icons if images fail to load

### Issue: Build errors with MobX

**Solution:** Run the code generator:

```bash
flutter pub run build_runner build
```

## Best Practices

1. **Initialize once**: Create the `MeaiAssistant` instance once and reuse it
2. **Store tokens securely**: Use secure storage for authentication tokens
3. **Handle errors**: Implement proper error handling in your API functions
4. **Test on devices**: Test the keyboard behavior on real devices
5. **Optimize images**: Use optimized images for logos to improve performance

## API Reference

### MeaiAssistant

Main class for managing the assistant.

- `MeaiAssistant({required AssistantConfig config})`: Constructor
- `Widget wrapApp(Widget app)`: Wrap your app with assistant UI
- `void showAssistant()`: Show floating button
- `void hideAssistant()`: Hide floating button
- `void showModal()`: Show chat modal
- `void hideModal()`: Hide chat modal
- `void setBottomSpacing(double spacing)`: Adjust button position
- `void clearMessages()`: Clear chat history

### AssistantConfig

Configuration class for customizing the assistant.

See the Configuration section above for all available options.

### AssistantColorScheme

Color scheme for the assistant UI.

- `AssistantColorScheme.meAi`: Default meAi theme (yellow branding)
- `AssistantColorScheme.purple`: Purple theme
- `AssistantColorScheme.blue`: Blue theme
- `AssistantColorScheme.green`: Green theme
- `AssistantColorScheme({...})`: Custom theme

## License

This project is licensed under the MIT License.

## Support

For issues, questions, or contributions, please reach out your meAi account manager or open an issue on the GitHub repository.


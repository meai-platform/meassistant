import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:keystore_signature/keystore_signature.dart';
import 'package:ios_teamid/ios_teamid.dart';
import 'dart:io';

/// Service for handling SDK authentication with mebank
class SdkAuthService {
  final Dio _dio = Dio();
  final String baseUrl;
  final String? clientId;
  final Future<String?> Function(int timestamp, String clientId, String packageName, String? customerId) getHmac;
  final String? customerId;
  final bool debug;

  String? _accessToken;
  DateTime? _tokenExpiry;
  String? _tokenCustomerId; // Track customerId in current token

  SdkAuthService({
    required this.baseUrl,
    this.clientId,
    required this.getHmac,
    this.customerId,
    this.debug = false,
  }) {
    _dio.options.baseUrl = baseUrl;
  }

  void _debugPrint(String message) {
    if (debug) {
      print(message);
    }
  }

  /// Get package name automatically from the app
  Future<String> _getPackageName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.packageName;
    } catch (e) {
      throw Exception(
          'Failed to get package name automatically from app. Error: $e');
    }
  }

  /// Get app hash automatically calculated from app signing certificate/signature
  /// Uses the actual app signing certificate hash (SHA-256) for security
  /// For iOS, app hash is not used (simplified approach)
  Future<String?> _getAppHash() async {
    try {
      if (Platform.isAndroid) {
        // For Android, get the signing certificate hash using keystore_signature
        // This gets the actual SHA-256 hash of the app's signing certificate
        try {
          final hexKeys = await KeystoreSignature.digestAsHex(HashAlgorithm.sha256);
          if (hexKeys.isNotEmpty) {
            // Use the first (primary) signing certificate hash
            // Convert to lowercase for consistency with backend
            return hexKeys.first.toLowerCase();
          }
        } catch (e) {
          // If keystore_signature fails, return null (app hash is optional)
          return null;
        }
      }
      // For iOS and other platforms, app hash is not used (simplified approach)
      return null;
    } catch (e) {
      // Return null if hash calculation fails (app hash is optional)
      return null;
    }
  }

  /// Get team ID for iOS apps
  /// Uses ios_teamid plugin to retrieve the team ID
  Future<String?> _getTeamId() async {
    if (Platform.isIOS) {
      try {
        final iosTeamidPlugin = IosTeamid();
        final teamId = await iosTeamidPlugin.getTeamId();
        return teamId;
      } catch (e) {
        // Plugin failed, return null
        // Team ID is required for iOS, but we'll let the backend handle validation
        return null;
      }
    }
    return null;
  }

  /// Get OS type: "android" or "ios"
  String _getOs() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  /// Authenticate and get JWT token
  Future<String> authenticate({String? customerId}) async {
    _debugPrint('[MeAI SDK] 🔐 Starting SDK authentication...');
    
    // Use provided customerId or fall back to instance customerId
    final effectiveCustomerId = customerId ?? this.customerId;
    _debugPrint('[MeAI SDK] Customer ID: $effectiveCustomerId');
    
    // Check if we have a valid token and customerId matches
    if (_accessToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        // If customerId changed, we need to re-authenticate
        if (effectiveCustomerId == null || effectiveCustomerId == _tokenCustomerId) {
          _debugPrint('[MeAI SDK] ✅ Using cached token (expires at $_tokenExpiry)');
          return _accessToken!;
        } else {
          _debugPrint('[MeAI SDK] 🔄 Customer ID changed, re-authenticating...');
        }
      } else {
        _debugPrint('[MeAI SDK] ⏰ Token expired, re-authenticating...');
      }
    }

    // Validate required credentials
    if (clientId == null) {
      _debugPrint('[MeAI SDK] ❌ Authentication failed: clientId is required');
      throw Exception('SDK authentication requires clientId');
    }
    
    _debugPrint('[MeAI SDK] Client ID: $clientId');
    
    // Get package name, app hash, OS, and team ID automatically
    _debugPrint('[MeAI SDK] 📦 Retrieving app information...');
    final effectivePackageName = await _getPackageName();
    _debugPrint('[MeAI SDK] Package Name: $effectivePackageName');
    
    final effectiveAppHash = await _getAppHash();
    if (effectiveAppHash != null) {
      _debugPrint('[MeAI SDK] App Hash: $effectiveAppHash');
    }
    
    final os = _getOs();
    _debugPrint('[MeAI SDK] OS: $os');
    
    final teamId = await _getTeamId();
    if (teamId != null) {
      _debugPrint('[MeAI SDK] Team ID: $teamId');
    }

    try {
      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _debugPrint('[MeAI SDK] Timestamp: $timestamp');
      
      // Get HMAC from backend via callback
      // Backend calculates: HMAC-SHA256(clientSecret, timestamp + clientId + packageName + customerId)
      _debugPrint('[MeAI SDK] 🔑 Requesting HMAC from backend...');
      _debugPrint('[MeAI SDK] HMAC Parameters: timestamp=$timestamp, clientId=$clientId, packageName=$effectivePackageName, customerId=$effectiveCustomerId');
      final hmac = await getHmac(timestamp, clientId!, effectivePackageName, effectiveCustomerId);
      if (hmac == null || hmac.isEmpty) {
        _debugPrint('[MeAI SDK] ❌ HMAC calculation failed - getHmac callback returned null or empty');
        throw Exception('HMAC calculation failed - getHmac callback returned null or empty');
      }
      _debugPrint('[MeAI SDK] ✅ HMAC received: ${hmac.substring(0, 20)}...');
      
      final requestData = {
        'packageName': effectivePackageName,
        'clientId': clientId,
        // appHash is automatically calculated from app signature (Android only)
        if (effectiveAppHash != null) 'appHash': effectiveAppHash,
        if (effectiveCustomerId != null && effectiveCustomerId.isNotEmpty) 
          'customerId': effectiveCustomerId,
        'os': os, // Operating system: "android" or "ios"
        if (teamId != null && teamId.isNotEmpty) 'teamId': teamId, // Team ID for iOS
      };
      
      _debugPrint('[MeAI SDK] 📤 Sending authentication request to /api/sdk/auth/token');
      _debugPrint('[MeAI SDK] Request Data: $requestData');
      
      final response = await _dio.post(
        '/api/sdk/auth/token',
        data: requestData,
        options: Options(
          headers: {
            'timestamp': timestamp.toString(),
            'secret-hash': hmac, // HMAC calculated by backend
          },
        ),
      );

      _debugPrint('[MeAI SDK] 📥 Authentication Response: ${response.statusCode}');
      _debugPrint('[MeAI SDK] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['accessToken'] as String;
        final expiresIn = data['expiresIn'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // Refresh 1 minute before expiry
        _tokenCustomerId = effectiveCustomerId; // Store customerId for this token

        _debugPrint('[MeAI SDK] ✅ Authentication successful!');
        _debugPrint('[MeAI SDK] Token expires in: $expiresIn seconds');
        _debugPrint('[MeAI SDK] Token: ${_accessToken!.substring(0, 20)}...');

        return _accessToken!;
      } else {
        _debugPrint('[MeAI SDK] ❌ Authentication failed: ${response.statusMessage}');
        throw Exception('Authentication failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _debugPrint('[MeAI SDK] ❌ Authentication error: ${e.message}');
      if (e.response != null) {
        _debugPrint('[MeAI SDK] Error Response: ${e.response?.data}');
        final errorMessage = e.response?.data['error'] ?? e.message;
        throw Exception('Authentication failed: $errorMessage');
      }
      throw Exception('Authentication failed: ${e.message}');
    }
  }

  /// Get current access token, refreshing if necessary
  Future<String> getAccessToken({String? customerId}) async {
    return await authenticate(customerId: customerId);
  }

  /// Clear stored token (force re-authentication)
  void clearToken() {
    _accessToken = null;
    _tokenExpiry = null;
    _tokenCustomerId = null;
  }
  
  /// Update customerId and re-authenticate if needed
  Future<String> updateCustomerId(String newCustomerId) async {
    if (newCustomerId != _tokenCustomerId) {
      clearToken();
      return await authenticate(customerId: newCustomerId);
    }
    return await getAccessToken();
  }

  /// Check if token is valid
  bool isTokenValid() {
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }
    return DateTime.now().isBefore(_tokenExpiry!);
  }
}


import 'package:dio/dio.dart';
import '../config/assistant_config.dart';
import 'sdk_auth_service.dart';

/// Service for making API calls to the assistant backend
class ApiService {
  final Dio _dio = Dio();
  final AssistantConfig _config;
  final SdkAuthService? _sdkAuthService;

  ApiService(this._config, [SdkAuthService? sdkAuthService])
      : _sdkAuthService = sdkAuthService {
    _dio.options.baseUrl = _config.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _debugPrint('[MeAI SDK] 📤 API Request: ${options.method} ${options.uri}');
        _debugPrint('[MeAI SDK] Request Headers: ${options.headers}');
        if (options.data != null) {
          _debugPrint('[MeAI SDK] Request Body: ${options.data}');
        }
        
        // Prioritize SDK authentication if available
        if (_sdkAuthService != null) {
          try {
            // Get customerId from config for token generation
            final customerId = _config.customerId;
            _debugPrint('[MeAI SDK] 🔐 Getting access token via SDK auth (customerId: $customerId)');
            final token = await _sdkAuthService!.getAccessToken(customerId: customerId);
            options.headers['Authorization'] = 'Bearer $token';
            _debugPrint('[MeAI SDK] ✅ Token obtained successfully');
          } catch (e) {
            _debugPrint('[MeAI SDK] ⚠️ SDK auth failed: $e');
            // Fall back to custom auth token if SDK auth fails
            if (_config.getAuthToken != null) {
              _debugPrint('[MeAI SDK] 🔄 Falling back to custom auth token');
              final token = await _config.getAuthToken!();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          }
        } else if (_config.getAuthToken != null) {
          // Fall back to custom auth token if SDK auth is not configured
          _debugPrint('[MeAI SDK] 🔐 Using custom auth token');
          final token = await _config.getAuthToken!();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        // Add additional headers if provided
        if (_config.additionalHeaders != null) {
          options.headers.addAll(_config.additionalHeaders!);
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        _debugPrint('[MeAI SDK] 📥 API Response: ${response.statusCode} ${response.requestOptions.uri}');
        _debugPrint('[MeAI SDK] Response Headers: ${response.headers}');
        _debugPrint('[MeAI SDK] Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (DioException e, handler) {
        _debugPrint('[MeAI SDK] ❌ API Error: ${e.requestOptions.method} ${e.requestOptions.uri}');
        _debugPrint('[MeAI SDK] Error Status: ${e.response?.statusCode}');
        _debugPrint('[MeAI SDK] Error Message: ${e.message}');
        _debugPrint('[MeAI SDK] Error Response: ${e.response?.data}');
        
        // If unauthorized, try to refresh token and retry
        if (e.response?.statusCode == 401 && _sdkAuthService != null) {
          _debugPrint('[MeAI SDK] 🔄 401 Unauthorized - clearing token for retry');
          _sdkAuthService!.clearToken();
        }
        handler.next(e);
      },
    ));
  }

  void _debugPrint(String message) {
    if (_config.debug) {
      print(message);
    }
  }

  Future<Response> get(String endpoint) async {
    _debugPrint('[MeAI SDK] 🔍 GET Request: $endpoint');
    try {
      final response = await _dio.get(endpoint);
      _debugPrint('[MeAI SDK] ✅ GET Success: $endpoint');
      return response;
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ GET Failed: $endpoint - $e');
      rethrow;
    }
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    _debugPrint('[MeAI SDK] 📤 POST Request: $endpoint');
    _debugPrint('[MeAI SDK] POST Data: $data');
    try {
      final response = await _dio.post(endpoint, data: data);
      _debugPrint('[MeAI SDK] ✅ POST Success: $endpoint');
      return response;
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ POST Failed: $endpoint - $e');
      rethrow;
    }
  }

  Future<Response> postFormData(
      String endpoint, Map<String, dynamic> data) async {
    _debugPrint('[MeAI SDK] 📤 POST FormData Request: $endpoint');
    _debugPrint('[MeAI SDK] FormData: $data');
    try {
      final response = await _dio.post(endpoint, data: FormData.fromMap(data));
      _debugPrint('[MeAI SDK] ✅ POST FormData Success: $endpoint');
      return response;
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ POST FormData Failed: $endpoint - $e');
      rethrow;
    }
  }
}


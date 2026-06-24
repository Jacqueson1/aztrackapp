import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Simple HTTP API client
// - GET/POST/PUT/DELETE
// - JSON body handling
// - Default headers and optional Bearer auth
// - Throws ApiException on errors
class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  // Base API URL. Change to your backend or pass in the constructor.
  late final String baseUrl;
  late final http.Client _client;
  late final Duration timeout;

  String? authToken;
  String? currentUserName;
  Set<String> currentPermissions = {};

  // Internal constructor
  ApiService._internal() {
    _client = http.Client();
    timeout = const Duration(seconds: 30);
    
    if (kIsWeb) {
      baseUrl = 'http://127.0.0.1:8000/api'; // Web uses localhost
    } else if (Platform.isAndroid) {
      // 10.0.2.2 is the host loopback for Android Emulators.
      baseUrl = 'http://10.0.2.2:8000/api'; 
    } else {
      // iOS Simulator or Desktop
      baseUrl = 'http://127.0.0.1:8000/api';
    }
  }

  // Set bearer token
  void setAuthToken(String token) => authToken = token;

  // Clear bearer token
  void clearAuthToken() {
    authToken = null;
    currentUserName = null;
    currentPermissions.clear();
  }

  // Check if current user has permission
  bool hasPermission(String permissionName) {
    return currentPermissions.contains(permissionName);
  }

  // Default headers. Change Content-Type if needed.
  Map<String, String> get _defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // Build full URI from endpoint and optional query params.
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    // If endpoint starts with http it's used as-is, otherwise appended to baseUrl.
    final raw = endpoint.startsWith('http') ? endpoint : baseUrl + endpoint;
    final uri = Uri.parse(raw);
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(queryParameters: queryParams);
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    return _sendRequest(() => _client.get(uri, headers: {..._defaultHeaders, ...?extraHeaders}));
  }

  // POST request with optional JSON body
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint, null);
    return _sendRequest(() => _client.post(uri,
        headers: {..._defaultHeaders, ...?extraHeaders}, body: body != null ? jsonEncode(body) : null));
  }

  // PUT request with optional JSON body
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint, null);
    return _sendRequest(() => _client.put(uri,
        headers: {..._defaultHeaders, ...?extraHeaders}, body: body != null ? jsonEncode(body) : null));
  }

  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    return _sendRequest(() => _client.delete(uri, headers: {..._defaultHeaders, ...?extraHeaders}));
  }

  // Send request, apply timeout, convert low-level errors to ApiException
  Future<dynamic> _sendRequest(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn().timeout(timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(message: 'No internet connection', details: e.toString());
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Connection error', details: e.toString());
    } on TimeoutException catch (e) {
      throw ApiException(message: 'Request timed out', details: e.toString());
    } on FormatException catch (e) {
      throw ApiException(message: 'Invalid response format', details: e.toString());
    } on ApiException {
      // Re-throw ApiException so it doesn't get wrapped in an unexpected error
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error', details: e.toString());
    }
  }

  // Handle response: parse JSON on 2xx, otherwise throw ApiException
  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      try {
        return json.decode(body);
      } catch (_) {
        // If response is not JSON, return raw body.
        return body;
      }
    }

    dynamic details;
    try {
      details = body.isNotEmpty ? json.decode(body) : null;
    } catch (_) {
      details = body;
    }

    throw ApiException(statusCode: status, message: 'HTTP $status', details: details);
  }
}

// API error: contains HTTP status, message, and details
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic details;

  ApiException({this.statusCode, required this.message, this.details});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
}

// Example usage (uncomment and adapt to test):
//
// import 'package:your_app/service/api_service.dart';
//
// Future<void> main() async {
//   // Option A: pass your backend base URL when creating the client
//   final api = ApiService(baseUrl: 'https://api.example.com');
//
//   // Optionally set a bearer token if your API requires authentication
//   api.setAuthToken('your_token_here');
//
//   try {
//     // GET with query params
//     final data = await api.get('/v1/users', queryParams: {'page': '1'});
//     print('Users: $data');
//
//     // POST with JSON body
//     final created = await api.post('/v1/items', body: {'name': 'Item'});
//     print('Created: $created');
//   } on ApiException catch (e) {
//     // Handle API errors centrally
//     print('API error: $e');
//   }
// }

// Notes:
// - Uncomment the code above and replace 'https://api.example.com' with your
//   backend URL to try it locally.
// - If you prefer a file-level default baseUrl, you can uncomment and set a
//   value near the `baseUrl` declaration, but then remove `required` from the
//   constructor parameter.



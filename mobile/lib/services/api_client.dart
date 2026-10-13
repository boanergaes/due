import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final TokenStorage _tokenStorage;
  final http.Client _client;
  void Function()? onUnauthenticated;

  ApiClient({
    TokenStorage? tokenStorage,
    http.Client? client,
    this.onUnauthenticated,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _client = client ?? http.Client();

  /// Build request headers with Bearer token injection
  Future<Map<String, String>> _buildHeaders() async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Process HTTP response and handle 401/422/500 errors
  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      _tokenStorage.deleteToken();
      onUnauthenticated?.call();
      throw ApiException(
        statusCode: 401,
        message: 'Unauthenticated or session expired.',
      );
    }

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'An error occurred';
    Map<String, dynamic>? errors;

    if (body is Map<String, dynamic>) {
      if (body['message'] != null) {
        message = body['message'].toString();
      }
      if (body['errors'] is Map<String, dynamic>) {
        errors = body['errors'] as Map<String, dynamic>;
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }

  /// GET request
  Future<dynamic> get(String url, {Map<String, dynamic>? queryParams}) async {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      uri = uri.replace(queryParameters: cleanParams);
    }

    final headers = await _buildHeaders();
    final response = await _client.get(uri, headers: headers);
    return _processResponse(response);
  }

  /// POST request
  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    final headers = await _buildHeaders();
    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// PUT request
  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    final headers = await _buildHeaders();
    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// PATCH request
  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    final headers = await _buildHeaders();
    final response = await _client.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(String url) async {
    final uri = Uri.parse(url);
    final headers = await _buildHeaders();
    final response = await _client.delete(uri, headers: headers);
    return _processResponse(response);
  }
}

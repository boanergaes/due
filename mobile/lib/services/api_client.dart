import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'device_service.dart';
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

    final deviceName = DeviceService.currentName;
    if (deviceName.isNotEmpty && deviceName != DeviceService.fallbackDeviceName) {
      headers['X-Device-Name'] = deviceName;
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

  ApiException _mapNetworkException(Object e, Uri uri) {
    if (e is TimeoutException) {
      return ApiException(
        statusCode: 408,
        message: 'Request timed out connecting to ${uri.host}:${uri.port}. Server took too long to reply.',
      );
    }
    return ApiException(
      statusCode: 0,
      message: 'Cannot connect to server at ${uri.host}:${uri.port}. Please check your network or server URL in Settings.',
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

    try {
      final headers = await _buildHeaders();
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _mapNetworkException(e, uri);
    }
  }

  /// POST request
  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _buildHeaders();
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _mapNetworkException(e, uri);
    }
  }

  /// PUT request
  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _buildHeaders();
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _mapNetworkException(e, uri);
    }
  }

  /// PATCH request
  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _buildHeaders();
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _mapNetworkException(e, uri);
    }
  }

  /// DELETE request
  Future<dynamic> delete(String url, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _buildHeaders();
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request).timeout(const Duration(seconds: 35));
      final response = await http.Response.fromStream(streamed);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _mapNetworkException(e, uri);
    }
  }

  /// Multipart upload request
  Future<dynamic> uploadMultipart(
    String url, {
    required String fileField,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);

    final headers = await _buildHeaders();
    // Let http set its own multipart boundary Content-Type
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    if (filePath != null && filePath.isNotEmpty) {
      final multipartFile = await http.MultipartFile.fromPath(
        fileField,
        filePath,
        filename: fileName,
      );
      request.files.add(multipartFile);
    } else if (fileBytes != null) {
      final multipartFile = http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
    } else {
      throw ApiException(
        statusCode: 400,
        message: 'No file path or bytes provided for upload.',
      );
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  /// Test reachability of an API endpoint
  Future<(bool, String)> testReachability(String rawUrl) async {
    try {
      final cleanUrl = rawUrl.endsWith('/') ? rawUrl.substring(0, rawUrl.length - 1) : rawUrl;
      final uri = Uri.parse('$cleanUrl/dashboard');
      final headers = await _buildHeaders();
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return (true, 'Connected successfully (${response.statusCode} OK)');
      }
      return (false, 'Server responded with status ${response.statusCode}');
    } on TimeoutException {
      return (false, 'Connection timed out. Check IP and port.');
    } on SocketException catch (e) {
      return (false, 'Network error: ${e.message}');
    } catch (e) {
      return (false, 'Could not reach server: $e');
    }
  }
}

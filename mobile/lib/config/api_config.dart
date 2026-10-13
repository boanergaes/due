import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String? _customBaseUrl;

  /// Override the API base URL at runtime (e.g. for custom LAN IP or production)
  static void setBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Default API base URL depending on runtime platform
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 is the Android emulator loopback alias to host machine localhost
      return 'http://10.0.2.2:8000/api/v1';
    }

    // iOS Simulator, Linux desktop, macOS desktop
    return 'http://127.0.0.1:8000/api/v1';
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get user => '$baseUrl/auth/user';
  static String get logout => '$baseUrl/auth/logout';
  static String get appearance => '$baseUrl/auth/appearance';

  // Dashboard endpoint
  static String get dashboard => '$baseUrl/dashboard';

  // Course Classes endpoints
  static String get classes => '$baseUrl/classes';
  static String classDetail(int id) => '$baseUrl/classes/$id';

  // Assignments endpoints
  static String get assignments => '$baseUrl/assignments';
  static String assignmentDetail(int id) => '$baseUrl/assignments/$id';
  static String assignmentStatus(int id) => '$baseUrl/assignments/$id/status';

  // Assignment Notes endpoints
  static String assignmentNotes(int assignmentId) =>
      '$baseUrl/assignments/$assignmentId/notes';
  static String assignmentNoteDetail(int assignmentId, int noteId) =>
      '$baseUrl/assignments/$assignmentId/notes/$noteId';
}

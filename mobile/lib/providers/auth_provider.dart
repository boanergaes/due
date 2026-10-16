import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/device_service.dart';
import '../services/token_storage.dart';
import 'theme_provider.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final ThemeProvider? themeProvider;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _errorMessage;
  String? _currentToken;
  String? _currentDeviceName;
  Map<String, dynamic>? _currentPassport;
  Map<String, dynamic>? _currentTokenPayload;
  bool _justAuthenticated = false;

  AuthProvider({
    required this.apiClient,
    required this.tokenStorage,
    this.themeProvider,
    User? initialUser,
    AuthStatus? initialStatus,
  })  : _user = initialUser,
        _status = initialStatus ?? (initialUser != null ? AuthStatus.authenticated : AuthStatus.uninitialized) {
    apiClient.onUnauthenticated = _handleUnauthenticated;
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;
  String? get currentToken => _currentToken;
  String get currentDeviceName => _currentDeviceName ?? DeviceService.fallbackDeviceName;
  Map<String, dynamic>? get currentPassport => _currentPassport;
  Map<String, dynamic>? get currentTokenPayload => _currentTokenPayload;
  bool get justAuthenticated => _justAuthenticated;

  void dismissAuthPassport() {
    _justAuthenticated = false;
    notifyListeners();
  }

  static String get defaultDeviceName => DeviceService.fallbackDeviceName;

  void _handleUnauthenticated() {
    _user = null;
    _currentToken = null;
    _currentDeviceName = null;
    _currentPassport = null;
    _currentTokenPayload = null;
    _justAuthenticated = false;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Session expired. Please log in again.';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check stored credentials on application boot
  Future<void> checkAuth() async {
    try {
      final hasToken = await tokenStorage.hasToken();
      if (!hasToken) {
        _currentToken = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _currentToken = await tokenStorage.getToken();
      try {
        final detected = await DeviceService.getDeviceName();
        _currentDeviceName = detected;
      } catch (_) {}

      final response = await apiClient.get(ApiConfig.user);
      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user'] as Map<String, dynamic>);
        if (response['device_name'] != null &&
            (response['device_name'] as String).isNotEmpty) {
          _currentDeviceName = response['device_name'] as String;
        }
        _status = AuthStatus.authenticated;
        _errorMessage = null;

        // Apply theme from database user profile
        if (_user != null && themeProvider != null) {
          themeProvider!.setThemeMode(_user!.appearance);
        }
      } else {
        await tokenStorage.deleteToken();
        _currentToken = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      try {
        await tokenStorage.deleteToken();
      } catch (_) {}
      _currentToken = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Authenticate user credentials and save token
  Future<bool> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final detected = await DeviceService.getDeviceName();
      final targetDeviceName = (deviceName != null &&
              deviceName.isNotEmpty &&
              deviceName != DeviceService.fallbackDeviceName)
          ? deviceName
          : detected;
      final response = await apiClient.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
          'device_name': targetDeviceName,
        },
      );

      final token = response['token'] as String;
      await tokenStorage.saveToken(token);
      _currentToken = token;
      _currentDeviceName = response['device_name'] as String? ?? targetDeviceName;
      _currentPassport = response['passport'] as Map<String, dynamic>?;
      _currentTokenPayload = response['payload'] as Map<String, dynamic>?;
      _justAuthenticated = true;

      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      // Sync theme preference
      if (themeProvider != null && _user != null) {
        themeProvider!.setThemeMode(_user!.appearance);
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Unable to connect to server. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Register a new account
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final detected = await DeviceService.getDeviceName();
      final targetDeviceName = (deviceName != null &&
              deviceName.isNotEmpty &&
              deviceName != DeviceService.fallbackDeviceName)
          ? deviceName
          : detected;
      final response = await apiClient.post(
        ApiConfig.register,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': targetDeviceName,
        },
      );

      final token = response['token'] as String;
      await tokenStorage.saveToken(token);
      _currentToken = token;
      _currentDeviceName = response['device_name'] as String? ?? targetDeviceName;
      _currentPassport = response['passport'] as Map<String, dynamic>?;
      _currentTokenPayload = response['payload'] as Map<String, dynamic>?;
      _justAuthenticated = true;

      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      if (themeProvider != null && _user != null) {
        themeProvider!.setThemeMode(_user!.appearance);
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e.errors != null && e.errors!.isNotEmpty) {
        final firstError = e.errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          _errorMessage = firstError.first.toString();
        } else {
          _errorMessage = e.message;
        }
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Unable to connect to server. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Update appearance preference in database and sync theme
  Future<void> updateAppearance(String appearance) async {
    try {
      await apiClient.patch(
        ApiConfig.appearance,
        body: {'appearance': appearance},
      );

      if (_user != null) {
        _user = _user!.copyWith(appearance: appearance);
      }

      if (themeProvider != null) {
        themeProvider!.setThemeMode(appearance);
      }

      notifyListeners();
    } catch (_) {
      // Ignored if offline
    }
  }

  /// Update user name and email
  Future<bool> updateProfile({required String name, required String email}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.put(
        ApiConfig.profile,
        body: {'name': name, 'email': email},
      );

      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user'] as Map<String, dynamic>);
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update profile. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Update account password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await apiClient.put(
        ApiConfig.password,
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update password. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Delete student account permanently
  Future<bool> deleteAccount({required String password}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await apiClient.delete(
        ApiConfig.deleteAccount,
        body: {'password': password},
      );
      await tokenStorage.deleteToken();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete account. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Log out and revoke personal access token
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConfig.logout);
    } catch (_) {
      // Swallowed on network disconnection
    }

    await tokenStorage.deleteToken();
    _currentToken = null;
    _currentDeviceName = null;
    _currentPassport = null;
    _currentTokenPayload = null;
    _justAuthenticated = false;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}

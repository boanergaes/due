import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/subscription_info.dart';
import '../services/api_client.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiClient apiClient;

  SubscriptionInfo? _subscriptionInfo;
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionProvider({required this.apiClient, SubscriptionInfo? initialInfo})
      : _subscriptionInfo = initialInfo;

  SubscriptionInfo? get subscriptionInfo => _subscriptionInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get tier => _subscriptionInfo?.tier ?? 'free';
  String get tierLabel => _subscriptionInfo?.tierLabel ?? 'Free Tier';
  bool get isFree => _subscriptionInfo?.isFree ?? true;
  bool get isScholar => _subscriptionInfo?.isScholar ?? false;
  bool get isGenius => _subscriptionInfo?.isGenius ?? false;
  bool get canUploadResources => _subscriptionInfo?.canUploadResources ?? false;
  bool get canUseAi => _subscriptionInfo?.canUseAi ?? false;

  /// Fetch subscription details, active plan, and storage quota from API
  Future<void> fetchSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiConfig.subscription);
      if (response is Map<String, dynamic>) {
        _subscriptionInfo = SubscriptionInfo.fromJson(response);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load subscription details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process mock checkout for Scholar or Genius tier
  Future<bool> checkout({
    required String tier,
    required String interval,
    required String cardholderName,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
    String? postalCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
      final cleanExpMonth = expMonth.padLeft(2, '0');
      final cleanExpYear = expYear.length == 2 ? '20$expYear' : expYear;

      final body = {
        'tier': tier,
        'interval': interval,
        'cardholder_name': cardholderName,
        'card_number': cleanCardNumber,
        'exp_month': cleanExpMonth,
        'exp_year': cleanExpYear,
        'cvc': cvc,
        if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
      };

      await apiClient.post(ApiConfig.subscriptionCheckout, body: body);
      // Re-fetch fresh subscription status & quota
      await fetchSubscription();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Mock checkout failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel subscription and return to Free tier
  Future<bool> cancelSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiClient.post(ApiConfig.subscriptionCancel);
      await fetchSubscription();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to cancel subscription: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

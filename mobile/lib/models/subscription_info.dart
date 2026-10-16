class StorageQuota {
  final int usedBytes;
  final int limitBytes;
  final String usedFormatted;
  final String limitFormatted;
  final double percentage;

  const StorageQuota({
    required this.usedBytes,
    required this.limitBytes,
    required this.usedFormatted,
    required this.limitFormatted,
    required this.percentage,
  });

  factory StorageQuota.fromJson(Map<String, dynamic> json) {
    return StorageQuota(
      usedBytes: json['used_bytes'] is int
          ? json['used_bytes'] as int
          : int.tryParse(json['used_bytes']?.toString() ?? '0') ?? 0,
      limitBytes: json['limit_bytes'] is int
          ? json['limit_bytes'] as int
          : int.tryParse(json['limit_bytes']?.toString() ?? '0') ?? 0,
      usedFormatted: json['used_formatted']?.toString() ?? '0 B',
      limitFormatted: json['limit_formatted']?.toString() ?? '0 B',
      percentage: (json['percentage'] is num)
          ? (json['percentage'] as num).toDouble()
          : double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'used_bytes': usedBytes,
        'limit_bytes': limitBytes,
        'used_formatted': usedFormatted,
        'limit_formatted': limitFormatted,
        'percentage': percentage,
      };
}

class ActiveSubscription {
  final int id;
  final String tier;
  final String status;
  final dynamic price;
  final String interval;
  final String? cardBrand;
  final String? cardLastFour;
  final DateTime startsAt;
  final DateTime? endsAt;

  const ActiveSubscription({
    required this.id,
    required this.tier,
    required this.status,
    required this.price,
    required this.interval,
    this.cardBrand,
    this.cardLastFour,
    required this.startsAt,
    this.endsAt,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      tier: json['tier']?.toString() ?? 'basic',
      status: json['status']?.toString() ?? 'active',
      price: json['price'],
      interval: json['interval']?.toString() ?? 'monthly',
      cardBrand: json['card_brand']?.toString(),
      cardLastFour: json['card_last_four']?.toString(),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier,
        'status': status,
        'price': price,
        'interval': interval,
        'card_brand': cardBrand,
        'card_last_four': cardLastFour,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
      };
}

class SubscriptionInfo {
  final String tier;
  final String tierLabel;
  final bool isAdmin;
  final List<String> abilities;
  final StorageQuota storage;
  final DateTime? expiresAt;
  final ActiveSubscription? activeSubscription;

  const SubscriptionInfo({
    required this.tier,
    required this.tierLabel,
    required this.isAdmin,
    required this.abilities,
    required this.storage,
    this.expiresAt,
    this.activeSubscription,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final abilitiesList = <String>[];
    if (json['abilities'] is List) {
      for (final a in json['abilities'] as List) {
        abilitiesList.add(a.toString());
      }
    }

    final storageJson = json['storage'] is Map<String, dynamic>
        ? json['storage'] as Map<String, dynamic>
        : <String, dynamic>{};

    return SubscriptionInfo(
      tier: json['tier']?.toString() ?? 'free',
      tierLabel: json['tier_label']?.toString() ?? 'Free Tier',
      isAdmin: json['is_admin'] == true || json['is_super_admin'] == true,
      abilities: abilitiesList,
      storage: StorageQuota.fromJson(storageJson),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      activeSubscription: json['active_subscription'] is Map<String, dynamic>
          ? ActiveSubscription.fromJson(
              json['active_subscription'] as Map<String, dynamic>)
          : null,
    );
  }

  bool hasFeature(String feature) {
    if (isAdmin) return true;
    if (abilities.contains('feature:$feature') || abilities.contains(feature)) {
      return true;
    }
    if (feature == 'resources') {
      return tier == 'basic' || tier == 'premium';
    }
    if (feature == 'ai') {
      return tier == 'premium';
    }
    return false;
  }

  bool get canUploadResources => hasFeature('resources');
  bool get canUseAi => hasFeature('ai');
  bool get isFree => tier == 'free';
  bool get isScholar => tier == 'basic';
  bool get isGenius => tier == 'premium';

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'tier_label': tierLabel,
        'is_admin': isAdmin,
        'abilities': abilities,
        'storage': storage.toJson(),
        'expires_at': expiresAt?.toIso8601String(),
        'active_subscription': activeSubscription?.toJson(),
      };
}

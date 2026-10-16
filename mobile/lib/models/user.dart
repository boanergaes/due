class User {
  final int id;
  final String name;
  final String email;
  final String appearance;
  final String subscriptionTier;
  final String? createdAt;
  final int classesCount;
  final int assignmentsCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.appearance = 'dark',
    this.subscriptionTier = 'free',
    this.createdAt,
    this.classesCount = 0,
    this.assignmentsCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      appearance: json['appearance'] as String? ?? 'dark',
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      createdAt: json['created_at'] as String?,
      classesCount: json['classes_count'] as int? ?? 0,
      assignmentsCount: json['assignments_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'appearance': appearance,
      'subscription_tier': subscriptionTier,
      'created_at': createdAt,
      'classes_count': classesCount,
      'assignments_count': assignmentsCount,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? appearance,
    String? subscriptionTier,
    String? createdAt,
    int? classesCount,
    int? assignmentsCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      appearance: appearance ?? this.appearance,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
      classesCount: classesCount ?? this.classesCount,
      assignmentsCount: assignmentsCount ?? this.assignmentsCount,
    );
  }
}

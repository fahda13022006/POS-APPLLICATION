class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' atau 'kasir'
  final bool isActive;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'kasir',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'AppUser(uid: $uid, name: $name, role: $role, isActive: $isActive)';
}

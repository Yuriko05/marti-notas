class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' o 'normal'
  final String username; // nombre normalizado para login
  final bool hasPassword; // indica si el usuario tiene contraseña en Auth
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String>? fcmTokens; // Tokens FCM por dispositivo
  final DateTime? fcmTokensUpdatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.username,
    this.hasPassword = false,
    required this.createdAt,
    this.lastLogin,
  this.fcmTokens,
  this.fcmTokensUpdatedAt,
  });

  // Crear un UserModel desde un documento de Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'normal',
      username: data['username'] ?? (data['name'] ?? '').toString().toLowerCase(),
      hasPassword: data['hasPassword'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as dynamic)?.toDate(),
      fcmTokens: (data['fcmTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      fcmTokensUpdatedAt: (data['fcmTokensUpdatedAt'] as dynamic)?.toDate(),
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'username': username,
      'hasPassword': hasPassword,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    if (fcmTokens != null) 'fcmTokens': fcmTokens,
    if (fcmTokensUpdatedAt != null) 'fcmTokensUpdatedAt': fcmTokensUpdatedAt,
    };
  }

  // Verificar si el usuario es administrador
  bool get isAdmin => role == 'admin';

  // Crear una copia del modelo con cambios
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? username,
    bool? hasPassword,
    DateTime? createdAt,
    DateTime? lastLogin,
  List<String>? fcmTokens,
  DateTime? fcmTokensUpdatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      username: username ?? this.username,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
  fcmTokens: fcmTokens ?? this.fcmTokens,
  fcmTokensUpdatedAt: fcmTokensUpdatedAt ?? this.fcmTokensUpdatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, username: $username, role: $role)';
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' o 'normal'
  final String? password; // Contraseña para mostrar en admin
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.password,
    required this.createdAt,
    this.lastLogin,
  });

  // Crear un UserModel desde un documento de Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'normal',
      password: data['password'], // Incluir contraseña si existe
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as dynamic)?.toDate(),
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'password': password,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
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
    String? password,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, role: $role)';
  }
}

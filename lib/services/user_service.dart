import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colección de usuarios en Firestore
  static const String usersCollection = 'users';

  /// Obtener el usuario actual desde Firestore
  static Future<UserModel?> getCurrentUser() async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final DocumentSnapshot doc = await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      // Si el usuario no existe en Firestore, crear uno con rol 'normal'
      return await _createUserInFirestore(firebaseUser);
    } catch (e) {('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Crear un usuario en Firestore si no existe
  static Future<UserModel> _createUserInFirestore(User firebaseUser) async {
    final UserModel newUser = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.email?.split('@')[0] ??
          firebaseUser.displayName ??
          'usuario',
      name: firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'Usuario',
      role: 'normal', // Por defecto, los usuarios son normales
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore
        .collection(usersCollection)
        .doc(firebaseUser.uid)
        .set(newUser.toFirestore());

    return newUser;
  }

  /// Actualizar la última fecha de login
  static Future<void> updateLastLogin() async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _firestore
            .collection(usersCollection)
            .doc(firebaseUser.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {('Error al actualizar último login: $e');
    }
  }

  /// Verificar si el usuario actual es administrador
  static Future<bool> isCurrentUserAdmin() async {
    final UserModel? user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  /// Stream para escuchar cambios en el usuario actual
  static Stream<UserModel?> getCurrentUserStream() {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await getCurrentUser();
    });
  }

  /// Obtener usuario por ID
  static Future<UserModel?> getUserById(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(usersCollection).doc(uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {('Error al obtener usuario por ID: $e');
      return null;
    }
  }

  /// Obtener todos los usuarios (solo para administradores)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final QuerySnapshot query = await _firestore
          .collection(usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {('Error al obtener todos los usuarios: $e');
      return [];
    }
  }

  /// Actualizar rol de usuario (solo para administradores)
  static Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(uid)
          .update({'role': newRole});
      return true;
    } catch (e) {('Error al actualizar rol de usuario: $e');
      return false;
    }
  }

  /// Crear un nuevo usuario (para el panel de admin)
  static Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Nota: La creación de usuarios con email/password requiere
      // usar Firebase Admin SDK desde el backend por seguridad.
      // Este método es un placeholder para la integración futura.

      throw UnimplementedError(
          'La creación de usuarios debe hacerse desde el backend por seguridad');
    } catch (e) {('Error al crear usuario: $e');
      return null;
    }
  }
}

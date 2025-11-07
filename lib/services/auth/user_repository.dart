import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// Repositorio para la gestión de usuarios en Firestore
/// Maneja todas las operaciones CRUD de usuarios en la base de datos
class UserRepository {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Crear perfil de usuario en Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      // Prepare data and ensure we store a normalized `username` for
      // consistent lookups. Do NOT persist plaintext passwords here.
      final Map<String, dynamic> data = Map<String, dynamic>.from(user.toFirestore());

      // Normalize username from display name
      String username = _normalizeName(user.name);
      data['username'] = username;

      // Remove password if present to avoid storing it in Firestore
      if (data.containsKey('password')) {
        data.remove('password');
      }

      await _firestore.collection(_usersCollection).doc(user.uid).set(data);

      debugPrint('UserRepository: Perfil creado para usuario: ${user.uid}');
    } catch (e) {
      debugPrint('UserRepository: Error al crear perfil: $e');
      rethrow;
    }
  }

  /// Obtener perfil de usuario por UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        debugPrint('UserRepository: Perfil no encontrado para UID: $uid');
        return null;
      }

      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      debugPrint('UserRepository: Error al obtener perfil: $e');
      return null;
    }
  }

  /// Stream para escuchar cambios en el perfil de un usuario
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
    });
  }

  /// Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
      }

      if (role != null && role.isNotEmpty) {
        updateData['role'] = role;
      }

      if (updateData.isEmpty) {
        debugPrint('UserRepository: No hay datos para actualizar');
        return false;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updateData);

      debugPrint('UserRepository: Perfil actualizado correctamente');
      return true;
    } catch (e) {
      debugPrint('UserRepository: Error al actualizar perfil: $e');
      return false;
    }
  }

  /// Actualizar última fecha de login
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      debugPrint('UserRepository: Última fecha de login actualizada');
    } catch (e) {
      debugPrint('UserRepository: Error al actualizar última fecha de login: $e');
    }
  }

  /// Eliminar perfil de usuario de Firestore
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      debugPrint('UserRepository: Perfil eliminado de Firestore: $uid');
    } catch (e) {
      debugPrint('UserRepository: Error al eliminar perfil: $e');
      rethrow;
    }
  }

  /// Buscar usuario por nombre en Firestore
  Future<UserModel?> findUserByName(String name) async {
    try {
      final trimmed = name.trim();

      // Try lookup by normalized username first (preferred)
      final normalized = _normalizeName(trimmed);

      QuerySnapshot query = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Fallback to legacy `name` field for backward compatibility
        query = await _firestore
            .collection(_usersCollection)
            .where('name', isEqualTo: trimmed)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return UserModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }

      return null;
    } catch (e) {
      debugPrint('UserRepository: Error buscando usuario por nombre: $e');
      return null;
    }
  }

  /// Normaliza un nombre para usarlo como `username` en Firestore.
  /// Convenciones: lowercase, sin espacios, solo a-z0-9.
  String _normalizeName(String name) {
    final lower = name.toLowerCase().trim();
    final withoutDiacritics = _stripDiacritics(lower);
    return withoutDiacritics
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _stripDiacritics(String input) {
    const Map<String, String> mapping = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'ă': 'a',
      'ą': 'a',
      'Á': 'a',
      'À': 'a',
      'Ä': 'a',
      'Â': 'a',
      'Ã': 'a',
      'Å': 'a',
      'Ă': 'a',
      'Ą': 'a',
      'č': 'c',
      'ć': 'c',
      'ç': 'c',
      'Č': 'c',
      'Ć': 'c',
      'Ç': 'c',
      'ď': 'd',
      'đ': 'd',
      'Ď': 'd',
      'Đ': 'd',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'ě': 'e',
      'ę': 'e',
      'É': 'e',
      'È': 'e',
      'Ë': 'e',
      'Ê': 'e',
      'Ě': 'e',
      'Ę': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'Í': 'i',
      'Ì': 'i',
      'Ï': 'i',
      'Î': 'i',
      'ĺ': 'l',
      'ľ': 'l',
      'ł': 'l',
      'Ĺ': 'l',
      'Ľ': 'l',
      'Ł': 'l',
      'ñ': 'n',
      'ń': 'n',
      'Ñ': 'n',
      'Ń': 'n',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ő': 'o',
      'Ó': 'o',
      'Ò': 'o',
      'Ö': 'o',
      'Ô': 'o',
      'Õ': 'o',
      'Ő': 'o',
      'ř': 'r',
      'Ř': 'r',
      'ś': 's',
      'ș': 's',
      'š': 's',
      'Ś': 's',
      'Ș': 's',
      'Š': 's',
      'ť': 't',
      'Ť': 't',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ů': 'u',
      'ű': 'u',
      'Ú': 'u',
      'Ù': 'u',
      'Ü': 'u',
      'Û': 'u',
      'Ů': 'u',
      'Ű': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'Ý': 'y',
      'Ÿ': 'y',
      'ź': 'z',
      'ż': 'z',
      'ž': 'z',
      'Ź': 'z',
      'Ż': 'z',
      'Ž': 'z',
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(mapping[char] ?? char);
    }
    return buffer.toString();
  }

  /// Obtener todos los usuarios (para panel admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final QuerySnapshot query =
          await _firestore.collection(_usersCollection).get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('UserRepository: Error al obtener todos los usuarios: $e');
      return [];
    }
  }

  /// Verificar si un usuario es administrador
  Future<bool> isUserAdmin(String uid) async {
    try {
      final user = await getUserProfile(uid);
      return user?.isAdmin ?? false;
    } catch (e) {
      debugPrint('UserRepository: Error al verificar si es admin: $e');
      return false;
    }
  }
}

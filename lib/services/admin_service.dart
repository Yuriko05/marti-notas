import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear nuevo usuario simplificado (solo nombre y contraseña)
  static Future<String?> createUser({
    required String name,
    required String password,
    required String role, // 'admin' o 'normal'
  }) async {
    try {
      // Verificar que el usuario actual es admin
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Verificar si el usuario actual es admin usando AuthService
      final isAdmin = await AuthService.isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('No tienes permisos de administrador');
      }

      print('👤 Admin creando usuario: $name ($role)');

      // Usar el nuevo método simplificado de AuthService
      return await AuthService.registerWithNameAndPassword(
        name: name,
        password: password,
        role: role,
      );
    } catch (e) {
      print('Error creando usuario: $e');
      return null;
    }
  }

  /// Obtener todos los usuarios (solo para administradores)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        throw Exception('No tienes permisos de administrador');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  /// Actualizar usuario (solo para administradores)
  static Future<bool> updateUser({
    required String userId,
    required String name,
    required String role,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return false;

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error actualizando usuario: $e');
      return false;
    }
  }

  /// Eliminar usuario (solo para administradores)
  static Future<bool> deleteUser(String userId) async {
    try {
      print('🗑️ Iniciando eliminación de usuario: $userId');

      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        print('❌ Error: No hay usuario autenticado');
        return false;
      }

      print('✅ Usuario actual autenticado: ${currentUser.uid}');

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) {
        print('❌ Error: Documento del usuario actual no existe');
        return false;
      }

      final userData = currentUserDoc.data();
      print('📄 Datos del usuario actual: $userData');

      if (userData?['role'] != 'admin') {
        print(
            '❌ Error: Usuario no tiene permisos de administrador. Rol: ${userData?['role']}');
        return false;
      }

      // No permitir que el admin se elimine a sí mismo
      if (userId == currentUser.uid) {
        print('❌ Error: No se puede eliminar a sí mismo');
        throw Exception('No puedes eliminarte a ti mismo');
      }

      print('🔍 Verificando que el usuario a eliminar existe...');
      final userToDeleteDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userToDeleteDoc.exists) {
        print('❌ Error: El usuario a eliminar no existe');
        return false;
      }

      final userToDeleteData = userToDeleteDoc.data() as Map<String, dynamic>;
      final String userEmail = userToDeleteData['email'] ?? '';

      print('✅ Usuario a eliminar encontrado: ${userToDeleteData}');

      // Usar AuthService para eliminar el usuario (intentará eliminar de Auth y Firestore)
      final success = await AuthService.deleteUserAsAdmin(
        userId: userId,
        userEmail: userEmail,
      );

      if (success) {
        print('✅ Usuario eliminado correctamente');
        return true;
      } else {
        print('❌ Error al eliminar usuario');
        return false;
      }
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Asignar tarea a usuario específico (solo para administradores)
  static Future<String?> assignTaskToUser({
    required String title,
    required String description,
    required String assignedToUserId,
    required DateTime dueDate,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return null;

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        return null;
      }

      // Verificar que el usuario asignado existe
      final assignedUserDoc =
          await _firestore.collection('users').doc(assignedToUserId).get();

      if (!assignedUserDoc.exists) {
        throw Exception('El usuario asignado no existe');
      }

      final taskModel = TaskModel(
        id: '', // Se asignará automáticamente
        title: title,
        description: description,
        status: 'pending',
        dueDate: dueDate,
        createdBy: currentUser.uid,
        assignedTo: assignedToUserId,
        isPersonal: false, // Las tareas asignadas por admin no son personales
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('tasks').add(taskModel.toFirestore());

      // Actualizar el ID del documento
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error asignando tarea: $e');
      return null;
    }
  }

  /// Obtener estadísticas del sistema (solo para administradores)
  static Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return null;

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        return null;
      }

      // Contar usuarios
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.size;
      final adminUsers = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'admin')
          .length;

      // Contar tareas
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final totalTasks = tasksSnapshot.size;
      final pendingTasks = tasksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;
      final completedTasks = tasksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      // Contar notas
      final notesSnapshot = await _firestore.collection('notes').get();
      final totalNotes = notesSnapshot.size;

      return {
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'normalUsers': totalUsers - adminUsers,
        'totalTasks': totalTasks,
        'pendingTasks': pendingTasks,
        'completedTasks': completedTasks,
        'totalNotes': totalNotes,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return null;
    }
  }

  /// Obtener tareas asignadas por el admin
  static Future<List<TaskModel>> getAssignedTasks() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return [];

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: currentUser.uid)
          .where('isPersonal', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo tareas asignadas: $e');
      return [];
    }
  }

  /// Actualizar una tarea existente
  static Future<bool> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String assignedToUserId,
    required DateTime dueDate,
  }) async {
    try {
      print('🔄 Actualizando tarea: $taskId');

      await _firestore.collection('tasks').doc(taskId).update({
        'title': title,
        'description': description,
        'assignedTo': assignedToUserId,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Tarea actualizada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error actualizando tarea: $e');
      return false;
    }
  }

  /// Eliminar una tarea
  static Future<bool> deleteTask(String taskId) async {
    try {
      print('🗑️ Eliminando tarea: $taskId');

      await _firestore.collection('tasks').doc(taskId).delete();

      print('✅ Tarea eliminada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error eliminando tarea: $e');
      return false;
    }
  }
}

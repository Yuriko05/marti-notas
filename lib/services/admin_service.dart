import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import 'auth/session_manager.dart';
import 'history_service.dart';
import 'cloud_functions_service.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear nuevo usuario usando Cloud Function (NO cierra sesión del admin)
  static Future<Map<String, dynamic>?> createUser({
    required String name,
    required String password,
    required String role, // 'admin' o 'normal'
  }) async {
    try {
      // Verificar que el usuario actual es admin
      final currentUser = SessionManager().currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Verificar si el usuario actual es admin usando SessionManager
      final isAdmin = await SessionManager().isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('No tienes permisos de administrador');
      }

      print('👤 Admin creando usuario via Cloud Function: $name ($role)');

      // Usar Cloud Function (NO cierra sesión del admin)
      final result = await CloudFunctionsService.createUser(
        name: name,
        password: password,
        role: role,
      );

      if (result != null && result['success'] == true) {
        print('✅ Usuario creado exitosamente: ${result['name']} (${result['uid']})');
        return result;
      } else {
        print('❌ Error en Cloud Function: ${result?['message']}');
        return result;
      }
    } catch (e) {
      print('❌ Error creando usuario: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': e.toString(),
      };
    }
  }

  /// Crear usuario usando método anterior (DEPRECADO - cierra sesión del admin)
  /// Solo mantener por compatibilidad
  @Deprecated('Usar createUser() que usa Cloud Function')
  static Future<String?> createUserLegacy({
    required String name,
    required String password,
    required String role,
  }) async {
    try {
      final currentUser = SessionManager().currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final isAdmin = await SessionManager().isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('No tienes permisos de administrador');
      }

      print('👤 Admin creando usuario (método legacy): $name ($role)');

      return await SessionManager().registerWithNameAndPassword(
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
      final currentUser = SessionManager().currentUser;
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
      final currentUser = SessionManager().currentUser;
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

      final currentUser = SessionManager().currentUser;
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

      print('✅ Usuario a eliminar encontrado: ${userToDeleteData}');

      // Usar SessionManager para eliminar el usuario (intentará eliminar de Auth y Firestore)
      final success = await SessionManager().deleteUserAsAdmin(
        userId: userId,
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
    String priority = 'medium',
    List<String>? initialAttachments,
    List<String>? initialLinks,
    String? initialInstructions,
  }) async {
    try {
      final currentUser = SessionManager().currentUser;
      if (currentUser == null) return null;

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'admin') {
        return null;
      }

      // Verificar que el usuario asignado existe y que no sea admin
      final assignedUserDoc =
          await _firestore.collection('users').doc(assignedToUserId).get();

      if (!assignedUserDoc.exists) {
        throw Exception('El usuario asignado no existe');
      }

  final assignedUserData = assignedUserDoc.data();
      final assignedUserRole = assignedUserData?['role'] ?? 'normal';
      // Evitar asignar tareas a administradores
      if (assignedUserRole == 'admin') {
        print('Intento de asignar tarea a un usuario con rol admin: $assignedToUserId');
        throw Exception('No se puede asignar tareas a usuarios con rol admin');
      }
      // Si existe un flag "active" y está en false, evitar asignar
      if (assignedUserData != null && assignedUserData.containsKey('active')) {
        final isActive = assignedUserData['active'] == true;
        if (!isActive) {
          print('Intento de asignar tarea a un usuario inactivo: $assignedToUserId');
          throw Exception('El usuario asignado está inactivo');
        }
      }

      final taskModel = TaskModel(
        id: '', // Se asignará automáticamente
        title: title,
        description: description,
        status: 'pending',
        priority: priority,
        dueDate: dueDate,
        createdBy: currentUser.uid,
        assignedTo: assignedToUserId,
        isPersonal: false, // Las tareas asignadas por admin no son personales
        createdAt: DateTime.now(),
        initialAttachments: initialAttachments ?? [],
        initialLinks: initialLinks ?? [],
        initialInstructions: initialInstructions,
      );

      final docRef =
          await _firestore.collection('tasks').add(taskModel.toFirestore());

      // Actualizar el ID del documento
      await docRef.update({'id': docRef.id});

      // Registrar evento de auditoría (escribe tanto en legacy como en nuevo path)
      try {
        await HistoryService.recordEvent(
          taskId: docRef.id,
          action: 'assign',
          actorUid: currentUser.uid,
          actorRole: currentUserDoc.data()?['role'] ?? 'admin',
          payload: {'before': null, 'after': taskModel.toFirestore()},
        );
      } catch (e) {
        print('Warning: no se pudo escribir history para la tarea ${docRef.id}: $e');
      }

      // 🔔 NO enviar notificación local aquí
      // Las notificaciones push se envían automáticamente por Cloud Function
      // (sendTaskAssignedNotification se activa cuando se crea una nueva tarea)

      return docRef.id;
    } catch (e) {
      print('Error asignando tarea: $e');
      return null;
    }
  }

  /// Obtener estadísticas del sistema (solo para administradores)
  static Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      final currentUser = SessionManager().currentUser;
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
      final currentUser = SessionManager().currentUser;
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

  /// Stream de tareas asignadas por el admin (actualizaciones en tiempo real)
  static Stream<List<TaskModel>> streamAssignedTasks() {
    try {
      final currentUser = SessionManager().currentUser;
      if (currentUser == null) return const Stream.empty();

      final snapshots = _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: currentUser.uid)
          .where('isPersonal', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();

      return snapshots.map((snap) => snap.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList());
    } catch (e) {
      print('Error creando stream de tareas asignadas: $e');
      return const Stream.empty();
    }
  }

  /// Actualizar una tarea existente
  static Future<bool> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String assignedToUserId,
    required DateTime dueDate,
    String? priority,
  }) async {
    try {
    print('🔄 Actualizando tarea: $taskId');

    final currentUser = SessionManager().currentUser;
    if (currentUser == null) return false;
    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();

    // Verificar que el usuario asignado existe y no es admin
      final assignedUserDoc =
          await _firestore.collection('users').doc(assignedToUserId).get();
      if (!assignedUserDoc.exists) {
        print('❌ Error: usuario asignado no existe: $assignedToUserId');
        return false;
      }

  final assignedUserData = assignedUserDoc.data();
      final assignedUserRole = assignedUserData?['role'] ?? 'normal';
      if (assignedUserRole == 'admin') {
        print('❌ Error: no se permite asignar/actualizar tarea para usuario admin: $assignedToUserId');
        return false;
      }

      final taskDocRef = _firestore.collection('tasks').doc(taskId);

      // Obtener estado previo
      final prevSnap = await taskDocRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      final updateData = {
        'title': title,
        'description': description,
        'assignedTo': assignedToUserId,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (priority != null) {
        updateData['priority'] = priority;
      }

      await taskDocRef.update(updateData);

      // Obtener estado después de la actualización
      final afterSnap = await taskDocRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      // Registrar evento de auditoría en nuevo servicio
      try {
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'update',
          actorUid: currentUser.uid,
          actorRole: currentUserDoc.data()?['role'] ?? 'admin',
          payload: {'before': prevData, 'after': afterData},
        );
      } catch (e) {
        print('Warning: no se pudo escribir history para la actualización $taskId: $e');
      }

      print('✅ Tarea actualizada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error actualizando tarea: $e');
      return false;
    }
  }

  /// Reasignar una tarea a otro usuario (para bulk actions)
  static Future<bool> reassignTask(String taskId, String newAssignedToUserId) async {
    try {
      print('🔄 Reasignando tarea: $taskId -> $newAssignedToUserId');

      final currentUser = SessionManager().currentUser;
      if (currentUser == null) return false;
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      // Verificar que el usuario asignado existe y no es admin
      final assignedUserDoc =
          await _firestore.collection('users').doc(newAssignedToUserId).get();
      if (!assignedUserDoc.exists) {
        print('❌ Error: usuario asignado no existe: $newAssignedToUserId');
        return false;
      }

      final assignedUserData = assignedUserDoc.data();
      final assignedUserRole = assignedUserData?['role'] ?? 'normal';
      if (assignedUserRole == 'admin') {
        print('❌ Error: no se permite asignar tarea a usuario admin: $newAssignedToUserId');
        return false;
      }

      final taskDocRef = _firestore.collection('tasks').doc(taskId);

      // Obtener estado previo
      final prevSnap = await taskDocRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;
      final oldAssignedTo = prevData?['assignedTo'] as String?;

      await taskDocRef.update({
        'assignedTo': newAssignedToUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Registrar evento de auditoría
      try {
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'reassign',
          actorUid: currentUser.uid,
          actorRole: currentUserDoc.data()?['role'] ?? 'admin',
          payload: {
            'from': oldAssignedTo,
            'to': newAssignedToUserId,
          },
        );
      } catch (e) {
        print('Warning: no se pudo escribir history para la reasignación $taskId: $e');
      }

      print('✅ Tarea reasignada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error reasignando tarea: $e');
      return false;
    }
  }

  /// Eliminar una tarea
  static Future<bool> deleteTask(String taskId) async {
    try {
      print('🗑️ Eliminando tarea: $taskId');

      // Obtener snapshot previo para registro
      final taskDocRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskDocRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      // Registrar evento de eliminación usando HistoryService
      try {
        final currentUser = SessionManager().currentUser;
        String? actorUid = currentUser?.uid;
        String? actorRole;
        if (currentUser != null) {
          final actorDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          if (actorDoc.exists) {
            final roleValue = actorDoc.data()?['role'];
            actorRole = roleValue is String ? roleValue : null;
          }
        }

        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'delete',
          actorUid: actorUid,
          actorRole: actorRole,
          payload: {'before': prevData, 'after': null},
        );
      } catch (e) {
        print('Warning: no se pudo escribir history antes de eliminar $taskId: $e');
      }

      await taskDocRef.delete();

      print('✅ Tarea eliminada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error eliminando tarea: $e');
      return false;
    }
  }
}


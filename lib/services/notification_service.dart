import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import '../constants/firestore_collections.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Subscription para cancelar el listener onTokenRefresh
  static StreamSubscription<String>? _tokenRefreshSubscription;
  
  static const String _channelId = 'task_notifications';
  static const String _channelName = 'Notificaciones de Tareas';
  static const String _channelDescription =
      'Notificaciones para tareas y recordatorios';

  /// Handler estático para mensajes en segundo plano - llamado desde main.dart
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('📥 Procesando mensaje en segundo plano: ${message.messageId}');
    print('Título: ${message.notification?.title}');
    print('Cuerpo: ${message.notification?.body}');
    print('Data: ${message.data}');
    
    // Mostrar notificación local si viene con notification payload
    if (message.notification != null) {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: message.notification!.title ?? 'Nueva notificación',
        body: message.notification!.body ?? '',
        payload: message.data['taskId'] ?? '',
      );
    }
  }

  /// Inicializar el servicio de notificaciones (locales + push)
  static Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración general
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar notificaciones locales
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();
    
    // Inicializar Firebase Cloud Messaging (push)
    await _initializeFCM();
  }

  /// Inicializar Firebase Cloud Messaging
  static Future<void> _initializeFCM() async {
    try {
      // Solicitar permisos de notificaciones push
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Permisos FCM: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Obtener y guardar FCM token
        await _saveFCMToken();

        // Manejar mensajes cuando la app está en primer plano
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📥 Mensaje en primer plano: ${message.messageId}');
          
          if (message.notification != null) {
            // Mostrar notificación local cuando llega push en primer plano
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: message.notification!.title ?? 'Nueva notificación',
              body: message.notification!.body ?? '',
              payload: message.data['taskId'] ?? '',
            );
          }
        });

        // Manejar cuando el usuario toca la notificación (app en segundo plano)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('📱 App abierta desde notificación: ${message.messageId}');
          _handleNotificationTap(message.data);
        });

        // Manejar si la app se abrió desde una notificación (app cerrada)
        RemoteMessage? initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          print('📱 App abierta desde notificación (cerrada): ${initialMessage.messageId}');
          _handleNotificationTap(initialMessage.data);
        }

        print('✅ Firebase Cloud Messaging inicializado correctamente');
      } else {
        print('❌ Permisos de notificaciones push denegados');
      }
    } catch (e) {
      print('❌ Error inicializando FCM: $e');
    }
  }

  /// Guardar FCM token en Firestore
  static Future<void> _saveFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      // Guardar token como un array para soportar múltiples dispositivos por usuario
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          // Usamos fcmTokens (array) en vez de un único fcmToken
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokensUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ FCM Token agregado a fcmTokens: ${token.substring(0, 20)}... (set merge)');
      }

      // Escuchar actualizaciones del token y añadir al array (evita duplicados automáticamente)
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token actualizado: verificando usuario actual');
        try {
          // ⚠️ CRITICAL: Obtener usuario actual en el momento del refresh, no usar variable capturada
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            print('⚠️ No hay usuario autenticado, no guardamos el token refresh');
            return;
          }
          
          final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
          await userRef.set({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'fcmTokensUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Token refresh guardado para usuario: ${currentUser.uid}');
        } catch (e) {
          print('❌ Error guardando nuevo token: $e');
        }
      });
    } catch (e) {
      print('❌ Error guardando FCM token: $e');
    }
  }

  /// Registrar el token del dispositivo actual en Firestore (usado al iniciar sesión)
  static Future<void> registerCurrentDeviceToken() async {
    // Reutilizamos la lógica existente que obtiene y guarda el token
    await _saveFCMToken();
  }

  /// Obtener el FCM token del usuario actual
  static Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('❌ Error obteniendo FCM token: $e');
      return null;
    }
  }

  /// Manejar cuando se toca una notificación push
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('🔔 Notificación tocada con data: $data');
    // TODO: Implementar navegación a la tarea específica
    final taskId = data['taskId'];
    if (taskId != null) {
      print('📋 Navegar a tarea: $taskId');
      // Aquí puedes implementar navegación usando un NavigatorKey global
    }
  }

  /// Crear canal de notificaciones para Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Manejar cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Implementar navegación a la tarea específica
    print('Notificación tocada: ${response.payload}');
  }

  /// Solicitar permisos de notificación
  static Future<bool> requestPermissions() async {
    // Permisos para Android 13+
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted =
          await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    // Permisos para iOS
    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Asumir que está permitido en otras plataformas
  }

  /// Mostrar notificación inmediata
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Programar notificación para una fecha específica
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Convertir DateTime a TZDateTime
    final tz.TZDateTime scheduledTZ =
        tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancelar notificación específica
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Eliminar token FCM del array del usuario (usado al hacer logout)
  static Future<void> removeCurrentDeviceToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      // Cancelar el listener de token refresh para evitar que reinserte tokens
      if (_tokenRefreshSubscription != null) {
        await _tokenRefreshSubscription!.cancel();
        _tokenRefreshSubscription = null;
        print('✅ Listener de token refresh cancelado');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));

      // Intentar eliminar el token localmente para forzar un token nuevo en próximas sesiones
      try {
        await _fcm.deleteToken();
      } catch (e) {
        print('⚠️ No se pudo eliminar el token localmente: $e');
      }

      print('✅ FCM Token eliminado del arreglo y token local borrado');
    } catch (e) {
      print('❌ Error eliminando FCM token: $e');
    }
  }

  /// Programar notificaciones diarias para un usuario
  static Future<void> scheduleDailyReminder() async {
    const int dailyReminderId = 1000; // ID fijo para recordatorio diario

    try {
      // TODO: Migrar la programación de recordatorios a Cloud Tasks para soportar recordatorios push.
      // Programar para las 9:00 AM todos los días
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

      // Si ya pasaron las 9:00 AM de hoy, programar para mañana
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: dailyReminderId,
        title: '¡Buenos días! 📋',
        body: 'Revisa tus tareas pendientes para hoy',
        scheduledTime: scheduledTime,
        payload: 'daily_reminder',
      );
    } catch (e) {
      print('Error programando recordatorio diario: $e');
    }
  }

  /// Programar notificaciones de vencimiento para las tareas del usuario
  static Future<void> scheduleTaskDueNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Simplificar consulta - solo buscar por assignedTo y filtrar después
    final tasksQuery = await FirebaseFirestore.instance
      .collection(FirestoreCollections.tasks)
          .where('assignedTo', isEqualTo: user.uid)
          .get();

      for (final doc in tasksQuery.docs) {
        final task = TaskModel.fromFirestore(doc.data(), doc.id);

        // Solo programar para tareas pendientes
  if (task.status == TaskStatus.pending) {
          // Programar notificación 1 día antes del vencimiento
          final oneDayBefore = task.dueDate.subtract(const Duration(days: 1));
          if (oneDayBefore.isAfter(DateTime.now())) {
            await scheduleNotification(
              id: task.id.hashCode,
              title: '⚠️ Tarea por vencer',
              body: '${task.title} vence mañana',
              scheduledTime: oneDayBefore,
              payload: 'task_due_${task.id}',
            );
          }

          // Programar notificación el día del vencimiento
          if (task.dueDate.isAfter(DateTime.now())) {
            await scheduleNotification(
              id: task.id.hashCode + 1,
              title: '🚨 Tarea vence HOY',
              body: task.title,
              scheduledTime: DateTime(
                task.dueDate.year,
                task.dueDate.month,
                task.dueDate.day,
                9, // 9:00 AM
              ),
              payload: 'task_due_today_${task.id}',
            );
          }
        }
      }
    } catch (e) {
      print('Error programando notificaciones de vencimiento: $e');
    }
  }

  /// Programar notificación cuando se asigna una nueva tarea
  /// NOTA: Esta función se activa desde el backend Node.js, no desde Firebase
  static Future<void> showNewTaskAssignedNotification(TaskModel task) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '📋 Nueva tarea asignada',
      body: task.title,
      payload: 'new_task_${task.id}',
    );
  }

  /// Verificar nuevas tareas asignadas al iniciar sesión
  /// Esta función verifica tareas creadas recientemente, NO es inmediata
  static Future<void> checkForNewAssignedTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Consulta simple solo por assignedTo para evitar índices
    final tasksQuery = await FirebaseFirestore.instance
      .collection(FirestoreCollections.tasks)
          .where('assignedTo', isEqualTo: user.uid)
          .get();

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      int newTasksCount = 0;

      // Filtrar en código las tareas nuevas y no personales
      for (final doc in tasksQuery.docs) {
        final task = TaskModel.fromFirestore(doc.data(), doc.id);

        // Solo tareas no personales (asignadas por admin) y recientes
        if (!task.isPersonal && task.createdAt.isAfter(yesterday)) {
          await showNotification(
            id: DateTime.now().millisecondsSinceEpoch + doc.hashCode,
            title: '📋 Nueva tarea asignada',
            body: task.title,
            payload: 'new_task_${task.id}',
          );
          newTasksCount++;
        }
      }

      if (newTasksCount > 0) {
        print(
            '✅ Verificación al login: $newTasksCount tareas nuevas encontradas');
      }
    } catch (e) {
      print('Error verificando nuevas tareas asignadas: $e');
    }
  }

  /// Configurar notificaciones para cuando el usuario inicie sesión
  static Future<void> setupLoginNotifications() async {
    // Solicitar permisos
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('Permisos de notificación denegados');
      return;
    }

    // Verificar nuevas tareas asignadas (NO inmediato, solo al login)
    await checkForNewAssignedTasks();

    // Programar recordatorio diario
    await scheduleDailyReminder();

    // Programar notificaciones de vencimiento de tareas
    await scheduleTaskDueNotifications();

    print('Notificaciones configuradas exitosamente');
  }

  /// Limpiar notificaciones de tareas completadas
  static Future<void> cleanupCompletedTaskNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Obtener tareas completadas
  final completedTasksQuery = await FirebaseFirestore.instance
    .collection(FirestoreCollections.tasks)
        .where('assignedTo', isEqualTo: user.uid)
    .where('status', isEqualTo: TaskStatus.completed.value)
        .get();

    // Cancelar notificaciones de tareas completadas
    for (final doc in completedTasksQuery.docs) {
      final task = TaskModel.fromFirestore(doc.data(), doc.id);
      await cancelNotification(task.id.hashCode);
      await cancelNotification(task.id.hashCode + 1);
    }
  }

  /// ========================================
  /// NOTIFICACIONES PARA TAREAS ASIGNADAS
  /// ========================================

  /// Notificación inmediata cuando admin asigna una tarea
  static Future<void> showTaskAssignedNotification({
    required String taskTitle,
    required String taskId,
    required String adminName,
  }) async {
    try {
      await showNotification(
        id: taskId.hashCode,
        title: '📋 Nueva Tarea Asignada',
        body: '$adminName te asignó: "$taskTitle"',
        payload: 'task_assigned_$taskId',
      );
      print('✅ Notificación de asignación enviada: $taskTitle');
    } catch (e) {
      print('❌ Error enviando notificación de asignación: $e');
    }
  }

  /// Notificación cuando el admin confirma/acepta una tarea
  static Future<void> showTaskAcceptedNotification({
    required String taskTitle,
    required String taskId,
  }) async {
    try {
      await showNotification(
        id: taskId.hashCode + 100,
        title: '✅ Tarea Aceptada',
        body: 'Tu tarea "$taskTitle" fue confirmada por el administrador',
        payload: 'task_accepted_$taskId',
      );
      print('✅ Notificación de aceptación enviada: $taskTitle');
    } catch (e) {
      print('❌ Error enviando notificación de aceptación: $e');
    }
  }

  /// Notificación cuando el admin rechaza una tarea
  static Future<void> showTaskRejectedNotification({
    required String taskTitle,
    required String taskId,
    String? reason,
  }) async {
    try {
      final body = reason != null
          ? 'Tu tarea "$taskTitle" fue rechazada. Motivo: $reason'
          : 'Tu tarea "$taskTitle" fue rechazada por el administrador';
      
      await showNotification(
        id: taskId.hashCode + 200,
        title: '❌ Tarea Rechazada',
        body: body,
        payload: 'task_rejected_$taskId',
      );
      print('✅ Notificación de rechazo enviada: $taskTitle');
    } catch (e) {
      print('❌ Error enviando notificación de rechazo: $e');
    }
  }

  /// ========================================
  /// NOTIFICACIONES PARA TAREAS PERSONALES
  /// ========================================

  /// Programar notificaciones para una tarea personal
  static Future<void> schedulePersonalTaskNotifications({
    required TaskModel task,
  }) async {
    if (!task.isPersonal) return;

    try {
      // Cancelar notificaciones anteriores si existen
      await cancelTaskNotifications(task.id);

      // 1. Notificación 1 día antes de vencer
      final oneDayBefore = task.dueDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: task.id.hashCode + 10,
          title: '⏰ Recordatorio de Tarea Personal',
          body: '"${task.title}" vence mañana',
          scheduledTime: oneDayBefore,
          payload: 'personal_task_reminder_${task.id}',
        );
      }

      // 2. Notificación al momento de vencer
      if (task.dueDate.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: task.id.hashCode + 11,
          title: '🔔 Tarea Personal Venciendo',
          body: '"${task.title}" vence ahora',
          scheduledTime: task.dueDate,
          payload: 'personal_task_due_${task.id}',
        );
      }

      print('✅ Notificaciones programadas para tarea personal: ${task.title}');
    } catch (e) {
      print('❌ Error programando notificaciones personales: $e');
    }
  }

  /// Notificación cuando se completa una tarea personal
  static Future<void> showPersonalTaskCompletedNotification({
    required String taskTitle,
    required String taskId,
  }) async {
    try {
      await showNotification(
        id: taskId.hashCode + 300,
        title: '🎉 ¡Tarea Completada!',
        body: 'Completaste: "$taskTitle"',
        payload: 'personal_task_completed_$taskId',
      );
      print('✅ Notificación de tarea personal completada: $taskTitle');
    } catch (e) {
      print('❌ Error enviando notificación de completación: $e');
    }
  }

  /// Cancelar todas las notificaciones de una tarea
  static Future<void> cancelTaskNotifications(String taskId) async {
    try {
      await cancelNotification(taskId.hashCode);
      await cancelNotification(taskId.hashCode + 1);
      await cancelNotification(taskId.hashCode + 10);
      await cancelNotification(taskId.hashCode + 11);
      await cancelNotification(taskId.hashCode + 100);
      await cancelNotification(taskId.hashCode + 200);
      await cancelNotification(taskId.hashCode + 300);
      print('🗑️ Notificaciones canceladas para tarea: $taskId');
    } catch (e) {
      print('❌ Error cancelando notificaciones: $e');
    }
  }

  /// ========================================
  /// DEPRECATED - Mantener por compatibilidad
  /// ========================================

  /// @deprecated Use showTaskAssignedNotification instead
  static Future<void> showInstantTaskNotification({
    required String taskTitle,
    required String userName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generar ID único para esta notificación
    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notifications.show(
      notificationId,
      '📋 Nueva Tarea Asignada',
      'Te han asignado: "$taskTitle"',
      platformDetails,
      payload: 'instant_task_notification',
    );

    print('✅ Notificación instantánea enviada: $taskTitle para $userName');
  }
}

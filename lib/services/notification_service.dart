import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'task_notifications';
  static const String _channelName = 'Notificaciones de Tareas';
  static const String _channelDescription =
      'Notificaciones para tareas y recordatorios';

  /// Inicializar el servicio de notificaciones
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

    // Inicializar
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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

  /// Programar notificaciones diarias para un usuario
  static Future<void> scheduleDailyReminder() async {
    const int dailyReminderId = 1000; // ID fijo para recordatorio diario

    try {
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
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .get();

      for (final doc in tasksQuery.docs) {
        final task = TaskModel.fromFirestore(doc.data(), doc.id);

        // Solo programar para tareas pendientes
        if (task.status == 'pending') {
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
          .collection('tasks')
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
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .get();

    // Cancelar notificaciones de tareas completadas
    for (final doc in completedTasksQuery.docs) {
      final task = TaskModel.fromFirestore(doc.data(), doc.id);
      await cancelNotification(task.id.hashCode);
      await cancelNotification(task.id.hashCode + 1);
    }
  }

  /// Mostrar notificación inmediata cuando se asigna una tarea
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

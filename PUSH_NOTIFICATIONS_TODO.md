Este archivo ha sido consolidado en `NOTIFICACIONES_RESUMEN.md`.
Por compatibilidad histórica queda este marcador para evitar pérdidas de referencia.

```dart
class UserModel {
  // ... campos existentes ...
  final String? fcmToken;            // 🆕
  final DateTime? fcmTokenUpdatedAt; // 🆕

  UserModel({
    // ... parámetros existentes ...
    this.fcmToken,
    this.fcmTokenUpdatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      // ... campos existentes ...
      fcmToken: data['fcmToken'],
      fcmTokenUpdatedAt: data['fcmTokenUpdatedAt']?.toDate(),
    );
  }
}
```

---

### FASE 2: Envío de Notificaciones

#### 2.1 Crear `notification_service.dart`

**⚠️ IMPORTANTE:** Firebase ya NO permite enviar notificaciones directamente desde la app por seguridad. Hay 3 opciones:

**Opción A: Cloud Functions (RECOMENDADA)** ✅

```javascript
// functions/index.js (Firebase Cloud Functions)
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Notificar a admin cuando usuario envía tarea
exports.notifyAdminOnTaskSubmission = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Si cambió a pending_review
    if (newData.status === 'pending_review' && oldData.status !== 'pending_review') {
      // Obtener tokens de todos los admins
      const adminsSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'admin')
        .get();
      
      const tokens = adminsSnapshot.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token != null);
      
      if (tokens.length === 0) return;
      
      // Enviar notificación
      const message = {
        notification: {
          title: '📝 Nueva tarea para revisar',
          body: `${newData.assignedToName} completó: ${newData.title}`,
        },
        data: {
          type: 'task_submitted',
          taskId: context.params.taskId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
      };
      
      await admin.messaging().sendMulticast(message);
    }
  });

// Notificar a usuario cuando admin revisa
exports.notifyUserOnTaskReview = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Si cambió a completed o needs_review
    if ((newData.status === 'completed' || newData.status === 'needs_review') 
        && oldData.status === 'pending_review') {
      
      // Obtener token del usuario asignado
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(newData.assignedTo)
        .get();
      
      const token = userDoc.data()?.fcmToken;
      if (!token) return;
      
      const isApproved = newData.status === 'completed';
      
      // Enviar notificación
      const message = {
        notification: {
          title: isApproved ? '✅ Tarea Aprobada' : '❌ Tarea Rechazada',
          body: isApproved 
            ? `Tu tarea "${newData.title}" fue aprobada`
            : `Tu tarea "${newData.title}" necesita correcciones`,
        },
        data: {
          type: isApproved ? 'task_approved' : 'task_rejected',
          taskId: context.params.taskId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: token,
      };
      
      await admin.messaging().send(message);
    }
  });
```

**Opción B: Backend Propio (Node.js, Python, etc.)**
- Crear API REST
- Recibir solicitudes desde la app
- Enviar notificaciones con Admin SDK

**Opción C: Servicio Externo (OneSignal, Pusher, etc.)**
- Integrar SDK de terceros
- Más costo pero más fácil

---

### FASE 3: Manejo de Notificaciones Recibidas

#### 3.1 Crear `notification_handler.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level function para manejar en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Mostrar notificación local si es necesario
}

class NotificationHandler {
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Configurar notificaciones locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Configurar canal de Android
    const androidChannel = AndroidNotificationChannel(
      'task_notifications',
      'Notificaciones de Tareas',
      description: 'Notificaciones sobre tareas asignadas y revisadas',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Configurar handlers de FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Manejar notificación que abrió la app
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  // Manejar notificación cuando app está en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Mostrar notificación local
    _showLocalNotification(
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      message.data,
    );
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Notificaciones de Tareas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data['taskId'],
    );
  }

  // Manejar cuando se toca la notificación
  void _handleNotificationOpen(RemoteMessage message) {
    print('Notification opened: ${message.data}');
    
    final type = message.data['type'];
    final taskId = message.data['taskId'];

    // Navegar según el tipo
    if (taskId != null) {
      // Navegar a la tarea
      // Usar Navigator global o notificar a la app
      navigateToTask(taskId, type);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId != null) {
      navigateToTask(taskId, 'local');
    }
  }

  // Método para navegar (implementar según tu navegación)
  void navigateToTask(String taskId, String? type) {
    // TODO: Implementar navegación
    // Opción 1: Usar GlobalKey<NavigatorState>
    // Opción 2: Usar Provider para notificar
    // Opción 3: Usar Stream/EventBus
    print('Navigate to task: $taskId (type: $type)');
  }
}
```

---

### FASE 4: Integración en la App

#### 4.1 Actualizar `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 🆕 Inicializar handler de notificaciones en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // ...
}

class _MyAppState extends State<MyApp> {
  final NotificationHandler _notificationHandler = NotificationHandler();
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationHandler.initialize();
  }
  
  // ...
}
```

#### 4.2 Inicializar FCM en Login

```dart
// En auth_service.dart o donde manejes el login

Future<void> _onLoginSuccess(String userId) async {
  // ... código existente ...
  
  // 🆕 Inicializar FCM
  final fcmService = FCMService();
  await fcmService.initialize(userId);
}

Future<void> logout() async {
  final userId = _auth.currentUser?.uid;
  
  // 🆕 Eliminar token FCM
  if (userId != null) {
    final fcmService = FCMService();
    await fcmService.deleteToken(userId);
  }
  
  await _auth.signOut();
}
```

---

## 📱 Configuración de Plataforma

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest>
  <application>
    <!-- ... contenido existente ... -->

    <!-- 🆕 Intent filter para notificaciones -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="task_notifications" />

    <meta-data
      android:name="com.google.firebase.messaging.default_notification_icon"
      android:resource="@drawable/ic_notification" />

    <meta-data
      android:name="com.google.firebase.messaging.default_notification_color"
      android:resource="@color/notification_color" />
  </application>
</manifest>
```

### iOS (`ios/Runner/AppDelegate.swift`)

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // 🆕 Solicitar permisos de notificaciones
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🧪 Testing

### Pruebas Manuales:

1. **Obtención de Token:**
   - Login → Verificar que se guarda `fcmToken` en Firestore

2. **Notificación Admin:**
   - Usuario completa tarea
   - Verificar que admin recibe push
   - Tocar notificación → Debe abrir la tarea

3. **Notificación Usuario:**
   - Admin aprueba/rechaza
   - Verificar que usuario recibe push
   - Tocar notificación → Debe abrir la tarea

4. **Estados de la App:**
   - App en foreground → Mostrar notificación local
   - App en background → Recibir push normal
   - App cerrada → Recibir push y abrir al tocar

5. **Múltiples Dispositivos:**
   - Login en 2 dispositivos
   - Verificar que ambos reciben notificaciones

### Testing desde Firebase Console:

1. Ir a **Cloud Messaging** en Firebase Console
2. Clic en "Enviar primer mensaje"
3. Ingresar título y texto
4. Seleccionar token FCM de prueba
5. Enviar y verificar recepción

---

## 💰 Costos Estimados (Plan Blaze)

### FCM (Firebase Cloud Messaging):
- ✅ **GRATIS ilimitado** para notificaciones push
- Sin costo adicional

### Cloud Functions:
- ✅ **Gratuito hasta:**
  - 2M invocaciones/mes
  - 400,000 GB-segundos/mes
  - 200,000 CPU-segundos/mes
- Después: ~$0.40 por 1M invocaciones adicionales
- **Estimado para app pequeña:** Gratis o < $1/mes

### Total Estimado: **$0 - $2/mes**

---

## ⏱️ Tiempo de Implementación Estimado

| Fase | Tiempo | Dificultad |
|------|--------|------------|
| Fase 1: Servicio FCM | 2-3 horas | Media |
| Fase 2: Cloud Functions | 3-4 horas | Media-Alta |
| Fase 3: Handler | 2-3 horas | Media |
| Fase 4: Integración | 1-2 horas | Baja |
| Testing | 2-3 horas | Media |
| **TOTAL** | **10-15 horas** | **Media** |

---

## ✅ Checklist de Implementación

### Preparación:
- [ ] Habilitar Cloud Functions en Firebase Console
- [ ] Configurar cuenta de billing (necesario para Cloud Functions)
- [ ] Instalar Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`
- [ ] Init functions: `firebase init functions`

### Código Flutter:
- [ ] Crear `fcm_service.dart`
- [ ] Crear `notification_handler.dart`
- [ ] Actualizar `user_model.dart`
- [ ] Actualizar `main.dart`
- [ ] Actualizar `auth_service.dart`

### Cloud Functions:
- [ ] Crear `functions/index.js`
- [ ] Implementar `notifyAdminOnTaskSubmission`
- [ ] Implementar `notifyUserOnTaskReview`
- [ ] Deploy: `firebase deploy --only functions`

### Configuración Plataforma:
- [ ] Actualizar `AndroidManifest.xml`
- [ ] Actualizar `AppDelegate.swift`
- [ ] Agregar iconos de notificación

### Testing:
- [ ] Probar obtención de token
- [ ] Probar notificación admin (tarea enviada)
- [ ] Probar notificación usuario (tarea aprobada)
- [ ] Probar notificación usuario (tarea rechazada)
- [ ] Probar navegación al tocar
- [ ] Probar en múltiples dispositivos

---

## 📚 Recursos Adicionales

### Documentación Oficial:
- [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [firebase_messaging](https://pub.dev/packages/firebase_messaging)

### Tutoriales Recomendados:
- [FlutterFire Messaging Overview](https://firebase.flutter.dev/docs/messaging/overview)
- [Handling Background Messages](https://firebase.flutter.dev/docs/messaging/usage#handling-messages)
- [Cloud Functions Quick Start](https://firebase.google.com/docs/functions/get-started)

---

## 🚀 Siguiente Paso

**¿Deseas que implemente las notificaciones push?**

Puedo empezar con:
1. Crear los servicios Flutter (`fcm_service.dart` y `notification_handler.dart`)
2. Crear las Cloud Functions
3. Configurar la integración completa

**Responde:**
- ✅ "Sí, implementa las notificaciones" → Comenzaré con la Fase 1
- ⏸️ "Más tarde" → OK, está documentado para cuando lo necesites
- ❓ "Tengo preguntas" → Pregúntame lo que necesites

---

**Fecha:** Enero 2024  
**Estado:** Documentado y listo para implementar  
**Prioridad:** Alta (mejora significativa UX)

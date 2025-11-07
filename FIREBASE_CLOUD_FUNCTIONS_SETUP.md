# Configuración de Firebase Cloud Functions para Notificaciones Push

## 📋 Resumen
Este documento describe cómo configurar Firebase Cloud Functions para enviar notificaciones push cuando un admin asigna una tarea a un usuario.

## 🚀 Pasos de Configuración

### 1. Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Iniciar sesión en Firebase

```bash
firebase login
```

### 3. Inicializar Functions en el proyecto

Desde la raíz del proyecto (donde está `firebase.json`):

```bash
firebase init functions
```

Selecciona:
- Language: **TypeScript** (recomendado) o JavaScript
- ESLint: **Yes**
- Install dependencies: **Yes**

### 4. Crear la función para enviar notificaciones

Edita `functions/src/index.ts` (o `index.js`):

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Cloud Function que escucha cuando se crea una nueva tarea
 * y envía una notificación push al usuario asignado
 */
export const sendTaskAssignedNotification = functions.firestore
  .document("tasks/{taskId}")
  .onCreate(async (snapshot, context) => {
    try {
      const task = snapshot.data();
      const taskId = context.params.taskId;

      // Solo enviar notificación para tareas asignadas (no personales)
      if (task.isPersonal) {
        console.log(`Tarea ${taskId} es personal, no se envía notificación`);
        return null;
      }

      // Obtener información del usuario asignado
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(task.assignedTo)
        .get();

      if (!userDoc.exists) {
        console.log(`Usuario ${task.assignedTo} no encontrado`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`Usuario ${task.assignedTo} no tiene FCM token`);
        return null;
      }

      // Obtener información del admin que asignó
      const adminDoc = await admin
        .firestore()
        .collection("users")
        .doc(task.createdBy)
        .get();

      const adminName = adminDoc.exists ? adminDoc.data()?.name : "Admin";

      // Construir el mensaje de notificación
      const message = {
        notification: {
          title: "📋 Nueva Tarea Asignada",
          body: `${adminName} te asignó: "${task.title}"`,
        },
        data: {
          taskId: taskId,
          type: "task_assigned",
          priority: task.priority || "medium",
        },
        token: fcmToken,
      };

      // Enviar la notificación
      const response = await admin.messaging().send(message);
      console.log(`✅ Notificación enviada exitosamente: ${response}`);

      return response;
    } catch (error) {
      console.error("❌ Error enviando notificación:", error);
      return null;
    }
  });

/**
 * Cloud Function para enviar notificación cuando una tarea es rechazada
 */
export const sendTaskRejectedNotification = functions.firestore
  .document("tasks/{taskId}")
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const taskId = context.params.taskId;

      // Verificar si el estado cambió a 'rejected'
      if (before.status !== "rejected" && after.status === "rejected") {
        // Obtener FCM token del usuario
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(after.assignedTo)
          .get();

        if (!userDoc.exists) {
          console.log(`Usuario ${after.assignedTo} no encontrado`);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
          console.log(`Usuario ${after.assignedTo} no tiene FCM token`);
          return null;
        }

        // Construir mensaje
        const message = {
          notification: {
            title: "❌ Tarea Rechazada",
            body: `La tarea "${after.title}" fue rechazada`,
          },
          data: {
            taskId: taskId,
            type: "task_rejected",
            reviewComment: after.reviewComment || "Sin comentarios",
          },
          token: fcmToken,
        };

        // Enviar notificación
        const response = await admin.messaging().send(message);
        console.log(`✅ Notificación de rechazo enviada: ${response}`);

        return response;
      }

      return null;
    } catch (error) {
      console.error("❌ Error enviando notificación de rechazo:", error);
      return null;
    }
  });

/**
 * Cloud Function para enviar notificación cuando una tarea es aprobada
 */
export const sendTaskApprovedNotification = functions.firestore
  .document("tasks/{taskId}")
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const taskId = context.params.taskId;

      // Verificar si el estado cambió a 'confirmed'
      if (before.status !== "confirmed" && after.status === "confirmed") {
        // Obtener FCM token del usuario
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(after.assignedTo)
          .get();

        if (!userDoc.exists) {
          console.log(`Usuario ${after.assignedTo} no encontrado`);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
          console.log(`Usuario ${after.assignedTo} no tiene FCM token`);
          return null;
        }

        // Construir mensaje
        const message = {
          notification: {
            title: "✅ Tarea Aprobada",
            body: `La tarea "${after.title}" fue aprobada por el admin`,
          },
          data: {
            taskId: taskId,
            type: "task_approved",
            reviewComment: after.reviewComment || "",
          },
          token: fcmToken,
        };

        // Enviar notificación
        const response = await admin.messaging().send(message);
        console.log(`✅ Notificación de aprobación enviada: ${response}`);

        return response;
      }

      return null;
    } catch (error) {
      console.error("❌ Error enviando notificación de aprobación:", error);
      return null;
    }
  });
```

### 5. Instalar dependencias

```bash
cd functions
npm install firebase-admin firebase-functions
npm install -D @types/node
cd ..
```

### 6. Desplegar las Functions

```bash
firebase deploy --only functions
```

## 📱 Configuración Adicional para Android

### AndroidManifest.xml

Agrega dentro de `<application>`:

```xml
<!-- Firebase Messaging Service -->
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Notificaciones en segundo plano -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="task_notifications" />
```

### android/app/build.gradle

Verifica que tenga:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

## 🍎 Configuración Adicional para iOS

### Info.plist

Agrega:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### AppDelegate.swift

```swift
import UIKit
import Flutter
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
                           didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

## 🧪 Testing

### Probar notificación manualmente desde Firebase Console

1. Ve a Firebase Console > Cloud Messaging
2. Click en "Send your first message"
3. Título: "Test Notificación"
4. Cuerpo: "Esta es una prueba"
5. Click en "Send test message"
6. Pega el FCM token (se imprime en consola cuando inicias sesión)
7. Click en "Test"

### Ver logs de Cloud Functions

```bash
firebase functions:log
```

## 🔧 Troubleshooting

### No recibo notificaciones

1. Verifica que el FCM token esté guardado en Firestore:
   ```
   users/{userId}/fcmToken
   ```

2. Revisa logs de Cloud Functions:
   ```bash
   firebase functions:log
   ```

3. Verifica permisos de notificaciones en el dispositivo

4. Para Android: Verifica que google-services.json esté actualizado

5. Para iOS: Verifica que GoogleService-Info.plist esté actualizado

### Las notificaciones solo funcionan en primer plano

- Verifica que `FirebaseMessaging.onBackgroundMessage` esté configurado
- En Android: Verifica el canal de notificaciones
- En iOS: Verifica permisos y configuración de APNs

## 📚 Referencias

- [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [FlutterFire Messaging](https://firebase.flutter.dev/docs/messaging/overview)

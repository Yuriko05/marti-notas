# 🔔 Sistema de Notificaciones - Arquitectura Corregida

**Fecha:** 31 de octubre de 2025  
**Estado:** ✅ BUG CORREGIDO - Notificaciones ahora llegan al dispositivo correcto

---

## ⚠️ PROBLEMA SOLUCIONADO

### Bug Original
Cuando el administrador asignaba/confirmaba/rechazaba una tarea desde su teléfono, la notificación aparecía en **su propio dispositivo** en lugar del dispositivo del usuario asignado.

### Causa Raíz
Se estaban usando **notificaciones locales** (`flutter_local_notifications`) para acciones entre dispositivos. Las notificaciones locales solo se muestran en el dispositivo que ejecuta el código.

### Solución Implementada
Se **eliminaron las notificaciones locales** de las acciones del admin y ahora se depende **exclusivamente de Cloud Functions** que envían notificaciones push al token FCM del usuario correcto.

---

## 🏗️ Arquitectura de Notificaciones

### 1. **Notificaciones PUSH (Cloud Functions)** 
**Para: Acciones entre dispositivos diferentes**

#### Cuándo usar:
- ✅ Admin asigna tarea a otro usuario
- ✅ Admin confirma tarea de otro usuario  
- ✅ Admin rechaza tarea de otro usuario

#### Cómo funciona:
1. Admin realiza acción en Firestore (crear/actualizar tarea)
2. Cloud Function detecta cambio (onCreate/onUpdate trigger)
3. Cloud Function lee el `fcmToken` del usuario asignado desde Firestore
4. Cloud Function envía push notification al token FCM
5. Notificación aparece en el dispositivo del usuario asignado ✅

#### Cloud Functions Desplegadas:
- `sendTaskAssignedNotification` - Trigger: onCreate tasks
- `sendTaskApprovedNotification` - Trigger: onUpdate when status='confirmed'  
- `sendTaskRejectedNotification` - Trigger: onUpdate when status='rejected'

---

### 2. **Notificaciones LOCALES**
**Para: Acciones del mismo usuario en su propio dispositivo**

#### Cuándo usar:
- ✅ Usuario crea tarea personal (para sí mismo)
- ✅ Usuario completa tarea personal

#### Cómo funciona:
1. Usuario crea/completa tarea personal
2. `flutter_local_notifications` muestra notificación local
3. Notificación aparece en el mismo dispositivo ✅

#### Métodos Locales Activos:
- `schedulePersonalTaskNotifications()` - Programa notificaciones para tareas personales
- `showPersonalTaskCompletedNotification()` - Felicitación al completar tarea personal
- `cancelTaskNotifications()` - Cancela notificaciones programadas

---

## 📝 Cambios en el Código

### ❌ **ELIMINADO** - `AdminService.assignTaskToUser()` (líneas 289-299)

```dart
// ❌ ELIMINADO - Causaba que notificación apareciera en teléfono del admin
try {
  final adminName = currentUserDoc.data()?['name'] ?? 'Administrador';
  await NotificationService.showTaskAssignedNotification(
    taskTitle: title,
    taskId: docRef.id,
    adminName: adminName,
  );
} catch (e) {
  print('Warning: no se pudo enviar notificación: $e');
}
```

**Reemplazado con:**
```dart
// 🔔 NO enviar notificación local aquí
// Las notificaciones push se envían automáticamente por Cloud Function
// (sendTaskAssignedNotification se activa cuando se crea una nueva tarea)
```

---

### ❌ **ELIMINADO** - `TaskService.confirmTask()` (líneas 104-111)

```dart
// ❌ ELIMINADO - Causaba que notificación apareciera en teléfono del admin
if (task != null && !task.isPersonal) {
  await NotificationService.showTaskAcceptedNotification(
    taskTitle: task.title,
    taskId: taskId,
  );
}
```

**Reemplazado con:**
```dart
// 🔔 NO enviar notificación local aquí
// Las notificaciones push se envían automáticamente por Cloud Function
// (sendTaskApprovedNotification se activa cuando status cambia a 'confirmed')
```

---

### ❌ **ELIMINADO** - `TaskService.rejectTask()` (líneas 156-163)

```dart
// ❌ ELIMINADO - Causaba que notificación apareciera en teléfono del admin
if (task != null && !task.isPersonal) {
  await NotificationService.showTaskRejectedNotification(
    taskTitle: task.title,
    taskId: taskId,
    reason: reason,
  );
}
```

**Reemplazado con:**
```dart
// 🔔 NO enviar notificación local aquí
// Las notificaciones push se envían automáticamente por Cloud Function
// (sendTaskRejectedNotification se activa cuando status cambia a 'rejected')
```

---

### ✅ **MANTENIDO** - Notificaciones Locales para Tareas Personales

#### `TaskService.createPersonalTask()` (líneas 608-610)
```dart
// ✅ CORRECTO - Usuario crea tarea para sí mismo, notificación local OK
final task = TaskModel.fromFirestore(taskData, docRef.id);
await NotificationService.schedulePersonalTaskNotifications(task: task);
```

#### `TaskService.completeTask()` (líneas 434-443)
```dart
// ✅ CORRECTO - Usuario completa su propia tarea, notificación local OK
if (task != null) {
  await NotificationService.cancelTaskNotifications(taskId);
  
  if (task.isPersonal) {
    await NotificationService.showPersonalTaskCompletedNotification(
      taskTitle: task.title,
      taskId: taskId,
    );
  }
}
```

---

## 🧪 Pruebas de Validación

### Escenario 1: Admin Asigna Tarea a Usuario
1. **Setup:** 
   - Admin en Teléfono (con sesión activa)
   - Usuario "Otro Usuario" en Laptop (con sesión activa)

2. **Acción:** Admin asigna tarea a "Otro Usuario"

3. **Resultado Esperado:**
   - ❌ NO aparece notificación en el Teléfono del admin
   - ✅ SÍ aparece notificación push en el Laptop del usuario
   - ✅ Contenido: "📋 Nueva tarea asignada: {título}"

---

### Escenario 2: Admin Confirma Tarea de Usuario
1. **Setup:**
   - Usuario completa tarea y envía a revisión
   - Admin revisa desde su Teléfono

2. **Acción:** Admin confirma la tarea

3. **Resultado Esperado:**
   - ❌ NO aparece notificación en el Teléfono del admin
   - ✅ SÍ aparece notificación push en el dispositivo del usuario
   - ✅ Contenido: "✅ Tarea aceptada: {título}"

---

### Escenario 3: Admin Rechaza Tarea de Usuario
1. **Acción:** Admin rechaza tarea con razón "Falta evidencia"

2. **Resultado Esperado:**
   - ❌ NO aparece notificación en el Teléfono del admin
   - ✅ SÍ aparece notificación push en el dispositivo del usuario
   - ✅ Contenido: "❌ Tarea rechazada: {título}\nMotivo: Falta evidencia"

---

### Escenario 4: Usuario Crea Tarea Personal
1. **Acción:** Usuario crea tarea personal para sí mismo

2. **Resultado Esperado:**
   - ✅ Notificación local programada 1 día antes de vencimiento
   - ✅ Notificación local programada al momento de vencimiento
   - ✅ Aparece en el MISMO dispositivo (correcto para tareas personales)

---

## 📊 Estado de Métodos en NotificationService

### ❌ Métodos Ya NO usados para acciones admin:
```dart
// Estos métodos existen pero YA NO se llaman desde admin actions
showTaskAssignedNotification()    // Solo push via Cloud Function
showTaskAcceptedNotification()    // Solo push via Cloud Function  
showTaskRejectedNotification()    // Solo push via Cloud Function
```

### ✅ Métodos ACTIVOS para tareas personales:
```dart
schedulePersonalTaskNotifications()        // ✅ ACTIVO
showPersonalTaskCompletedNotification()    // ✅ ACTIVO
cancelTaskNotifications()                  // ✅ ACTIVO
```

---

## 🔐 Configuración de Cloud Functions

### functions/index.js - Triggers Configurados

```javascript
// 1. Nueva tarea asignada
exports.sendTaskAssignedNotification = functions
  .region('us-central1')
  .firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const taskData = snap.data();
    const assignedTo = taskData.assignedTo;
    
    // Leer token FCM del usuario desde users/{userId}/fcmToken
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(assignedTo)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    
    // Enviar push al token
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '📋 Nueva tarea asignada',
        body: taskData.title,
      },
      data: { taskId: context.params.taskId }
    });
  });

// 2. Tarea confirmada
exports.sendTaskApprovedNotification = functions
  .region('us-central1')
  .firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    
    // Solo disparar si status cambió a 'confirmed'
    if (before.status !== 'confirmed' && after.status === 'confirmed') {
      const assignedTo = after.assignedTo;
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(assignedTo)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '✅ Tarea aceptada',
          body: `Tu tarea "${after.title}" fue confirmada`,
        },
        data: { taskId: context.params.taskId }
      });
    }
  });

// 3. Tarea rechazada
exports.sendTaskRejectedNotification = functions
  .region('us-central1')
  .firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    
    // Solo disparar si status cambió a 'rejected'
    if (before.status !== 'rejected' && after.status === 'rejected') {
      const assignedTo = after.assignedTo;
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(assignedTo)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '❌ Tarea rechazada',
          body: `"${after.title}"\nMotivo: ${after.rejectionReason || 'No especificado'}`,
        },
        data: { taskId: context.params.taskId }
      });
    }
  });
```

---

## ✅ Ventajas de la Nueva Arquitectura

### 1. **Correctitud**
- ✅ Notificaciones llegan al dispositivo correcto
- ✅ Admin NO recibe notificaciones de sus propias acciones

### 2. **Simplicidad**
- ✅ Solo un canal de notificación para acciones admin (push)
- ✅ Solo un canal para tareas personales (local)
- ✅ No hay duplicación ni confusión

### 3. **Escalabilidad**
- ✅ Cloud Functions escalan automáticamente
- ✅ No depende de que la app del admin esté abierta

### 4. **Confiabilidad**
- ✅ Cloud Functions tienen retry automático
- ✅ Notificaciones push funcionan incluso si app está cerrada

---

## 📱 Requisitos de Dispositivo

### Para Recibir Notificaciones Push:
1. ✅ Usuario debe tener FCM token guardado en Firestore (`users/{uid}/fcmToken`)
2. ✅ Token se guarda automáticamente al hacer login (ver `AuthService`)
3. ✅ Token se actualiza si cambia de dispositivo

### Para Notificaciones Locales (Tareas Personales):
1. ✅ Permisos de notificación habilitados en el dispositivo
2. ✅ `flutter_local_notifications` configurado (ya está)

---

## 🚀 Conclusión

El sistema de notificaciones ahora funciona correctamente:

- **Admin Actions** → Cloud Functions → Push Notifications → Dispositivo del usuario ✅
- **Personal Tasks** → Local Notifications → Mismo dispositivo ✅

**NO** se usan notificaciones locales para comunicación entre dispositivos diferentes.

---

**Autor:** GitHub Copilot  
**Revisión:** 31 de octubre de 2025

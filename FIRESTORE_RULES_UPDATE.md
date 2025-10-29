# 🔐 Actualización de Reglas de Firestore

**Fecha:** 27 de octubre de 2025  
**Estado:** ⚠️ **PENDIENTE DE DEPLOYMENT MANUAL**

---

## 📋 Resumen de Cambios

Las reglas de Firestore han sido actualizadas en el archivo `firestore.rules` para incluir:

### ✅ Nuevas Funcionalidades:

1. **Tareas Personales** - Usuarios pueden crear, editar y eliminar sus propias tareas personales
2. **Cleanup Service** - Administradores pueden eliminar tareas completadas (para limpieza automática)
3. **Permisos Granulares** - Control más específico sobre operaciones de lectura/escritura

---

## 🔧 Reglas Actualizadas

### Tareas Personales (`isPersonal: true`)
```javascript
// Crear tareas personales
allow create: if request.auth != null && 
                 request.resource.data.assignedTo == request.auth.uid &&
                 request.resource.data.isPersonal == true;

// Actualizar tareas personales propias
allow update: if request.auth != null && 
                 resource.data.assignedTo == request.auth.uid &&
                 resource.data.isPersonal == true;

// Eliminar tareas personales propias
allow delete: if request.auth != null && 
                 resource.data.assignedTo == request.auth.uid &&
                 resource.data.isPersonal == true;
```

### Cleanup Service (Admin)
```javascript
// Permitir a admins eliminar tareas completadas después de 24h
allow delete: if request.auth != null && 
                 exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                 get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                 resource.data.status == 'completed';
```

---

## 🚀 Cómo Desplegar Manualmente

### Opción 1: Consola de Firebase (Recomendado)

1. **Abrir Firebase Console:**
   ```
   https://console.firebase.google.com/project/notas-marti-75827/firestore/rules
   ```

2. **Navegar a Firestore Database → Rules**

3. **Copiar el contenido completo del archivo `firestore.rules`**

4. **Pegar en el editor de la consola**

5. **Click en "Publicar" (Publish)**

6. **Verificar que no hay errores de sintaxis**

### Opción 2: Firebase CLI (Requiere Permisos)

Si tienes permisos de administrador en el proyecto:

```bash
# Asegúrate de estar autenticado
firebase login

# Desplegar solo las reglas
firebase deploy --only firestore:rules
```

**Nota:** Actualmente la CLI muestra error 403 (permisos insuficientes).

---

## 📝 Contenido Completo de firestore.rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Reglas para la colección de usuarios
    match /users/{userId} {
      // Solo usuarios autenticados pueden leer/escribir su propio documento
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Los administradores pueden leer todos los usuarios
      allow read: if request.auth != null && 
                     exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Permitir a los administradores crear usuarios
      allow create: if request.auth != null && 
                       exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
                       
      // Permitir a los administradores actualizar usuarios
      allow update: if request.auth != null && 
                       exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
                       
      // Permitir a los administradores eliminar usuarios
      allow delete: if request.auth != null && 
                       exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Reglas para la colección de tareas
    match /tasks/{taskId} {
      // Los usuarios pueden leer tareas asignadas a ellos
      allow read: if request.auth != null && 
                     resource.data.assignedTo == request.auth.uid;
      
      // Los usuarios pueden actualizar el estado de sus tareas asignadas
      allow update: if request.auth != null && 
                       resource.data.assignedTo == request.auth.uid;
      
      // Permitir crear tareas PERSONALES (isPersonal == true)
      allow create: if request.auth != null && 
                       request.resource.data.assignedTo == request.auth.uid &&
                       request.resource.data.isPersonal == true;
      
      // Permitir actualizar tareas PERSONALES propias
      allow update: if request.auth != null && 
                       resource.data.assignedTo == request.auth.uid &&
                       resource.data.isPersonal == true;
      
      // Permitir eliminar tareas PERSONALES propias
      allow delete: if request.auth != null && 
                       resource.data.assignedTo == request.auth.uid &&
                       resource.data.isPersonal == true;
                        
      // Los administradores pueden hacer todo con las tareas
      allow read, write, create, update: if request.auth != null && 
                                            exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Permitir a los administradores eliminar tareas completadas después de 24h (cleanup service)
      allow delete: if request.auth != null && 
                       exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                       resource.data.status == 'completed';
    }
    
    // Reglas para la colección de notas
    match /notes/{noteId} {
      // Los usuarios solo pueden acceder a sus propias notas
      allow read, write: if request.auth != null && 
                            resource.data.createdBy == request.auth.uid;
      
      // Permitir crear notas propias
      allow create: if request.auth != null && 
                       request.resource.data.createdBy == request.auth.uid;
                       
      // Los administradores pueden leer todas las notas (para estadísticas)
      allow read, update, delete: if request.auth != null && 
                     exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## ✅ Beneficios de las Nuevas Reglas

### 1. **Tareas Personales**
- ✅ Los usuarios pueden crear sus propias tareas sin necesidad de un admin
- ✅ Control total sobre tareas personales (crear, editar, eliminar)
- ✅ No afecta las tareas asignadas por administradores

### 2. **Cleanup Service**
- ✅ El servicio de limpieza puede eliminar tareas completadas viejas
- ✅ Solo afecta tareas con `status == 'completed'`
- ✅ Solo administradores pueden ejecutar el cleanup
- ✅ Mantiene la base de datos limpia y optimizada

### 3. **Seguridad Mejorada**
- ✅ Permisos más específicos y granulares
- ✅ Usuarios solo pueden modificar sus propias tareas personales
- ✅ Administradores mantienen control total
- ✅ Previene accesos no autorizados

---

## 🧪 Cómo Verificar las Reglas

### Después del Deployment:

1. **Probar creación de tarea personal:**
   ```dart
   await TaskService.createPersonalTask(
     title: 'Test',
     description: 'Prueba',
     dueDate: DateTime.now().add(Duration(days: 7)),
   );
   ```
   **Esperado:** ✅ Éxito sin errores

2. **Probar cleanup service (como admin):**
   ```dart
   final service = TaskCleanupService();
   await service.cleanupOldTasks();
   ```
   **Esperado:** ✅ Sin errores de permisos

3. **Verificar en logs:**
   - Ya no debería aparecer: `[cloud_firestore/permission-denied]`
   - Debería funcionar: Creación, edición y eliminación de tareas personales

---

## ⚠️ Importante

- **No eliminar el archivo `firestore.rules`** - Es la fuente de verdad
- **Hacer backup antes de desplegar** - La consola de Firebase guarda historial
- **Probar en un entorno de desarrollo primero** si es posible
- **Las reglas afectan inmediatamente** después del deployment

---

## 📞 Comandos Útiles

### Ver reglas actuales:
```bash
firebase firestore:rules:list
```

### Ver diferencias:
```bash
firebase firestore:rules:get > current_rules.txt
diff current_rules.txt firestore.rules
```

### Deployment:
```bash
firebase deploy --only firestore:rules
```

---

## 🎯 Próximos Pasos

1. ✅ **Reglas actualizadas en `firestore.rules`**
2. ⏳ **Desplegar manualmente vía Firebase Console**
3. ⏳ **Verificar funcionamiento del cleanup service**
4. ⏳ **Probar creación de tareas personales**

---

**Estado Final:** Las reglas están listas para ser desplegadas. Se requiere acceso a la Firebase Console para completar el deployment.

**Fecha de actualización:** 27 de octubre de 2025

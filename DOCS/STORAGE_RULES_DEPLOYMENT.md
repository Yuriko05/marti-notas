# Guía de Despliegue de Reglas de Firebase Storage

## 📋 Resumen

Este documento explica cómo desplegar las reglas de seguridad de Firebase Storage configuradas en el archivo `storage.rules`.

---

## ✅ Archivos Configurados

1. **`storage.rules`** - Reglas de seguridad de Firebase Storage
2. **`firebase.json`** - Configuración actualizada para incluir Storage

---

## 🔒 Reglas Implementadas

### 1. Evidencia de Tareas (`task_evidence/{userId}/{fileName}`)

#### Permisos:

- **Lectura (READ):**
  - ✅ El propietario puede leer sus archivos
  - ✅ Los admins pueden leer cualquier archivo

- **Escritura (WRITE):**
  - ✅ Solo el propietario puede subir a su carpeta
  - ✅ Debe ser imagen o documento válido
  - ✅ Máximo 10MB por archivo

- **Eliminación (DELETE):**
  - ✅ El propietario puede eliminar sus archivos
  - ✅ Los admins pueden eliminar cualquier archivo

#### Formatos Permitidos:
- **Imágenes:** JPG, JPEG, PNG, GIF, BMP, WEBP
- **Documentos:** PDF, DOC, DOCX, XLS, XLSX, TXT

### 2. Imágenes de Perfil (`profile_pictures/{userId}/{fileName}`)
- **Lectura:** Todos los usuarios autenticados
- **Escritura:** Solo el propietario
- **Máximo:** 5MB
- **Tipo:** Solo imágenes

### 3. Archivos de Proyecto (`project_files/{projectId}/{fileName}`)
- **Lectura:** Todos los usuarios autenticados
- **Escritura:** Solo admins
- **Máximo:** 20MB

---

## 🚀 Métodos de Despliegue

### Opción 1: Usando Firebase CLI (RECOMENDADO)

#### Paso 1: Instalar Firebase CLI (si no lo tienes)

```powershell
npm install -g firebase-tools
```

#### Paso 2: Login en Firebase

```powershell
firebase login
```

Se abrirá tu navegador para autenticarte con tu cuenta de Google.

#### Paso 3: Verificar la configuración

```powershell
cd "D:\ejercicos de SENATI\marti-notas"
firebase projects:list
```

Verifica que `app-notas-3d555` esté en la lista.

#### Paso 4: Inicializar (si es primera vez)

```powershell
firebase init storage
```

Selecciona:
- Use existing project → `app-notas-3d555`
- What file should be used for Storage Rules? → `storage.rules` (ya existe)

#### Paso 5: Desplegar las reglas

```powershell
firebase deploy --only storage
```

Salida esperada:
```
✔ Deploy complete!
Project Console: https://console.firebase.google.com/project/app-notas-3d555/overview
```

#### Paso 6: Verificar en Firebase Console

1. Ve a: https://console.firebase.google.com/project/app-notas-3d555/storage/rules
2. Deberías ver las reglas desplegadas

---

### Opción 2: Desde Firebase Console (Manual)

#### Paso 1: Abrir Firebase Console

Ir a: https://console.firebase.google.com/project/app-notas-3d555/storage/rules

#### Paso 2: Copiar las reglas

Abre el archivo `storage.rules` y copia todo su contenido.

#### Paso 3: Pegar en el editor

1. Pega el contenido en el editor web
2. Clic en **"Publicar"**

#### Paso 4: Confirmar

Se te pedirá confirmar los cambios. Acepta.

---

## 🧪 Probar las Reglas (Opcional)

### Usando el Simulador de Reglas en Console:

1. Ve a: https://console.firebase.google.com/project/app-notas-3d555/storage/rules
2. Clic en **"Simulator"** (pestaña superior)

#### Prueba 1: Usuario sube su archivo

```
Operación: create
Ruta: /task_evidence/USER_ID_123/image_1234567890.jpg
Autenticado como: USER_ID_123 (simulado)
Content-Type: image/jpeg
Size: 5242880 (5MB)
```

**Resultado esperado:** ✅ Permitido

#### Prueba 2: Usuario intenta subir archivo muy grande

```
Operación: create
Ruta: /task_evidence/USER_ID_123/large_file.pdf
Autenticado como: USER_ID_123
Content-Type: application/pdf
Size: 15728640 (15MB)
```

**Resultado esperado:** ❌ Denegado (excede 10MB)

#### Prueba 3: Usuario intenta acceder a archivos de otro

```
Operación: get
Ruta: /task_evidence/USER_ID_456/document.pdf
Autenticado como: USER_ID_123
```

**Resultado esperado:** ❌ Denegado (no es el propietario ni admin)

#### Prueba 4: Admin accede a cualquier archivo

```
Operación: get
Ruta: /task_evidence/USER_ID_123/document.pdf
Autenticado como: ADMIN_USER_ID
Role en Firestore: admin
```

**Resultado esperado:** ✅ Permitido

---

## 🔍 Verificación Post-Despliegue

### 1. Verificar en Firebase Console

```
Storage → Rules → Deberías ver las reglas activas
```

### 2. Probar desde la App

1. **Como Usuario:**
   - Abre una tarea
   - Clic en "Completar Tarea"
   - Sube una imagen o archivo
   - Verifica que se suba correctamente

2. **Como Admin:**
   - Abre una tarea en revisión
   - Verifica que puedas ver las imágenes adjuntas
   - Intenta descargar archivos

### 3. Verificar Logs

Ve a: https://console.firebase.google.com/project/app-notas-3d555/storage/files

Busca archivos recién subidos en la carpeta `task_evidence/`.

---

## ⚠️ Problemas Comunes y Soluciones

### Problema 1: "Permission denied" al subir archivo

**Causa:** Las reglas no están desplegadas o hay un error de autenticación.

**Solución:**
1. Verifica que el usuario esté autenticado
2. Redespliega las reglas: `firebase deploy --only storage`
3. Verifica que el `userId` en la ruta coincida con `request.auth.uid`

### Problema 2: "File too large"

**Causa:** El archivo excede el límite de 10MB.

**Solución:**
- Comprime la imagen antes de subirla (ya implementado en `storage_service.dart`)
- Para documentos, pide al usuario que reduzca el tamaño

### Problema 3: "Invalid content type"

**Causa:** El tipo de archivo no está permitido.

**Solución:**
- Solo se permiten: imágenes (jpg, png, etc.) y documentos (pdf, doc, xls, txt)
- Verifica que el archivo sea de un tipo válido

### Problema 4: Admin no puede ver archivos de usuarios

**Causa:** La verificación `isAdmin()` falla.

**Solución:**
1. Verifica que el campo `role` existe en Firestore para el admin
2. Verifica las reglas de Firestore permiten leer el documento de usuario
3. El valor debe ser exactamente `'admin'` (minúsculas)

### Problema 5: "Firebase CLI not found"

**Causa:** Firebase CLI no está instalado o no está en el PATH.

**Solución:**
```powershell
npm install -g firebase-tools
```

Si sigue sin funcionar, cierra y abre PowerShell de nuevo.

---

## 📊 Monitoreo

### Ver Accesos Denegados:

1. Ve a: https://console.firebase.google.com/project/app-notas-3d555/storage/files
2. Clic en **"Usage"** (pestaña)
3. Revisa el gráfico de **"Failed Requests"**

### Alertas Recomendadas:

Configura alertas en Firebase para:
- 🔴 Alto número de accesos denegados
- 🟡 Archivos muy grandes subidos
- 🟢 Uso de almacenamiento cerca del límite

---

## 💰 Costos y Límites

### Plan Blaze:

**Gratuito hasta:**
- 5 GB de almacenamiento
- 1 GB/día de descarga
- 20,000 escrituras/día
- 50,000 lecturas/día

**Después del límite gratuito:**
- $0.026 por GB de almacenamiento/mes
- $0.12 por GB de descarga
- $0.05 por 10,000 escrituras
- $0.004 por 10,000 lecturas

**Estimado para uso normal:**
- ~100 usuarios con ~10 archivos c/u = ~1GB = **GRATIS**
- Uso moderado: **$0-2/mes**

---

## 🔐 Mejores Prácticas de Seguridad

### 1. Validar siempre en el servidor
- ✅ Las reglas de Storage son la primera línea de defensa
- ✅ Valida también en Flutter antes de subir (UX)
- ✅ Considera validación adicional en Cloud Functions

### 2. Limitar tamaños
- ✅ 10MB es suficiente para evidencia
- ✅ Comprime imágenes automáticamente
- ✅ Rechaza archivos muy grandes en la app

### 3. Estructura de carpetas clara
- ✅ Usa `{userId}` en la ruta para aislar archivos
- ✅ Nombra archivos con timestamp único
- ✅ Evita caracteres especiales en nombres

### 4. Auditoría
- ✅ Revisa logs periódicamente
- ✅ Monitorea accesos denegados
- ✅ Verifica que solo admins accedan a archivos de otros

### 5. Limpieza periódica
- ✅ Elimina archivos de tareas muy antiguas
- ✅ Implementa política de retención (ej: 6 meses)
- ✅ Usa Cloud Functions para limpieza automática

---

## 📝 Checklist de Despliegue

- [ ] Firebase CLI instalado y actualizado
- [ ] Login en Firebase (`firebase login`)
- [ ] Archivo `storage.rules` revisado y completo
- [ ] Archivo `firebase.json` actualizado
- [ ] Reglas desplegadas (`firebase deploy --only storage`)
- [ ] Verificación en Firebase Console
- [ ] Prueba de subida desde la app (usuario)
- [ ] Prueba de visualización (admin)
- [ ] Verificación de logs en Console
- [ ] Alertas configuradas (opcional)

---

## 🆘 Soporte

### Documentación Oficial:
- [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

### Comandos Útiles:

```powershell
# Ver proyectos
firebase projects:list

# Ver reglas actuales
firebase deploy --only storage --dry-run

# Desplegar todo (Storage + Firestore)
firebase deploy

# Ver logs
firebase functions:log
```

---

## ✅ Completado

Una vez desplegadas las reglas, tu sistema de Storage estará completamente seguro y funcional.

**Próximo paso:** Probar subiendo archivos desde la app.

---

**Fecha de configuración:** Enero 2024  
**Proyecto:** app-notas-3d555  
**Ubicación Storage:** gs://app-notas-3d555.firebasestorage.app

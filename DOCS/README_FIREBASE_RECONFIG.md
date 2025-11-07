# Reconfigurar este repo para otro proyecto Firebase (correoB)

Objetivo

Cambiar el proyecto Firebase al que apunta esta app Flutter (actualmente `notas-marti-75827`) para usar el proyecto B (correoB) — sin migrar datos del proyecto A.

Resumen rápido

- El archivo `lib/firebase_options.dart` contiene la configuración actual (API keys, projectId, appId, etc.).
- La forma más segura y sencilla es regenerar `lib/firebase_options.dart` usando FlutterFire CLI apuntando al projectId del proyecto B.
- Este documento contiene un script PowerShell de ayuda `scripts/reconfigure_firebase.ps1` y la guía manual.

Prerequisitos

- Tener instalado:
  - Flutter y Dart
  - FlutterFire CLI: `dart pub global activate flutterfire_cli`
  - Firebase CLI: `npm install -g firebase-tools` y haber ejecutado `firebase login`
- Tener acceso (permisos) al proyecto Firebase B (correoB) y que el proyecto tenga las apps registradas (o estar preparado para registrarlas durante `flutterfire configure`).

Opciones para reconfigurar

1) Regenerar `lib/firebase_options.dart` localmente (recomendado)

  a) Ejecuta el script (PowerShell) desde la raíz del repo:

  ```powershell
  .\scripts\reconfigure_firebase.ps1 -ProjectId "PROJECT_ID_B" -Platforms "android,ios,web"
  ```

  b) Esto lanzará `flutterfire configure` que te pedirá seleccionar/registrar apps en el proyecto B y generará `lib/firebase_options.dart` apuntando a B.

  c) Luego ejecuta:
  ```powershell
  flutter clean; flutter pub get; flutter run -d chrome
  ```

  Nota: `flutterfire configure` interactuará con la consola de Firebase (puede pedir crear apps iOS/Android/Web). Si no quieres crear apps, puedes generar el archivo web/solo plataformas que necesites.

2) Manual: crear apps en Firebase Console (proyecto B) y generar `firebase_options.dart` desde las credenciales de la consola

  a) Ve a Firebase Console → Project B → Project settings → Add app (Android/iOS/Web) y registra tu app. Descarga la configuración.
  b) Usa FlutterFire CLI o crea `lib/firebase_options.dart` manualmente con los valores de la consola.

3) Alternativa temporal (no recomendado para producción): mantener `lib/firebase_options.dart` y editar solo `projectId` y otros campos manualmente.

Consideraciones

- No subas claves ni credenciales privadas al repo.
- `lib/firebase_options.dart` contiene API keys públicas (no secretas) pero igual es buena práctica no versionarlas si compartes el repo.
- Si usas Cloud Functions en el proyecto B, asegúrate de:
  - Configurar `firebase-tools` con `firebase use --add <PROJECT_ID_B>`
  - Ejecutar `firebase deploy --project <PROJECT_ID_B> --only functions` desde la carpeta `functions/` del repo (si la hay).

Pasos posteriores

- Si tienes Cloud Functions que necesiten secretos (service accounts, keys), súbelos a Secret Manager en el proyecto B y actualiza las funciones para leerlos.
- Actualiza `firebase.json` si necesitas cambiar hosting targets.

Si quieres, puedo:
- Añadir el script (ya lo agregué) y probar una edición pequeña en el repo (no modifico `lib/firebase_options.dart` por seguridad).
- Generar un archivo `lib/firebase_options_projectB.dart` con placeholders para que lo completes manualmente.

Dime si quieres que ahora:
- 1) Intente reemplazar `lib/firebase_options.dart` por una versión con placeholders (no recomendable si vas a correr la app inmediatamente), o
- 2) Sólo deje los scripts y la guía (ya hecho), y te guíe para ejecutar el script localmente con `ProjectId` de B, o
- 3) Cree una segunda configuración `lib/firebase_options_projectB.dart` y un pequeño loader que seleccione cuál usar mediante una variable (útil si quieres poder alternar entre A y B desde el código).
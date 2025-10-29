Seguridad y manejo de credenciales

Resumen rápido:
- No subir archivos con credenciales (service accounts, google-services.json, Firebase config) al repositorio.
- El proyecto contiene `backend-notificaciones/firebase-service.json` (service account) y `lib/firebase_options.dart` (contiene API keys públicas).

Acciones recomendadas:
1. Rotar la clave privada del service account inmediatamente desde la consola de Google Cloud si este repo es público o compartido.
2. Mover `backend-notificaciones/firebase-service.json` fuera del repositorio y cargarlo en el servidor con un gestor de secretos (GitHub Secrets, Azure Key Vault, GCP Secret Manager o variables de entorno).
3. Reemplazar `lib/firebase_options.dart` por lectura desde variables de entorno o usar archivos de configuración por entorno que no se suban al repo (si necesitas esconder los apiKey).
4. Añadir las entradas apropiadas en `.gitignore` (ya añadidas) y eliminar del historial con `git rm --cached` si ya fueron commiteadas:
   - git rm --cached backend-notificaciones/firebase-service.json
   - git rm --cached lib/firebase_options.dart  # si decides no versionarlo
   - Luego: git commit -m "Remove credentials from repo" y rotar claves.

Mejoras a largo plazo:
- Usar GCP Secret Manager / AWS Secrets Manager / Azure Key Vault.
- Utilizar CI/CD con variables de entorno y no guardar secretos en el código.
- Revisar el historial de Git (BFG Repo-Cleaner) si las claves estuvieron expuestas públicamente.

Contacto:
Si quieres, puedo generar un script PowerShell para automatizar la eliminación del archivo del índice y un checklist para rotar la clave en Google Cloud.

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/logger.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Subir imagen desde la cámara o galería
  static Future<String?> uploadImage({
    required ImageSource source,
    required String taskId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('Usuario no autenticado', name: 'StorageService');
        return null;
      }

      // Seleccionar imagen
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        AppLogger.info('Selección de imagen cancelada', name: 'StorageService');
        return null;
      }

      // Crear nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'task_$taskId\_$timestamp.jpg';
      final path = 'task_evidence/${user.uid}/$fileName';

      // Subir archivo (compatible con Web y móvil)
      final ref = _storage.ref().child(path);
      
      AppLogger.info('Subiendo imagen: $path', name: 'StorageService');
      
      // En Web, usamos readAsBytes() en lugar de File
      final Uint8List imageData = await image.readAsBytes();
      
      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'taskId': taskId,
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': image.name,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.success('Imagen subida exitosamente: $downloadUrl',
          name: 'StorageService');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Error subiendo imagen', error: e, name: 'StorageService');
      return null;
    }
  }

  /// Subir archivo (PDF, DOC, etc.)
  static Future<String?> uploadFile({
    required String taskId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('Usuario no autenticado', name: 'StorageService');
        throw Exception('Usuario no autenticado');
      }

      // Seleccionar archivo - Permitir todos los tipos comunes de archivos
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Cambiado a FileType.any para permitir más tipos
        allowMultiple: false,
        withData: true, // Importante: fuerza cargar los bytes
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.info('Selección de archivo cancelada',
            name: 'StorageService');
        return null; // Usuario canceló, no es un error
      }

      final platformFile = result.files.first;

      // Validar tamaño (máximo 10MB)
      if (platformFile.size > 10 * 1024 * 1024) {
        AppLogger.warning('Archivo demasiado grande: ${(platformFile.size / 1024 / 1024).toStringAsFixed(2)} MB (máx 10MB)',
            name: 'StorageService');
        throw Exception('El archivo es demasiado grande. Máximo permitido: 10MB');
      }

      // Validar que tengamos los bytes del archivo
      if (platformFile.bytes == null) {
        AppLogger.error('No se pudieron leer los bytes del archivo: ${platformFile.name}',
            name: 'StorageService');
        throw Exception('No se pudo leer el archivo. Intenta con otro archivo.');
      }

      // Obtener extensión del archivo
      String extension = platformFile.extension ?? 'bin';
      
      // Validar tipos de archivo permitidos
      final allowedExtensions = [
        'pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
        'zip', 'rar', '7z',
        'mp4', 'mov', 'avi',
        'csv', 'json', 'xml'
      ];
      
      if (!allowedExtensions.contains(extension.toLowerCase())) {
        AppLogger.warning('Tipo de archivo no permitido: .$extension',
            name: 'StorageService');
        throw Exception('Tipo de archivo no permitido: .$extension');
      }

      // Crear nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = platformFile.name.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      final fileName = 'task_${taskId}_${timestamp}_$sanitizedName';
      final path = 'task_evidence/${user.uid}/$fileName';

      // Subir archivo (compatible con Web y móvil)
      final ref = _storage.ref().child(path);

      AppLogger.info('Subiendo archivo: ${platformFile.name} (${(platformFile.size / 1024).toStringAsFixed(1)} KB)',
          name: 'StorageService');

      final uploadTask = ref.putData(
        platformFile.bytes!,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'taskId': taskId,
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': platformFile.name,
            'fileSize': platformFile.size.toString(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.success('Archivo subido: ${platformFile.name}',
          name: 'StorageService');
      return downloadUrl;
    } on FirebaseException catch (e) {
      AppLogger.error('Error Firebase: ${e.code} - ${e.message}',
          error: e, name: 'StorageService');
      if (e.code == 'unauthorized') {
        throw Exception('No tienes permisos para subir archivos');
      }
      throw Exception('Error al subir: ${e.message}');
    } catch (e) {
      AppLogger.error('Error subiendo archivo', error: e, name: 'StorageService');
      // Re-lanzar excepciones personalizadas
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error inesperado al subir archivo');
    }
  }

  /// Subir múltiples archivos
  static Future<List<Map<String, String>>> uploadMultipleFiles({
    required String taskId,
    int maxFiles = 5,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Seleccionar múltiples archivos
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final uploadedFiles = <Map<String, String>>[];
      final filesToUpload = result.files.take(maxFiles).toList();

      for (final platformFile in filesToUpload) {
        // Validar tamaño
        if (platformFile.size > 10 * 1024 * 1024) continue;

        // Validar que tengamos los bytes
        if (platformFile.bytes == null) continue;

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = platformFile.extension ?? 'bin';
        final fileName = 'task_${taskId}_${timestamp}_${platformFile.name}';
        final path = 'task_evidence/${user.uid}/$fileName';

        try {
          final ref = _storage.ref().child(path);

          final uploadTask = ref.putData(
            platformFile.bytes!,
            SettableMetadata(
              contentType: _getContentType(extension),
              customMetadata: {
                'taskId': taskId,
                'userId': user.uid,
                'uploadedAt': DateTime.now().toIso8601String(),
                'originalName': platformFile.name,
              },
            ),
          );

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          uploadedFiles.add({
            'url': downloadUrl,
            'name': platformFile.name,
            'type': extension,
            'size': '${(platformFile.size / 1024).toStringAsFixed(1)} KB',
          });
        } catch (e) {
          AppLogger.error('Error subiendo ${platformFile.name}',
              error: e, name: 'StorageService');
        }
      }

      return uploadedFiles;
    } catch (e) {
      AppLogger.error('Error subiendo múltiples archivos',
          error: e, name: 'StorageService');
      return [];
    }
  }

  /// Eliminar archivo
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      AppLogger.success('Archivo eliminado exitosamente',
          name: 'StorageService');
      return true;
    } catch (e) {
      AppLogger.error('Error eliminando archivo',
          error: e, name: 'StorageService');
      return false;
    }
  }

  /// Obtener tipo de contenido según extensión
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      // Documentos
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      
      // Hojas de cálculo
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      
      // Presentaciones
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      // Texto
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      
      // Imágenes
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      
      // Comprimidos
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      
      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      
      default:
        return 'application/octet-stream';
    }
  }

  /// Obtener tamaño de archivo formateado
  static String getFormattedFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

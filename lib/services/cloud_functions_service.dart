import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Servicio para llamar a Cloud Functions
class CloudFunctionsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Crear un usuario usando Cloud Function (no cierra sesión del admin)
  /// 
  /// Parámetros:
  /// - [name]: Nombre del usuario
  /// - [password]: Contraseña del usuario
  /// - [role]: Rol del usuario ('normal' o 'admin')
  /// 
  /// Retorna:
  /// - [Map<String, dynamic>] con los datos del usuario creado
  /// - [null] si hay un error
  static Future<Map<String, dynamic>?> createUser({
    required String name,
    required String password,
    required String role,
  }) async {
    try {
      debugPrint('🔥 CloudFunctions: Llamando a createUser...');
      debugPrint('   - Nombre: $name');
      debugPrint('   - Rol: $role');

      // Llamar a la Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('createUser');
      
      final response = await callable.call<Map<dynamic, dynamic>>({
        'name': name,
        'password': password,
        'role': role,
      });

      final data = Map<String, dynamic>.from(response.data);
      
      debugPrint('✅ CloudFunctions: Usuario creado exitosamente');
      debugPrint('   - UID: ${data['uid']}');
      debugPrint('   - Email: ${data['email']}');
      debugPrint('   - Nombre: ${data['name']}');

      return data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ CloudFunctions: Error - ${e.code}');
      debugPrint('   Mensaje: ${e.message}');
      debugPrint('   Detalles: ${e.details}');
      
      // Retornar error con información útil
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Error desconocido',
      };
    } catch (e) {
      debugPrint('❌ CloudFunctions: Error inesperado: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': e.toString(),
      };
    }
  }
}

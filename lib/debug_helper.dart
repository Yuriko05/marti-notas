import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DebugHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Función para diagnosticar problemas de login
  static Future<void> diagnoseProblem() async {
    debugPrint('\n🔍 ===== DIAGNÓSTICO DE LOGIN =====');

    try {
      // 1. Verificar conexión con Firebase
      debugPrint('1️⃣ Verificando conexión con Firebase Auth...');
      final User? currentUser = _auth.currentUser;
      debugPrint('   Usuario actual: ${currentUser?.email ?? 'ninguno'}');

      // 2. Verificar conexión con Firestore
      debugPrint('2️⃣ Verificando conexión con Firestore...');

      // 3. Probar generación de email fake PRIMERO
      debugPrint('3️⃣ Probando generación de emails fake...');
      final testNames = ['lucas', 'admin', 'test', 'usuario'];

      for (String name in testNames) {
        final fakeEmail = _generateFakeEmail(name);
        debugPrint('   $name -> $fakeEmail');

        // Verificar si existe en Firebase Auth
        try {
          final methods = await _auth.fetchSignInMethodsForEmail(fakeEmail);
          if (methods.isNotEmpty) {
            debugPrint('     ✅ Existe en Firebase Auth: ${methods.join(', ')}');
          } else {
            debugPrint('     ❌ NO existe en Firebase Auth');
          }
        } catch (e) {
          debugPrint('     ⚠️ Error verificando existencia: $e');
        }
      }

      // 4. Intentar listar usuarios (solo si hay un admin autenticado)
      debugPrint('4️⃣ Estado de autenticación...');
      if (currentUser != null) {
        debugPrint('   ✅ Usuario autenticado detectado');
        debugPrint('   UID: ${currentUser.uid}');
        debugPrint('   Email: ${currentUser.email}');

        try {
          debugPrint('   Intentando listar usuarios en Firestore...');
          final QuerySnapshot usersQuery =
              await _firestore.collection('users').limit(10).get();

          debugPrint(
              '   Total de usuarios encontrados: ${usersQuery.docs.length}');

          if (usersQuery.docs.isEmpty) {
            debugPrint('   ⚠️ No hay usuarios en Firestore');
            debugPrint(
                '   Esto significa que necesitas crear usuarios primero');
          } else {
            debugPrint('   📋 Lista de usuarios:');
            for (var doc in usersQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              debugPrint('   - ID: ${doc.id}');
              debugPrint('     Nombre: ${data['name'] ?? 'N/A'}');
              debugPrint('     Email: ${data['email'] ?? 'N/A'}');
              debugPrint('     Rol: ${data['role'] ?? 'N/A'}');
              debugPrint('   ---');
            }
          }
        } catch (e) {
          debugPrint('   ❌ Error listando usuarios: $e');
          debugPrint('   Posible problema de permisos de Firestore');
        }
      } else {
        debugPrint('   ❌ No hay usuario autenticado');
        debugPrint('   No se pueden listar usuarios sin autenticación');
      }

      // 5. Probar un login de ejemplo
      debugPrint('5️⃣ Información adicional...');
      debugPrint('   Firebase Project: ${_auth.app.name}');
      debugPrint('   Firestore collection: users');
      debugPrint('   Dominio fake usado: @app.local');
    } catch (e) {
      debugPrint('❌ Error en diagnóstico: $e');
    }

    debugPrint('🔍 ===== FIN DEL DIAGNÓSTICO =====\n');

    // Mostrar sugerencias
    debugPrint('💡 SUGERENCIAS:');
    debugPrint('   1. Si no hay usuarios, crea uno usando el panel de debug');
    debugPrint(
        '   2. Si hay usuarios, verifica que el nombre coincida exactamente');
    debugPrint('   3. Recuerda que los nombres se convierten a minúsculas');
    debugPrint('   4. Ejemplo: "Lucas" se convierte en "lucas@app.local"');
    debugPrint('');
  }

  /// Generar correo fake basado en el nombre del usuario
  static String _generateFakeEmail(String name) {
    // Limpiar el nombre: minúsculas, sin espacios, caracteres especiales
    String cleanName = name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return '${cleanName}@app.local';
  }

  /// Crear un usuario de prueba
  static Future<void> createTestUser({
    required String name,
    required String password,
    String role = 'admin',
  }) async {
    try {
      debugPrint('\n🧪 ===== CREANDO USUARIO DE PRUEBA =====');
      debugPrint('Nombre: $name');
      debugPrint('Contraseña: $password');
      debugPrint('Rol: $role');

      final String fakeEmail = _generateFakeEmail(name);
      debugPrint('Email fake: $fakeEmail');

      // 0. Verificar si ya existe
      try {
        final existingMethods =
            await _auth.fetchSignInMethodsForEmail(fakeEmail);
        if (existingMethods.isNotEmpty) {
          debugPrint('⚠️ El usuario ya existe en Firebase Auth');
          debugPrint('   Métodos disponibles: ${existingMethods.join(', ')}');
          return;
        }
      } catch (e) {
        debugPrint('🔍 Verificando existencia previa: $e');
      }

      // 1. Crear en Firebase Authentication
      debugPrint('📝 Creando en Firebase Authentication...');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      final User? firebaseUser = result.user;
      if (firebaseUser == null) {
        debugPrint('❌ Error: No se pudo crear el usuario en Firebase Auth');
        return;
      }

      debugPrint('✅ Usuario creado en Firebase Auth: ${firebaseUser.uid}');
      debugPrint('   Email verificado: ${firebaseUser.email}');

      // 2. Guardar en Firestore
      debugPrint('💾 Guardando en Firestore...');
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'email': fakeEmail,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Usuario guardado en Firestore');

      // 3. Verificar que se creó correctamente
      debugPrint('🔍 Verificando creación en Firebase Auth...');
      try {
        final verifyMethods = await _auth.fetchSignInMethodsForEmail(fakeEmail);
        debugPrint(
            '   Métodos después de creación: ${verifyMethods.join(', ')}');

        if (verifyMethods.isEmpty) {
          debugPrint(
              '⚠️ ADVERTENCIA: El usuario no aparece inmediatamente en Firebase Auth');
          debugPrint('   Esto puede ser un problema de sincronización');
        }
      } catch (e) {
        debugPrint('⚠️ Error verificando usuario recién creado: $e');
      }

      // 4. Cerrar sesión del usuario recién creado
      await _auth.signOut();
      debugPrint('✅ Sesión cerrada del usuario recién creado');

      debugPrint('🎉 Usuario de prueba creado exitosamente!');
      debugPrint('   Datos para login: $name / $password');
      debugPrint('   Email en Firebase: $fakeEmail');
      debugPrint('🔍 ===== FIN DE CREACIÓN =====\n');
    } catch (e) {
      debugPrint('❌ Error creando usuario de prueba: $e');
      if (e.toString().contains('email-already-in-use')) {
        debugPrint('   El email ya está en uso. Intenta con otro nombre.');
      }
    }
  }

  /// Función específica para diagnosticar un usuario particular
  static Future<void> diagnoseSpecificUser(String userName) async {
    debugPrint('\n🔎 ===== DIAGNÓSTICO ESPECÍFICO: $userName =====');

    try {
      final String fakeEmail = _generateFakeEmail(userName);
      debugPrint('📧 Email fake esperado: $fakeEmail');

      // 1. Verificar en Firebase Authentication
      debugPrint('1️⃣ Verificando en Firebase Authentication...');
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(fakeEmail);
        if (methods.isEmpty) {
          debugPrint('   ❌ NO existe en Firebase Authentication');
        } else {
          debugPrint('   ✅ SÍ existe en Firebase Authentication');
          debugPrint('   Métodos: ${methods.join(', ')}');
        }
      } catch (e) {
        debugPrint('   ⚠️ Error verificando en Firebase Auth: $e');
      }

      // 2. Verificar en Firestore (solo si hay usuario autenticado)
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('2️⃣ Verificando en Firestore...');
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('name', isEqualTo: userName)
              .get();

          if (querySnapshot.docs.isEmpty) {
            debugPrint('   ❌ NO existe en Firestore');
          } else {
            debugPrint('   ✅ SÍ existe en Firestore');
            for (var doc in querySnapshot.docs) {
              final data = doc.data();
              debugPrint('   - ID: ${doc.id}');
              debugPrint('   - Nombre: ${data['name']}');
              debugPrint('   - Email: ${data['email']}');
              debugPrint('   - Rol: ${data['role']}');
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ Error verificando en Firestore: $e');
        }
      } else {
        debugPrint(
            '2️⃣ No se puede verificar Firestore (usuario no autenticado)');
      }
    } catch (e) {
      debugPrint('❌ Error en diagnóstico específico: $e');
    }

    debugPrint('🔎 ===== FIN DIAGNÓSTICO ESPECÍFICO =====\n');
  }

  /// Función para intentar "recrear" un usuario que ya existe en Firestore
  /// pero no aparece en Firebase Auth
  static Future<void> fixUserSync({
    required String name,
    required String password,
    String role = 'normal',
  }) async {
    debugPrint('\n🔧 ===== INTENTANDO REPARAR SINCRONIZACIÓN =====');
    debugPrint('Usuario: $name');

    try {
      final String fakeEmail = _generateFakeEmail(name);
      debugPrint('Email fake: $fakeEmail');

      // 1. Primero verificar estado actual
      final methods = await _auth.fetchSignInMethodsForEmail(fakeEmail);
      debugPrint(
          'Estado actual en Firebase Auth: ${methods.isEmpty ? 'NO EXISTE' : 'EXISTE'}');

      if (methods.isEmpty) {
        debugPrint('🔄 El usuario no existe en Firebase Auth. Creando...');

        // 2. Crear en Firebase Authentication
        final UserCredential result =
            await _auth.createUserWithEmailAndPassword(
          email: fakeEmail,
          password: password,
        );

        final User? firebaseUser = result.user;
        if (firebaseUser == null) {
          debugPrint('❌ Error: No se pudo crear el usuario en Firebase Auth');
          return;
        }

        debugPrint('✅ Usuario recreado en Firebase Auth: ${firebaseUser.uid}');

        // 3. Actualizar o crear en Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set(
            {
              'email': fakeEmail,
              'name': name,
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            },
            SetOptions(
                merge:
                    true)); // merge: true para no sobrescribir datos existentes

        debugPrint('✅ Datos sincronizados en Firestore');

        // 4. Cerrar sesión
        await _auth.signOut();
        debugPrint('✅ Sesión cerrada');

        // 5. Verificar que ahora funciona
        debugPrint('🔍 Verificando reparación...');
        final verifyMethods = await _auth.fetchSignInMethodsForEmail(fakeEmail);
        debugPrint(
            'Estado después de reparación: ${verifyMethods.isEmpty ? 'AÚN NO EXISTE' : 'REPARADO'}');

        if (verifyMethods.isNotEmpty) {
          debugPrint('🎉 ¡Usuario reparado! Ahora debería poder hacer login');
        } else {
          debugPrint(
              '⚠️ El usuario sigue sin aparecer. Puede ser un problema de Firebase');
        }
      } else {
        debugPrint('✅ El usuario ya existe en Firebase Auth');
        debugPrint('   Métodos disponibles: ${methods.join(', ')}');
        debugPrint('   No necesita reparación');
      }
    } catch (e) {
      debugPrint('❌ Error durante la reparación: $e');
    }

    debugPrint('🔧 ===== FIN DE REPARACIÓN =====\n');
  }
}

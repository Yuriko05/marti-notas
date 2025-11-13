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

        // Verificar si existe en Firestore (más confiable que Auth)
        try {
          final userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: fakeEmail)
              .limit(1)
              .get();
          
          if (userQuery.docs.isNotEmpty) {
            final userData = userQuery.docs.first.data();
            debugPrint('     ✅ Existe en Firestore - Rol: ${userData['role']}');
          } else {
            debugPrint('     ❌ NO existe en Firestore');
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

    return '$cleanName@app.local';
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

      // 0. Verificar si ya existe en Firestore
      try {
        final existingQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: fakeEmail)
            .limit(1)
            .get();
        
        if (existingQuery.docs.isNotEmpty) {
          debugPrint('⚠️ El usuario ya existe en Firestore');
          final userData = existingQuery.docs.first.data();
          debugPrint('   Rol: ${userData['role']}');
          debugPrint('   Nombre: ${userData['name']}');
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

      // 3. Verificar que se creó correctamente en Firestore
      debugPrint('🔍 Verificando creación en Firestore...');
      try {
        final verifyDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (verifyDoc.exists) {
          final data = verifyDoc.data();
          debugPrint('   ✅ Usuario encontrado en Firestore');
          debugPrint('   Nombre: ${data?['name']}');
          debugPrint('   Rol: ${data?['role']}');
        } else {
          debugPrint('   ⚠️ ADVERTENCIA: El usuario no aparece en Firestore');
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

      // 1. Verificar en Firebase Authentication (intentar login)
      debugPrint('1️⃣ Verificando en Firebase Authentication...');
      try {
        // Intentar buscar el usuario en Firestore por email
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: fakeEmail)
            .limit(1)
            .get();
        
        if (userQuery.docs.isEmpty) {
          debugPrint('   ❌ NO existe en base de datos');
        } else {
          debugPrint('   ✅ SÍ existe en base de datos');
          final userData = userQuery.docs.first.data();
          debugPrint('   Email: ${userData['email']}');
          debugPrint('   Rol: ${userData['role']}');
        }
      } catch (e) {
        debugPrint('   ⚠️ Error verificando en base de datos: $e');
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

      // 1. Primero verificar estado actual en Firestore
      final existingQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: fakeEmail)
          .limit(1)
          .get();
      
      final userExists = existingQuery.docs.isNotEmpty;
      debugPrint('Estado actual en base de datos: ${userExists ? 'EXISTE' : 'NO EXISTE'}');

      if (!userExists) {
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
        final verifyQuery = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (verifyQuery.exists) {
          debugPrint('Estado después de reparación: REPARADO');
          debugPrint('🎉 ¡Usuario reparado! Ahora debería poder hacer login');
        } else {
          debugPrint('Estado después de reparación: AÚN TIENE PROBLEMAS');
          debugPrint('⚠️ El usuario sigue sin aparecer. Puede ser un problema de Firebase');
        }
      } else {
        debugPrint('✅ El usuario ya existe en la base de datos');
        final userData = existingQuery.docs.first.data();
        debugPrint('   Rol: ${userData['role']}');
        debugPrint('   No necesita reparación');
      }
    } catch (e) {
      debugPrint('❌ Error durante la reparación: $e');
    }

    debugPrint('🔧 ===== FIN DE REPARACIÓN =====\n');
  }
}

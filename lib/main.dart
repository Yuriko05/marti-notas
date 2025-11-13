import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:marti_notas/firebase_options.dart';
import 'package:marti_notas/screens/home_screen.dart';
import 'package:marti_notas/screens/login_screen.dart';
import 'package:marti_notas/services/auth/session_manager.dart';
import 'package:marti_notas/services/notification_service.dart';
import 'package:marti_notas/models/user_model.dart';
import 'package:marti_notas/providers/auth_provider.dart' as app_providers;
import 'package:marti_notas/providers/task_provider.dart';
import 'package:marti_notas/providers/note_provider.dart';
import 'package:marti_notas/theme/app_theme.dart';
import 'package:marti_notas/widgets/loading_widgets.dart';

/// Handler global para notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📥 Mensaje en segundo plano: ${message.messageId}');
  await NotificationService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ⚠️ CRITICAL: Registrar el handler de background ANTES de runApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar notificaciones
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configurar Providers para toda la aplicación
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_providers.AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: MaterialApp(
        title: 'Gestor de Tareas - Marti',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: StreamBuilder<User?>(
          stream: SessionManager().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingIndicator(
                message: 'Iniciando aplicación...',
              );
            }
            if (snapshot.hasData) {
              // Si el usuario está autenticado, obtener sus datos y navegar según rol
              return FutureBuilder<UserModel?>(
                future: SessionManager().getCurrentUserProfile(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(
                      message: 'Cargando perfil...',
                    );
                  }

                  final UserModel? user = userSnapshot.data;
                  if (user == null) {
                    // Si hay error obteniendo el usuario, cerrar sesión
                    SessionManager().signOut();
                    return const LoginScreen();
                  }

                  // Configurar notificaciones locales para el usuario
                  // Esto incluye verificar tareas nuevas al iniciar sesión
                  NotificationService.setupLoginNotifications();

                  // Navegar a la pantalla correspondiente según el rol
                  return HomeScreen(user: user);
                },
              );
            }
            // Si el usuario NO está autenticado, muestra la pantalla de login
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

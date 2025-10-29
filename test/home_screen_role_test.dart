import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marti_notas/screens/home_screen.dart';
import 'package:marti_notas/models/user_model.dart';

void main() {
  testWidgets('HomeScreen shows admin view for admin user',
      (WidgetTester tester) async {
    final admin = UserModel(
      uid: '1',
      email: 'admin@example.com',
      name: 'Admin',
      role: 'admin',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: admin),
      ),
    );

    // Allow animations to settle
    await tester.pumpAndSettle();

    // Admin view contains the admin menu tile text
    expect(find.text('Gestión de Usuarios'), findsOneWidget);
  });

  testWidgets('HomeScreen shows user view for normal user',
      (WidgetTester tester) async {
    final user = UserModel(
      uid: '2',
      email: 'user@example.com',
      name: 'User',
      role: 'normal',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: user),
      ),
    );

    await tester.pumpAndSettle();

    // User view contains 'Mis Tareas' tile
    expect(find.text('Mis Tareas'), findsWidgets);
  });
}

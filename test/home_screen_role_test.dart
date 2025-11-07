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
      username: 'admin',
      hasPassword: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: admin,
          adminViewBuilder: (_) => const Text('Vista Admin'),
          userViewBuilder: (_) => const Text('Vista Usuario'),
        ),
      ),
    );

    // Allow animations to settle
    await tester.pumpAndSettle();

    expect(find.text('Vista Admin'), findsOneWidget);
  });

  testWidgets('HomeScreen shows user view for normal user',
      (WidgetTester tester) async {
    final user = UserModel(
      uid: '2',
      email: 'user@example.com',
      name: 'User',
      role: 'normal',
      username: 'user',
      hasPassword: false,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: user,
          adminViewBuilder: (_) => const Text('Vista Admin'),
          userViewBuilder: (_) => const Text('Vista Usuario'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vista Usuario'), findsOneWidget);
  });
}

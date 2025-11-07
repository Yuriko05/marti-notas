import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marti_notas/models/user_model.dart';
import 'package:marti_notas/services/auth/user_repository.dart';

void main() {
  group('UserRepository', () {
    late FakeFirebaseFirestore firestore;
    late UserRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = UserRepository(firestore: firestore);
    });

    test('createUserProfile normalizes username and persists data', () async {
      final user = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'normal',
        username: 'ignored',
        hasPassword: true,
        createdAt: DateTime(2025, 1, 1),
      );

      await repository.createUserProfile(user);

      final snapshot = await firestore.collection('users').doc('user-1').get();
      final data = snapshot.data()!;

      expect(data['email'], equals('test@example.com'));
  expect(data['username'], equals('juanperez'));
      expect(data.containsKey('password'), isFalse);
    });

    test('updateUserProfile updates name and role when provided', () async {
      await firestore.collection('users').doc('user-2').set({
        'email': 'a@example.com',
        'name': 'Ana',
        'role': 'normal',
        'username': 'ana',
        'createdAt': DateTime(2025, 1, 1),
      });

      final result = await repository.updateUserProfile(
        userId: 'user-2',
        name: 'Ana María',
        role: 'admin',
      );

      final updated =
          await firestore.collection('users').doc('user-2').get();
      final data = updated.data()!;

      expect(result, isTrue);
      expect(data['name'], equals('Ana María'));
      expect(data['role'], equals('admin'));
    });

    test('updateLastLogin writes server timestamp', () async {
      await firestore.collection('users').doc('user-3').set({
        'email': 'b@example.com',
        'name': 'Bruno',
        'role': 'normal',
        'username': 'bruno',
        'createdAt': DateTime(2025, 1, 1),
      });

      await repository.updateLastLogin('user-3');

      final updated =
          await firestore.collection('users').doc('user-3').get();
      final data = updated.data()!;

      expect(data['lastLogin'], isA<Timestamp>());
    });

    test('findUserByName uses normalized username before legacy fallback',
        () async {
      await firestore.collection('users').doc('user-4').set({
        'email': 'c@example.com',
        'name': 'María José',
        'role': 'normal',
        'username': 'mariajose',
        'createdAt': DateTime(2025, 1, 1),
      });

      final result = await repository.findUserByName(' María   José ');

      expect(result, isNotNull);
      expect(result!.uid, equals('user-4'));
      expect(result.username, equals('mariajose'));
    });

    test('getAllUsers returns every stored document', () async {
      await firestore.collection('users').doc('user-5').set({
        'email': 'd@example.com',
        'name': 'Diego',
        'role': 'normal',
        'username': 'diego',
        'createdAt': DateTime(2025, 1, 1),
      });

      await firestore.collection('users').doc('user-6').set({
        'email': 'e@example.com',
        'name': 'Elena',
        'role': 'admin',
        'username': 'elena',
        'createdAt': DateTime(2025, 1, 1),
      });

      final users = await repository.getAllUsers();

      expect(users, hasLength(2));
      expect(users.any((user) => user.uid == 'user-6'), isTrue);
    });

    test('isUserAdmin returns true only for admin role', () async {
      await firestore.collection('users').doc('admin-1').set({
        'email': 'admin@example.com',
        'name': 'Admin',
        'role': 'admin',
        'username': 'admin',
        'createdAt': DateTime(2025, 1, 1),
      });

      final isAdmin = await repository.isUserAdmin('admin-1');
      final isNotAdmin = await repository.isUserAdmin('unknown');

      expect(isAdmin, isTrue);
      expect(isNotAdmin, isFalse);
    });
  });
}

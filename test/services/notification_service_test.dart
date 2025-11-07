import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:marti_notas/services/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  tearDown(() {
    NotificationService.resetTestOverrides();
  });

  group('NotificationService token management', () {
    late MockFirebaseMessaging messaging;
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late MockUser user;
    late StreamController<String> tokenRefreshController;

    setUp(() {
      messaging = MockFirebaseMessaging();
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
      user = MockUser();
      tokenRefreshController = StreamController<String>.broadcast();

      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('user-123');
      when(() => messaging.getToken()).thenAnswer((_) async => 'token-abc');
      when(() => messaging.onTokenRefresh)
          .thenAnswer((_) => tokenRefreshController.stream);
      when(() => messaging.deleteToken()).thenAnswer((_) async {});

      NotificationService.setTestOverrides(
        messaging: messaging,
        firestore: firestore,
        auth: auth,
      );
    });

    tearDown(() async {
      await tokenRefreshController.close();
    });

    test('registerCurrentDeviceToken stores token and listens for refreshes',
        () async {
      await NotificationService.registerCurrentDeviceToken();

      final snapshot =
          await firestore.collection('users').doc('user-123').get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['fcmTokens'], equals(['token-abc']));
      expect(data['fcmTokensUpdatedAt'], isNotNull);
      expect(tokenRefreshController.hasListener, isTrue);

      // Emit token refresh and ensure we persist it again
      when(() => auth.currentUser).thenReturn(user);
      tokenRefreshController.add('token-new');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final refreshedSnapshot =
          await firestore.collection('users').doc('user-123').get();
      final refreshedTokens =
          List<String>.from(refreshedSnapshot.data()?['fcmTokens'] ?? []);
      expect(refreshedTokens, containsAll(['token-abc', 'token-new']));
    });

    test('removeCurrentDeviceToken removes token and deletes local instance',
        () async {
      await NotificationService.registerCurrentDeviceToken();

      await NotificationService.removeCurrentDeviceToken();

      final snapshot =
          await firestore.collection('users').doc('user-123').get();
      final tokens = List<String>.from(snapshot.data()?['fcmTokens'] ?? []);
      expect(tokens, isEmpty);
      verify(() => messaging.deleteToken()).called(1);
    });
  });
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase web app configuration. Native app IDs can be supplied with
/// --dart-define after registering those apps in Firebase.
class FirebaseOptionsConfig {
  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDbn9WJN19cIcARYyssiD1WolVvkOa4zjs',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'flappybirdsb-aa501',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '726607679999',
  );
  static const databaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: 'https://flappybirdsb-aa501-default-rtdb.firebaseio.com',
  );
  static const webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:726607679999:web:4b283712c7916469f857ca',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  static String get _appId {
    if (kIsWeb) return webAppId;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidAppId,
      TargetPlatform.iOS => iosAppId,
      _ => '',
    };
  }

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      databaseUrl.isNotEmpty &&
      _appId.isNotEmpty;

  static FirebaseOptions? get current {
    if (!isConfigured) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: _appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      databaseURL: databaseUrl,
      authDomain: kIsWeb ? '$projectId.firebaseapp.com' : null,
    );
  }
}

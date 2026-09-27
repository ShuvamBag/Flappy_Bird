import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../firebase_options.dart';

class FirebaseLeaderboard {
  FirebaseLeaderboard._();

  static final FirebaseLeaderboard instance = FirebaseLeaderboard._();

  FirebaseDatabase get _database => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: FirebaseOptionsConfig.databaseUrl,
      );

  Future<void> _ensureSignedIn() async {
    if (!FirebaseOptionsConfig.isConfigured) {
      throw StateError('Firebase is not configured for this platform.');
    }
    if (Firebase.apps.isEmpty) {
      final options = FirebaseOptionsConfig.current;
      if (options == null) {
        throw StateError('Firebase is not configured for this platform.');
      }
      await Firebase.initializeApp(options: options);
    }
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  String _playerKey(String name) {
    final normalizedName = name.trim().toLowerCase();
    return Uri.encodeComponent(normalizedName).replaceAll('.', '%2E');
  }

  Future<void> submitScore({required String name, required int score}) async {
    await _ensureSignedIn();
    final playerKey = _playerKey(name);
    final playerRef = _database.ref('leaderboard/$playerKey');
    await playerRef.runTransaction((currentValue) {
      final current = currentValue is Map ? currentValue : null;
      final previousScore = (current?['score'] as num?)?.toInt() ?? -1;
      if (score <= previousScore) return Transaction.abort();
      return Transaction.success({
        'name': name.trim(),
        'normalizedName': playerKey,
        'score': score,
      });
    }, applyLocally: false);
  }

  Future<List<Map<String, dynamic>>> getTopFive() async {
    await _ensureSignedIn();
    final snapshot = await _database
        .ref('leaderboard')
        .orderByChild('score')
        .limitToLast(5)
        .get();
    final entries = <Map<String, dynamic>>[];
    for (final child in snapshot.children) {
      final value = child.value;
      if (value is Map) {
        entries.add({
          'name': value['name']?.toString() ?? 'Player',
          'score': (value['score'] as num?)?.toInt() ?? 0,
        });
      }
    }
    entries.sort(
      (first, second) =>
          (second['score'] as int).compareTo(first['score'] as int),
    );
    return entries;
  }
}

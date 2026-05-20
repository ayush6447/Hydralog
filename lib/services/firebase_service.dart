import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static DocumentReference _userDoc() =>
      _db.collection('users').doc(_uid);

  // ── Profile ──────────────────────────────────────────────────────────────

  static Future<void> saveProfile(UserProfile profile, int goalMl) async {
    if (_uid == null) return;
    await _userDoc().set({
      'name': profile.name,
      'age': profile.age,
      'height': profile.height,
      'weight': profile.weight,
      'goalMl': goalMl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    if (_uid == null) return null;
    final doc = await _userDoc().get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // ── Water intake ─────────────────────────────────────────────────────────

  static Future<void> saveWaterIntake(String dateKey, int ml) async {
    if (_uid == null) return;
    await _userDoc()
        .collection('water')
        .doc(dateKey)
        .set({'ml': ml, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
  }

  static Future<Map<String, int>> loadWaterHistory() async {
    if (_uid == null) return {};
    final snap = await _userDoc().collection('water').get();
    return {for (var d in snap.docs) d.id: (d.data()['ml'] as int? ?? 0)};
  }

  // ── Health data ───────────────────────────────────────────────────────────

  static Future<void> saveHealthData(String dateKey, HealthData data) async {
    if (_uid == null) return;
    await _userDoc()
        .collection('health')
        .doc(dateKey)
        .set(data.toMap()..addAll({'updatedAt': FieldValue.serverTimestamp()}),
            SetOptions(merge: true));
  }

  static Future<Map<String, HealthData>> loadHealthHistory() async {
    if (_uid == null) return {};
    final snap = await _userDoc().collection('health').get();
    return {
      for (var d in snap.docs)
        d.id: HealthData.fromMap(d.data())
    };
  }

  // ── Real-time listener for cross-device sync ──────────────────────────────

  static Stream<Map<String, int>> waterStream() {
    if (_uid == null) return const Stream.empty();
    return _userDoc().collection('water').snapshots().map((snap) =>
        {for (var d in snap.docs) d.id: (d.data()['ml'] as int? ?? 0)});
  }

  static Stream<Map<String, HealthData>> healthStream() {
    if (_uid == null) return const Stream.empty();
    return _userDoc().collection('health').snapshots().map((snap) =>
        {for (var d in snap.docs) d.id: HealthData.fromMap(d.data())});
  }
}

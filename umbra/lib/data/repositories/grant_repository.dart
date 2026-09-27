import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_maps.dart';
import '../models/app_grant.dart';

/// `app_grants` koleksiyonu — harici uygulamanın (bağlantının) izni.
///
/// Eski `memory_grants` tablosu yerine `allowed_memory_ids` (Array) alanı
/// kullanılır: hangi hafıza kimin için izinli bilgisi grant dokümanında tutulur.
/// Doküman ID'si `{userId}_{appId}` şeklindedir, bu sayede bağlantı durumu
/// tek okuma/ yazma ile güncellenir.
class GrantRepository {
  GrantRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _grants =>
      _db.collection('app_grants');

  DocumentReference<Map<String, dynamic>> _ref(String userId, String appId) =>
      _grants.doc('${userId}_$appId');

  Future<List<AppGrant>> fetchAll(String userId) async {
    final snap = await _grants.where('user_id', isEqualTo: userId).get();
    final rows = snap.docs.map(docData).map(AppGrant.fromJson).toList()
      ..sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
    return rows;
  }

  Stream<List<AppGrant>> watchAll(String userId) {
    return _grants.where('user_id', isEqualTo: userId).snapshots().map((snap) {
      final rows = snap.docs.map(docData).map(AppGrant.fromJson).toList()
        ..sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
      return rows;
    });
  }

  /// Bağlantıyı açar / kapatır ve izinli hafıza listesini senkronize eder.
  Future<void> setConnection({
    required String userId,
    required String appId,
    required String appName,
    required bool active,
  }) async {
    final ref = _ref(userId, appId);
    final existing = await ref.get();
    final now = isoNow();

    String grantedAt = now;
    if (existing.exists) {
      final previous = AppGrant.fromJson(docData(existing));
      grantedAt = isoOf(previous.grantedAt);
    }

    await ref.set({
      'user_id': userId,
      'app_id': appId,
      'app_name': appName,
      'duration': active ? '30d' : 'revoked',
      'granted_at': grantedAt,
      'revoked_at': active ? null : now,
      'allowed_memory_ids': active
          ? await _allowedMemoryIds(userId, appId)
          : <String>[],
    }, SetOptions(merge: true));
  }

  /// Bağlantıyı tamamen kaldırır (prototipteki "Forget").
  Future<void> removeConnection({
    required String userId,
    required String appId,
  }) async {
    await _ref(userId, appId).delete();
  }

  /// Bu bağlantıdan türeyen hafızaların ID'leri.
  Future<List<String>> _allowedMemoryIds(String userId, String appId) async {
    final snap = await _db
        .collection('memories')
        .where('user_id', isEqualTo: userId)
        .get();
    return [
      for (final doc in snap.docs)
        if (doc.data()['connection'] == appId) doc.id,
    ];
  }
}

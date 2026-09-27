import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_maps.dart';
import '../models/enums.dart';
import '../models/memory.dart';

/// `memories` koleksiyonu.
///
/// Sorgular tek alan (`user_id`) eşitlik filtresiyle sınırlıdır; katman,
/// kaynak, bağlantı ve tarih filtreleme/sıralama istemci tarafında yapılır.
/// Bu sayede composite index gerekmez (test modunda index kurulumu yok).
class MemoryRepository {
  MemoryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _memories =>
      _db.collection('memories');

  Query<Map<String, dynamic>> _byUser(String userId) =>
      _memories.where('user_id', isEqualTo: userId);

  Future<List<Memory>> fetchAll(String userId) async {
    final snap = await _byUser(userId).get();
    return _sorted(snap.docs.map(docData).map(Memory.fromJson));
  }

  /// Canlı liste — Firestore snapshots yayını.
  Stream<List<Memory>> watchAll(String userId) {
    return _byUser(userId)
        .snapshots()
        .map((snap) => _sorted(snap.docs.map(docData).map(Memory.fromJson)));
  }

  Future<Memory> insert(Memory memory) async {
    final ref = _memories.doc();
    await ref.set(memory.toJson());
    return Memory.fromJson({...memory.toJson(), 'id': ref.id});
  }

  Future<void> insertMany(List<Memory> memories) async {
    if (memories.isEmpty) return;
    for (final chunk in _chunks(memories)) {
      final batch = _db.batch();
      for (final memory in chunk) {
        batch.set(_memories.doc(), memory.toJson());
      }
      await batch.commit();
    }
  }

  Future<void> updateStatement({
    required String id,
    required String statement,
    required List<String> derivation,
    DateTime? confirmedAt,
  }) async {
    await _memories.doc(id).update({
      'statement': statement,
      'derivation': derivation,
      if (confirmedAt != null) 'confirmed_at': isoOf(confirmedAt),
    });
  }

  Future<void> reconfirm({
    required String id,
    required List<String> derivation,
  }) async {
    await _memories.doc(id).update({
      'confirmed_at': isoNow(),
      'derivation': derivation,
    });
  }

  Future<void> delete(String id) => _memories.doc(id).delete();

  Future<void> deleteMany(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    for (final chunk in _chunks(list)) {
      final batch = _db.batch();
      for (final id in chunk) {
        batch.delete(_memories.doc(id));
      }
      await batch.commit();
    }
  }

  Future<List<Memory>> deleteByLayer({
    required String userId,
    required MemoryLayer layer,
  }) =>
      _deleteWhere(userId, (m) => m.layer == layer);

  Future<List<Memory>> deleteBySource({
    required String userId,
    required MemorySource source,
  }) =>
      _deleteWhere(userId, (m) => m.source == source);

  Future<List<Memory>> deleteByConnection({
    required String userId,
    required String connection,
  }) =>
      _deleteWhere(userId, (m) => m.connection == connection);

  Future<List<Memory>> deleteAll(String userId) =>
      _deleteWhere(userId, (_) => true);

  Future<List<Memory>> _deleteWhere(
    String userId,
    bool Function(Memory memory) test,
  ) async {
    final snap = await _byUser(userId).get();
    final removed = <Memory>[];
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final memory = Memory.fromJson(docData(doc));
      if (!test(memory)) continue;
      removed.add(memory);
      refs.add(doc.reference);
    }
    for (final chunk in _chunks(refs)) {
      final batch = _db.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
    return removed;
  }

  static List<Memory> _sorted(Iterable<Memory> rows) {
    final list = rows.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static List<List<T>> _chunks<T>(List<T> items, [int size = 400]) {
    final out = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      out.add(items.sublist(i, i + size > items.length ? items.length : i + size));
    }
    return out;
  }
}

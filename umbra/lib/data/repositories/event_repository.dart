import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_maps.dart';
import '../models/app_settings.dart';
import '../models/memory_event.dart';
import '../models/proposal.dart';

/// `events` koleksiyonu — append-only olay günlüğü (eski `memory_events`).
///
/// Kullanım başlıkları (`kind`):
///  - `log`               → Privacy ekranındaki "Recent" listesi
///  - `proposal`          → Today'deki "To review" kartları
///  - `proposal_resolved` → keep/reject kararı
///  - `settings`          → en güncel satır uygulama ayarları
///  - `chat`              → "Just talk" sohbet geçmişi
///
/// Sorgular tek alan (`user_id`) eşitlik filtresiyle sınırlıdır; `kind`
/// filtrelemesi ve sıralama istemci tarafında yapılır (composite index gerekmez).
class EventRepository {
  EventRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  Future<void> _insert({
    required String userId,
    required String kind,
    String? appId,
    required Map<String, dynamic> payload,
  }) async {
    await _events.add({
      'user_id': userId,
      'app_id': ?appId,
      'kind': kind,
      'payload': payload,
      'created_at': isoNow(),
    });
  }

  Future<List<MemoryEvent>> _fetch(
    String userId, {
    Set<String>? kinds,
    int? limit,
  }) async {
    final snap = await _events.where('user_id', isEqualTo: userId).get();
    final rows = snap.docs
        .map(docData)
        .map(MemoryEvent.fromJson)
        .where((e) => kinds == null || kinds.contains(e.kind))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit == null || rows.length <= limit) return rows;
    return rows.sublist(0, limit);
  }

  Future<void> log(String userId, String text, {String when = 'Today'}) =>
      _insert(
        userId: userId,
        kind: EventKind.log,
        payload: {'text': text, 't': when},
      );

  Future<List<MemoryEvent>> fetchLog(String userId, {int limit = 12}) =>
      _fetch(userId, kinds: {EventKind.log}, limit: limit);

  Future<void> addProposal(String userId, Proposal proposal) => _insert(
        userId: userId,
        kind: EventKind.proposal,
        appId: proposal.connection ?? proposal.source.id,
        payload: proposal.toPayload(),
      );

  Future<void> resolveProposal(
    String userId, {
    required String proposalId,
    required String action,
  }) =>
      _insert(
        userId: userId,
        kind: EventKind.proposalResolved,
        payload: {'proposal_id': proposalId, 'action': action},
      );

  /// Bekleyen önerileri (çözülmemiş olanlar) getirir.
  Future<List<Proposal>> fetchOpenProposals(String userId) async {
    final rows = await _fetch(
      userId,
      kinds: {EventKind.proposal, EventKind.proposalResolved},
      limit: 400,
    );

    final resolved = <String>{};
    final proposals = <MemoryEvent>[];
    for (final e in rows) {
      if (e.kind == EventKind.proposalResolved) {
        resolved.add('${e.payload['proposal_id']}');
      } else if (e.kind == EventKind.proposal) {
        proposals.add(e);
      }
    }
    return proposals
        .where((e) => !resolved.contains(e.id))
        .map((e) => Proposal.fromEvent(e.id, e.payload, e.createdAt))
        .toList();
  }

  Future<void> saveSettings(String userId, AppSettings settings) => _insert(
        userId: userId,
        kind: EventKind.settings,
        payload: settings.toJson(),
      );

  Future<AppSettings?> fetchLatestSettings(String userId) async {
    final rows = await _fetch(userId, kinds: {EventKind.settings}, limit: 1);
    if (rows.isEmpty) return null;
    final payload = rows.first.payload;
    if (payload.isEmpty) return const AppSettings();
    return AppSettings.fromJson(payload);
  }

  Future<void> addChat(
    String userId, {
    required String who,
    required String text,
  }) =>
      _insert(
        userId: userId,
        kind: EventKind.chat,
        appId: 'umbra',
        payload: {'who': who, 'text': text},
      );

  Future<List<MemoryEvent>> fetchChat(String userId, {int limit = 8}) async {
    final rows = await _fetch(userId, kinds: {EventKind.chat}, limit: limit);
    return rows.reversed.toList();
  }

  Future<void> addFeedback(
    String userId, {
    required String kind,
    Map<String, dynamic> payload = const {},
  }) =>
      _insert(userId: userId, kind: kind, appId: 'umbra', payload: payload);
}

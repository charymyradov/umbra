/// `events` koleksiyonu `kind` alanının izinli değerleri.
abstract final class EventKind {
  static const String log = 'log';
  static const String proposal = 'proposal';
  static const String proposalResolved = 'proposal_resolved';
  static const String settings = 'settings';
  static const String chat = 'chat';
  static const String feedback = 'feedback';
}

/// `events` dokümanı.
class MemoryEvent {
  const MemoryEvent({
    required this.id,
    required this.userId,
    this.appId,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? appId;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory MemoryEvent.fromJson(Map<String, dynamic> json) => MemoryEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        appId: json['app_id'] as String?,
        kind: (json['kind'] ?? '') as String,
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : const {},
        createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user_id': userId,
        'app_id': appId,
        'kind': kind,
        'payload': payload,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

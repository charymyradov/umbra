/// `app_grants` dokümanı — harici uygulamanın (ya da bağlantının) izni.
///
/// `allowed_memory_ids`: bu uygulamaya izin verilen hafıza ID'leri
/// (eski `memory_grants` tablosunun Array karşılığı).
class AppGrant {
  const AppGrant({
    required this.id,
    required this.userId,
    required this.appId,
    this.appName,
    this.duration = '30d',
    required this.grantedAt,
    this.revokedAt,
    this.allowedMemoryIds = const [],
  });

  final String id;
  final String userId;
  final String appId;
  final String? appName;
  final String duration;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final List<String> allowedMemoryIds;

  bool get isActive => revokedAt == null && duration != 'revoked';

  factory AppGrant.fromJson(Map<String, dynamic> json) => AppGrant(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        appId: json['app_id'] as String,
        appName: json['app_name'] as String?,
        duration: (json['duration'] as String?) ?? '30d',
        grantedAt: DateTime.tryParse('${json['granted_at']}')?.toLocal() ??
            DateTime.now(),
        revokedAt: DateTime.tryParse('${json['revoked_at']}')?.toLocal(),
        allowedMemoryIds: _stringList(json['allowed_memory_ids']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user_id': userId,
        'app_id': appId,
        'app_name': appName,
        'duration': duration,
        'granted_at': grantedAt.toUtc().toIso8601String(),
        'revoked_at': revokedAt?.toUtc().toIso8601String(),
        'allowed_memory_ids': allowedMemoryIds,
      };

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }
}

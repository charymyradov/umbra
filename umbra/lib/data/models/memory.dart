import 'enums.dart';

/// `public.memories` satırı.
class Memory {
  const Memory({
    this.id = '',
    required this.userId,
    required this.layer,
    required this.statement,
    required this.source,
    this.connection,
    this.detail,
    this.derivation = const [],
    this.confidence,
    this.basis,
    this.confirmedAt,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final MemoryLayer layer;
  final String statement;
  final MemorySource source;
  final String? connection;
  final String? detail;

  /// `derivation jsonb` — "nasıl geldik" adımları.
  final List<String> derivation;
  final double? confidence;
  final String? basis;
  final DateTime? confirmedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      layer: MemoryLayer.fromId(json['layer'] as String?),
      statement: (json['statement'] ?? '') as String,
      source: MemorySource.fromId(json['source'] as String?),
      connection: json['connection'] as String?,
      detail: json['detail'] as String?,
      derivation: _stringList(json['derivation']),
      confidence: (json['confidence'] as num?)?.toDouble(),
      basis: json['basis'] as String?,
      confirmedAt: _time(json['confirmed_at']),
      expiresAt: _time(json['expires_at']),
      createdAt: _time(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user_id': userId,
        'layer': layer.id,
        'statement': statement,
        'source': source.id,
        'connection': connection,
        'detail': detail,
        'derivation': derivation,
        'confidence': confidence,
        'basis': basis,
        'confirmed_at': confirmedAt?.toUtc().toIso8601String(),
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  Memory copyWith({
    String? statement,
    List<String>? derivation,
    DateTime? confirmedAt,
    DateTime? expiresAt,
  }) {
    return Memory(
      id: id,
      userId: userId,
      layer: layer,
      statement: statement ?? this.statement,
      source: source,
      connection: connection,
      detail: detail,
      derivation: derivation ?? this.derivation,
      confidence: confidence,
      basis: basis,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
    );
  }

  bool get isExplicit => source == MemorySource.explicit;

  /// Live katmanının bitiş tarihi; `expires_at` yoksa oluşturulma + süre.
  DateTime expiryFrom(int days) =>
      expiresAt ?? createdAt.add(Duration(days: days));

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  static DateTime? _time(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

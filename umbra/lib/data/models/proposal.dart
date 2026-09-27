import 'enums.dart';

/// Onay bekleyen çıkarım — `events(kind='proposal')`.
///
/// Tablo append-only olduğu için karar (keep/reject) ayrı bir
/// `proposal_resolved` olayı olarak yazılır.
class Proposal {
  const Proposal({
    required this.id,
    required this.layer,
    required this.statement,
    required this.prompt,
    required this.source,
    this.connection,
    this.confidence,
    this.basis,
    this.steps = const [],
    required this.createdAt,
  });

  final String id;
  final MemoryLayer layer;
  final String statement;
  final String prompt;
  final MemorySource source;
  final String? connection;
  final double? confidence;
  final String? basis;
  final List<String> steps;
  final DateTime createdAt;

  factory Proposal.fromEvent(String id, Map<String, dynamic> payload, DateTime createdAt) {
    return Proposal(
      id: id,
      layer: MemoryLayer.fromId(payload['layer'] as String?),
      statement: (payload['statement'] ?? '') as String,
      prompt: (payload['prompt'] ?? '') as String,
      source: MemorySource.fromId(payload['source'] as String?),
      connection: payload['connection'] as String?,
      confidence: (payload['confidence'] as num?)?.toDouble(),
      basis: payload['basis'] as String?,
      steps: payload['steps'] is List
          ? (payload['steps'] as List).map((e) => e.toString()).toList()
          : const [],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toPayload() => <String, dynamic>{
        'layer': layer.id,
        'statement': statement,
        'prompt': prompt,
        'source': source.id,
        'connection': connection,
        'confidence': confidence,
        'basis': basis,
        'steps': steps,
      };
}

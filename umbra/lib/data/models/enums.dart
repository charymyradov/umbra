/// Firestore `memories.layer` ve `memories.source` alanlarının karşılığı.
enum MemoryLayer {
  identity('identity'),
  preference('preference'),
  pattern('pattern'),
  live('live');

  const MemoryLayer(this.id);
  final String id;

  static MemoryLayer fromId(String? value) => MemoryLayer.values.firstWhere(
        (e) => e.id == value,
        orElse: () => MemoryLayer.preference,
      );
}

enum MemorySource {
  explicit('explicit'),
  behavioral('behavioral'),
  conversational('conversational'),
  ambient('ambient'),
  crossapp('crossapp');

  const MemorySource(this.id);
  final String id;

  static MemorySource fromId(String? value) => MemorySource.values.firstWhere(
        (e) => e.id == value,
        orElse: () => MemorySource.explicit,
      );
}

/// `app_grants.duration` izinli değerleri.
enum GrantDuration {
  session('session'),
  thirtyDays('30d'),
  revoked('revoked');

  const GrantDuration(this.id);
  final String id;
}

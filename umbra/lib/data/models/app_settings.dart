import 'enums.dart';

/// Uygulama ayarları — `events(kind='settings')` en güncel satırda saklanır.
///
/// Bağlantılar (kindle, podcasts, ...) ayrı bir tabloda (`app_grants`)
/// tutulduğu için burada yer almaz.
class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.mech = const {
      MemorySource.explicit: true,
      MemorySource.behavioral: true,
      MemorySource.conversational: true,
      MemorySource.ambient: true,
      MemorySource.crossapp: true,
    },
    this.suggestions = const {},
    this.expiryDays = 7,
    this.staleAfterDays = 60,
    this.morningAsked = false,
    this.tellMode = 'remember',
  });

  final bool onboarded;
  final Map<MemorySource, bool> mech;
  final Map<String, String> suggestions;
  final int expiryDays;
  final int staleAfterDays;
  final bool morningAsked;
  final String tellMode;

  bool mechOn(MemorySource s) => mech[s] ?? true;

  String? suggestionState(String id) => suggestions[id];

  AppSettings copyWith({
    bool? onboarded,
    Map<MemorySource, bool>? mech,
    Map<String, String>? suggestions,
    int? expiryDays,
    int? staleAfterDays,
    bool? morningAsked,
    String? tellMode,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      mech: mech ?? this.mech,
      suggestions: suggestions ?? this.suggestions,
      expiryDays: expiryDays ?? this.expiryDays,
      staleAfterDays: staleAfterDays ?? this.staleAfterDays,
      morningAsked: morningAsked ?? this.morningAsked,
      tellMode: tellMode ?? this.tellMode,
    );
  }

  AppSettings withSuggestion(String id, String state) => copyWith(
        suggestions: {...suggestions, id: state},
      );

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    final mechRaw = json['mech'];
    final mech = <MemorySource, bool>{
      for (final s in MemorySource.values) s: true,
    };
    if (mechRaw is Map) {
      for (final s in MemorySource.values) {
        final v = mechRaw[s.id] ?? mechRaw[s.name];
        if (v is bool) mech[s] = v;
      }
    }
    final sugRaw = json['suggestions'];
    final suggestions = <String, String>{};
    if (sugRaw is Map) {
      sugRaw.forEach((k, v) => suggestions['$k'] = '$v');
    }
    return AppSettings(
      onboarded: json['onboarded'] == true,
      mech: mech,
      suggestions: suggestions,
      expiryDays: (json['expiryDays'] as num?)?.toInt() ?? 7,
      staleAfterDays: (json['staleAfterDays'] as num?)?.toInt() ?? 60,
      morningAsked: json['morningAsked'] == true,
      tellMode: (json['tellMode'] as String?) ?? 'remember',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'onboarded': onboarded,
        'mech': {for (final e in mech.entries) e.key.id: e.value},
        'suggestions': suggestions,
        'expiryDays': expiryDays,
        'staleAfterDays': staleAfterDays,
        'morningAsked': morningAsked,
        'tellMode': tellMode,
      };
}

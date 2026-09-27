import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formats.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/models/proposal.dart';

// ---------------------------------------------------------------------------
// Hafıza sunumu
// ---------------------------------------------------------------------------

/// Prototipteki `mv(m)` — bir hafıza satırının ekranda ihtiyacı olan her şeyi.
class MemoryView {
  MemoryView(this.memory)
      : layer = layerOf(memory.layer),
        source = sourceOf(memory.source),
        connection = connectionOf(memory.connection);

  final Memory memory;
  final LayerDef layer;
  final SourceDef source;
  final ConnectionDef? connection;

  String get id => memory.id;
  String get text => memory.statement;
  MemoryLayer get layerId => memory.layer;
  MemorySource get sourceId => memory.source;

  bool get isIdentity => memory.layer == MemoryLayer.identity;
  bool get isPref => memory.layer == MemoryLayer.preference;
  bool get isPattern => memory.layer == MemoryLayer.pattern;
  bool get isLive => memory.layer == MemoryLayer.live;

  bool get hasConf => isPattern && memory.confidence != null;
  bool get told => memory.source == MemorySource.explicit;

  String get srcCode => source.code;
  Color get srcBg => source.color;
  String get srcName =>
      connection == null ? source.name : '${source.name} · ${connection!.name}';

  String get certainty => told
      ? 'You said it'
      : isPattern
          ? 'Inferred · you confirmed'
          : 'Observed · you confirmed';

  String get confWord => confWordOf(memory.confidence);
  List<bool> get dots => confDots(memory.confidence);

  DateTime expiryFrom(int days) => memory.expiryFrom(days);

  int daysLeftFrom(int days) {
    final exp = expiryFrom(days);
    final left = daysBetween(DateTime.now(), exp);
    return left < 0 ? 0 : left;
  }

  /// Live kartındaki yüzde halkası (kalan gün / toplam süre).
  double expiryRatio(int days) {
    if (!isLive || days <= 0) return 0;
    return (daysLeftFrom(days) / days).clamp(0, 1).toDouble();
  }

  String expiryLine(int days) {
    if (!isLive) return '';
    final exp = expiryFrom(days);
    return '${daysLeftFrom(days)}d left · ${fmtDate(exp)}';
  }

  String get shortMeta {
    if (isPref) return 'Confirmed ${fmtDate(memory.confirmedAt)}';
    if (isPattern) return memory.basis ?? 'You told me';
    final who = connection?.name ?? source.name;
    return '$who · ${fmtDate(memory.createdAt)}';
  }

  String get confirmedFmt => fmtDate(memory.confirmedAt);

  bool staleAfter(int staleDays) =>
      isPref &&
      memory.confirmedAt != null &&
      daysSince(memory.confirmedAt!) > staleDays;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack =
        '${memory.statement} ${source.name} ${memory.connection ?? ''} ${memory.detail ?? ''}';
    return haystack.toLowerCase().contains(q);
  }
}

String confWordOf(double? c) {
  if (c == null) return '';
  if (c < 0.45) return 'Low';
  if (c < 0.7) return 'Moderate';
  return 'Fairly high';
}

// ---------------------------------------------------------------------------
// Onay bekleyen kart
// ---------------------------------------------------------------------------

class PendingView {
  PendingView(this.proposal)
      : layer = layerOf(proposal.layer),
        source = sourceOf(proposal.source),
        connection = connectionOf(proposal.connection);

  final Proposal proposal;
  final LayerDef layer;
  final SourceDef source;
  final ConnectionDef? connection;

  String get glyph => connection?.glyph ?? source.code;
  Color get srcBg => connection?.color ?? source.color;
  String get srcLine => connection?.name ?? source.name;
  bool get isPattern => proposal.layer == MemoryLayer.pattern;
  bool get isLive => proposal.layer == MemoryLayer.live;
  List<bool> get dots => confDots(proposal.confidence);
  String get prompt => proposal.prompt;
  String get text => proposal.statement;
}

// ---------------------------------------------------------------------------
// Öneriler
// ---------------------------------------------------------------------------

class BasisItem {
  const BasisItem({
    required this.text,
    required this.color,
    required this.bg,
    required this.memoryId,
  });

  final String text;
  final Color color;
  final Color bg;
  final String memoryId;
}

class SuggestionView {
  const SuggestionView({
    required this.id,
    required this.when,
    required this.title,
    required this.author,
    required this.kind,
    required this.mins,
    required this.sub,
    required this.cbg,
    required this.cfg,
    required this.done,
    required this.hasPattern,
    required this.inferred,
    required this.basis,
    this.prog,
  });

  final String id;
  final String when;
  final String title;
  final String author;
  final String kind;
  final String mins;
  final String sub;
  final String? prog;
  final Color cbg;
  final Color cfg;
  final bool done;
  final bool hasPattern;
  final bool inferred;
  final List<BasisItem> basis;

  bool get active => !done;
  bool get hasProg => prog != null;

  String get pill => hasPattern
      ? 'From a pattern'
      : inferred
          ? 'From a signal'
          : 'You told me';

  Color get pillBg =>
      inferred && !hasPattern ? Colors.transparent : const Color(0xFFEAE2D3);

  Color get pillFg => hasPattern ? AppColors.blue : AppColors.muted;

  BorderSide get pillBorder => hasPattern
      ? const BorderSide(color: Color(0xFFB9C8D6), width: 1.5)
      : inferred
          ? const BorderSide(color: AppColors.hairline, width: 1.5)
          : BorderSide.none;

  Color get dotFill => inferred && !hasPattern ? Colors.transparent : cfg;

  String get basisText => hasPattern
      ? 'Suggested from a pattern, not something you told me.'
      : inferred
          ? 'Based on a signal you confirmed.'
          : 'Based on what you told me.';
}

Color basisColorOf(LayerDef l) => l.shapeFill ?? l.color;

/// Prototipteki `suggestions()` — mevcut hafızalardan türetilir.
List<SuggestionView> buildSuggestions(List<Memory> mem, AppSettings settings) {
  Memory? firstWhere(bool Function(Memory m) test) {
    for (final m in mem) {
      if (test(m)) return m;
    }
    return null;
  }

  bool any(bool Function(Memory m) test) => firstWhere(test) != null;

  bool isLive(Memory m) => m.layer == MemoryLayer.live;
  String lower(Memory m) => m.statement.toLowerCase();

  final short =
      any((m) => isLive(m) && lower(m).contains('minutes today'));
  final onBreak = any((m) => isLive(m) && lower(m).contains('break from'));

  final reading = firstWhere((m) =>
      isLive(m) &&
      m.connection == 'kindle' &&
      lower(m).startsWith('reading'));
  final clubFact = firstWhere(
      (m) => m.layer == MemoryLayer.identity && lower(m).contains('book club'));
  final clubLive = firstWhere((m) =>
      isLive(m) &&
      m.connection == 'calendar' &&
      lower(m).contains('club'));
  final talk = firstWhere(
      (m) => isLive(m) && lower(m).contains('talk') && !lower(m).contains('book club'));
  final flight = firstWhere((m) => isLive(m) && lower(m).contains('flight'));
  final commute = firstWhere((m) =>
      m.layer == MemoryLayer.pattern && m.connection == 'podcasts');
  final topics = firstWhere((m) =>
      m.layer == MemoryLayer.preference &&
      m.detail == 'Onboarding' &&
      lower(m).contains('drawn to'));
  final evening = firstWhere((m) =>
      m.layer == MemoryLayer.pattern && lower(m).contains('evening'));
  final rhythm = firstWhere((m) =>
      m.layer == MemoryLayer.preference && lower(m).contains('minute session'));
  final highlight = firstWhere((m) =>
      m.layer == MemoryLayer.pattern && lower(m).contains('highlight'));
  final stall = firstWhere(
      (m) => m.layer == MemoryLayer.pattern && lower(m).contains('stall'));
  final goals = firstWhere((m) =>
      m.layer == MemoryLayer.preference && lower(m).startsWith('goals'));

  BasisItem? basisOf(Memory? m) {
    if (m == null) return null;
    final view = MemoryView(m);
    return BasisItem(
      text: m.statement,
      color: basisColorOf(view.layer),
      bg: view.layer.bg,
      memoryId: m.id,
    );
  }

  List<BasisItem> basisOfAll(List<Memory?> items) =>
      items.map(basisOf).whereType<BasisItem>().toList();

  bool hasPatternOf(List<Memory?> items) =>
      items.whereType<Memory>().any((m) => m.layer == MemoryLayer.pattern);

  bool inferredOf(List<Memory?> items) =>
      items.whereType<Memory>().any((m) => !m.isExplicit);

  final result = <SuggestionView>[];

  if (reading != null) {
    final items = [reading, evening, rhythm, if (short) null];
    result.add(
      SuggestionView(
        id: 's_book',
        when: evening != null ? 'Tonight, 9 pm' : 'This evening',
        title: 'The Extended Mind',
        author: 'Annie Murphy Paul',
        kind: 'Book',
        mins: short ? '15 min' : '25 min',
        sub: short
            ? 'Chapter 7, first part · 15 min'
            : 'Chapter 7 · 25 min',
        prog: _progOf(reading.statement) ?? '62%',
        cbg: const Color(0xFF33486A),
        cfg: const Color(0xFFF1E6D0),
        done: settings.suggestionState('s_book') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  if (clubFact != null && clubLive != null) {
    final items = [clubFact, clubLive];
    result.add(
      SuggestionView(
        id: 's_club',
        when: 'Before Wed',
        title: 'Piranesi',
        author: 'Susanna Clarke',
        kind: 'Book club',
        mins: '90 min',
        sub: 'Chapters 1–4 · over 3 evenings',
        cbg: const Color(0xFF7A3B2E),
        cfg: const Color(0xFFF3E3CF),
        done: settings.suggestionState('s_club') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  if (talk != null && !onBreak) {
    final items = [talk, highlight];
    result.add(
      SuggestionView(
        id: 's_talk',
        when: 'Today',
        title: 'The Myth of Multitasking',
        author: 'Read-later',
        kind: 'Long read',
        mins: '18 min',
        sub: 'For your talk · 18 min',
        cbg: const Color(0xFFC9A45C),
        cfg: const Color(0xFF2B2620),
        done: settings.suggestionState('s_talk') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  if (flight != null) {
    final items = [flight, stall];
    result.add(
      SuggestionView(
        id: 's_flight',
        when: 'Saturday flight',
        title: 'Three short essays',
        author: 'Offline pack',
        kind: 'Essays',
        mins: '2.5 hr',
        sub: 'Saved offline · 2.5 hr',
        cbg: const Color(0xFF4B6A42),
        cfg: const Color(0xFFEFEAD8),
        done: settings.suggestionState('s_flight') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  if (commute != null) {
    final items = [commute];
    result.add(
      SuggestionView(
        id: 's_pod',
        when: 'Tue commute',
        title: 'Why we forget',
        author: 'Hidden Brain',
        kind: 'Podcast',
        mins: '42 min',
        sub: 'Podcast · 42 min',
        cbg: const Color(0xFF5B4163),
        cfg: const Color(0xFFF0E4EC),
        done: settings.suggestionState('s_pod') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  if (topics != null) {
    final items = [topics, goals];
    result.add(
      SuggestionView(
        id: 's_new',
        when: 'Anytime',
        title: 'Intro to ${_firstTopic(topics.statement)}',
        author: 'Primer',
        kind: 'Article',
        mins: '12 min',
        sub: 'Something new · 12 min',
        cbg: const Color(0xFFD8CBB3),
        cfg: const Color(0xFF2B2620),
        done: settings.suggestionState('s_new') == 'done',
        hasPattern: hasPatternOf(items),
        inferred: inferredOf(items),
        basis: basisOfAll(items),
      ),
    );
  }

  final hidden =
      result.where((s) => settings.suggestionState(s.id) != 'hidden').toList();
  return hidden;
}

/// "Drawn to cognitive science and design." → "cognitive science"
String _firstTopic(String statement) {
  final idx = statement.toLowerCase().indexOf('drawn to ');
  if (idx < 0) return 'something new';
  var rest = statement.substring(idx + 'drawn to '.length);
  rest = rest.replaceAll(RegExp(r'\.$'), '');
  final parts = rest.split(RegExp(r'\s*,\s*|\s+and\s+'));
  final first = parts.first.trim();
  return first.isEmpty ? 'something new' : first;
}

String? _progOf(String statement) {
  final m = RegExp(r'\((\d+)%\)').firstMatch(statement);
  return m == null ? null : '${m.group(1)}%';
}

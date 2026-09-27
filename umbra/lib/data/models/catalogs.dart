import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'enums.dart';

/// Katman (hafıza seviyesi) tanımı — prototipteki `LAYERS`.
class LayerDef {
  const LayerDef._({
    required this.id,
    required this.name,
    required this.tag,
    required this.color,
    required this.bg,
    required this.empty,
    required this.shapeRadius,
    this.shapeBorder,
    this.shapeBorderWidth = 0,
    this.shapeFill,
    this.cardBorder,
    this.addPlaceholder = '',
    this.addNote = '',
  });

  final MemoryLayer id;
  final String name;
  final String tag;
  final Color color;
  final Color bg;
  final String empty;
  final double shapeRadius; // 3 = kare, 999 = daire
  final Color? shapeBorder;
  final double shapeBorderWidth;
  final Color? shapeFill;
  final Color? cardBorder;
  final String addPlaceholder;
  final String addNote;
}

const double _r = 999;

const List<LayerDef> kLayers = [
  LayerDef._(
    id: MemoryLayer.identity,
    name: 'Identity',
    tag: 'Stable',
    color: AppColors.ink,
    bg: Color(0xFFEAE2D3),
    empty: 'No stable facts.',
    shapeRadius: 3,
    shapeFill: AppColors.ink,
    addPlaceholder: 'e.g. I have a daughter, Ana',
    addNote: 'Stable fact. Future edits need confirmation.',
  ),
  LayerDef._(
    id: MemoryLayer.preference,
    name: 'Preferences',
    tag: 'Confirmed',
    color: AppColors.warn,
    bg: Color(0xFFF4E7D3),
    empty: 'No preferences.',
    shapeRadius: _r,
    shapeFill: Color(0xFFC0772E),
    addPlaceholder: 'e.g. Prefer audiobooks for history',
    addNote: "I'll check in after 60 days.",
  ),
  LayerDef._(
    id: MemoryLayer.pattern,
    name: 'Patterns',
    tag: 'Probable',
    color: AppColors.blue,
    bg: Color(0xFFE4EAF0),
    empty: 'No patterns.',
    shapeRadius: _r,
    shapeBorder: AppColors.blue,
    shapeBorderWidth: 2,
    addPlaceholder: 'e.g. I read more on weekends',
    addNote: 'Saved as something you told me, not an inference.',
  ),
  LayerDef._(
    id: MemoryLayer.live,
    name: 'Live',
    tag: 'Temporary',
    color: AppColors.good,
    bg: Color(0xFFE6EDDF),
    empty: 'Nothing current.',
    shapeRadius: _r,
    shapeBorder: AppColors.good,
    shapeBorderWidth: 2,
    cardBorder: Color(0xFFB8C9AB),
    addPlaceholder: 'e.g. Studying for an exam this week',
    addNote: 'Auto-deletes in 7 days.',
  ),
];

LayerDef layerOf(MemoryLayer id) => kLayers.firstWhere((l) => l.id == id);

/// Kaynak (öğrenme mekanizması) tanımı — prototipteki `SRC`.
class SourceDef {
  const SourceDef({
    required this.id,
    required this.code,
    required this.name,
    required this.short,
    required this.color,
    required this.rule,
  });

  final MemorySource id;
  final String code;
  final String name;
  final String short;
  final Color color;

  /// Privacy ekranındaki kural satırı.
  final String rule;
}

const List<SourceDef> kSources = [
  SourceDef(
    id: MemorySource.explicit,
    code: 'a',
    name: 'Told directly',
    short: 'Saves directly',
    color: AppColors.ink,
    rule: 'Saves directly',
  ),
  SourceDef(
    id: MemorySource.behavioral,
    code: 'b',
    name: 'In-app behavior',
    short: 'What you start or skip',
    color: Color(0xFF8A5A1F),
    rule: 'Asks first',
  ),
  SourceDef(
    id: MemorySource.conversational,
    code: 'c',
    name: 'Conversation',
    short: 'Things you mention',
    color: Color(0xFF7A3B2E),
    rule: 'Asks first',
  ),
  SourceDef(
    id: MemorySource.ambient,
    code: 'd',
    name: 'Passive signals',
    short: 'Calendar, place type',
    color: Color(0xFF4B6A42),
    rule: 'Asks first',
  ),
  SourceDef(
    id: MemorySource.crossapp,
    code: 'e',
    name: 'Connected apps',
    short: 'Kindle, podcasts, more',
    color: Color(0xFF33486A),
    rule: 'Asks first',
  ),
];

const List<MemorySource> kSourceOrder = [
  MemorySource.explicit,
  MemorySource.behavioral,
  MemorySource.conversational,
  MemorySource.ambient,
  MemorySource.crossapp,
];

SourceDef sourceOf(MemorySource id) => kSources.firstWhere((s) => s.id == id);

/// Bağlantı (kaynak uygulama) tanımı — prototipteki `CONNS`.
class ConnectionDef {
  const ConnectionDef({
    required this.id,
    required this.name,
    required this.glyph,
    required this.mech,
    required this.reads,
    required this.color,
  });

  final String id;
  final String name;
  final String glyph;
  final MemorySource mech;
  final String reads;
  final Color color;
}

const List<ConnectionDef> kConnections = [
  ConnectionDef(
    id: 'kindle',
    name: 'Kindle',
    glyph: 'K',
    mech: MemorySource.crossapp,
    reads: 'Progress, highlights',
    color: Color(0xFF33486A),
  ),
  ConnectionDef(
    id: 'podcasts',
    name: 'Podcasts',
    glyph: 'P',
    mech: MemorySource.crossapp,
    reads: 'Episodes played',
    color: Color(0xFF5B4163),
  ),
  ConnectionDef(
    id: 'calendar',
    name: 'Calendar',
    glyph: 'C',
    mech: MemorySource.ambient,
    reads: 'Event titles, free time',
    color: Color(0xFF7A3B2E),
  ),
  ConnectionDef(
    id: 'notes',
    name: 'Notes',
    glyph: 'N',
    mech: MemorySource.crossapp,
    reads: 'Only #reading notes',
    color: Color(0xFFC9A45C),
  ),
  ConnectionDef(
    id: 'readlater',
    name: 'Read-later',
    glyph: 'R',
    mech: MemorySource.crossapp,
    reads: 'Saved article topics',
    color: Color(0xFF8A5A1F),
  ),
  ConnectionDef(
    id: 'location',
    name: 'Location',
    glyph: 'L',
    mech: MemorySource.ambient,
    reads: 'Place type only',
    color: Color(0xFF4B6A42),
  ),
  ConnectionDef(
    id: 'shelf',
    name: 'Bookshelf',
    glyph: 'S',
    mech: MemorySource.crossapp,
    reads: 'Shelves, ratings',
    color: Color(0xFF2B2620),
  ),
];

ConnectionDef? connectionOf(String? id) {
  if (id == null) return null;
  for (final c in kConnections) {
    if (c.id == id) return c;
  }
  return null;
}

/// Onboarding seçim listeleri.
const List<String> kGoals = [
  'Learn a new field',
  'Finish what I start',
  'Read more fiction',
  'Read instead of scrolling',
];

const List<(String, Color, Color)> kTopics = [
  ('Cognitive science', Color(0xFF33486A), Color(0xFFF1E6D0)),
  ('Design', Color(0xFFC9A45C), Color(0xFF2B2620)),
  ('History', Color(0xFF7A3B2E), Color(0xFFF3E3CF)),
  ('Climate', Color(0xFF4B6A42), Color(0xFFEFEAD8)),
  ('Fiction', Color(0xFF5B4163), Color(0xFFF0E4EC)),
  ('Economics', Color(0xFFD8CBB3), Color(0xFF2B2620)),
];

const List<(String, Color)> kTimes = [
  ('Morning', Color(0xFFE9C98A)),
  ('Commute', Color(0xFFD8B27A)),
  ('Lunch', Color(0xFFE2A95C)),
  ('Evening', Color(0xFFB7684A)),
  ('Night', Color(0xFF4A4560)),
];

const List<String> kFormats = ['Books', 'Articles', 'Podcasts'];

const List<String> kSessionLengths = ['10', '20', '45'];

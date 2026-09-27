import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/app_grant.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/models/memory_event.dart';
import '../data/providers/data_providers.dart';
import 'presentation.dart';
import 'shell_controller.dart';

class MechRowVm {
  const MechRowVm({
    required this.def,
    required this.count,
    required this.on,
  });

  final SourceDef def;
  final int count;
  final bool on;

  bool get locked => def.id == MemorySource.explicit;
  bool get toggleable => !locked;
  bool get hasMem => count > 0;

  String get rule =>
      locked ? 'Saves directly' : (on ? 'Asks first' : 'Off');

  Color get ruleColor =>
      (locked || on) ? const Color(0xFF5E564B) : const Color(0xFF8A8174);
}

class LayerForgetVm {
  const LayerForgetVm({required this.def, required this.count});

  final LayerDef def;
  final int count;

  double get opacity => count > 0 ? 1 : 0.45;
}

class LogRowVm {
  const LogRowVm({required this.when, required this.text, required this.first});

  final String when;
  final String text;
  final bool first;
}

class PrivacyUiState {
  const PrivacyUiState({
    required this.memCount,
    required this.srcBar,
    required this.mechRows,
    required this.layers,
    required this.log,
  });

  final int memCount;

  /// (yüzde, renk) — "Where memories come from" çubuğu.
  final List<(double, Color)> srcBar;
  final List<MechRowVm> mechRows;
  final List<LayerForgetVm> layers;
  final List<LogRowVm> log;

  static const PrivacyUiState empty = PrivacyUiState(
    memCount: 0,
    srcBar: [],
    mechRows: [],
    layers: [],
    log: [],
  );
}

/// Gizlilik sekmesi: kaynak dağılımı, öğrenme izinleri, dışa aktarma ve
/// "her şeyi unut" eylemleri.
class PrivacyViewModel extends Notifier<PrivacyUiState> {
  @override
  PrivacyUiState build() {
    final memories = ref.watch(memoriesProvider).value ?? const <Memory>[];
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final events = ref.watch(logProvider).value ?? const <MemoryEvent>[];

    final total = memories.length;
    final srcBar = <(double, Color)>[];
    if (total > 0) {
      for (final s in kSourceOrder) {
        final n = memories.where((m) => m.source == s).length;
        srcBar.add((n / total, sourceOf(s).color));
      }
    }

    final mechRows = <MechRowVm>[
      for (final s in kSourceOrder)
        MechRowVm(
          def: sourceOf(s),
          count: memories.where((m) => m.source == s).length,
          on: settings.mechOn(s),
        ),
    ];

    final layers = <LayerForgetVm>[
      for (final l in kLayers)
        LayerForgetVm(
          def: l,
          count: memories.where((m) => m.layer == l.id).length,
        ),
    ];

    final log = <LogRowVm>[
      for (var i = 0; i < events.length && i < 3; i++)
        LogRowVm(
          when: '${events[i].payload['t'] ?? 'Today'}',
          text: '${events[i].payload['text'] ?? ''}',
          first: i == 0,
        ),
    ];

    return PrivacyUiState(
      memCount: total,
      srcBar: srcBar,
      mechRows: mechRows,
      layers: layers,
      log: log,
    );
  }

  Future<void> toggleMech(MemorySource source) async {
    if (source == MemorySource.explicit) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final current =
        ref.read(settingsProvider).value ?? const AppSettings();
    final nextOn = !current.mechOn(source);
    final next = current.copyWith(
      mech: {...current.mech, source: nextOn},
    );
    await ref.read(settingsProvider.notifier).save(next);

    await ref.read(eventRepositoryProvider).log(
          userId,
          '${sourceOf(source).name} turned ${nextOn ? 'on' : 'off'}.',
        );
    ref.invalidate(logProvider);
    ref.read(shellProvider.notifier)
        .showToast('${sourceOf(source).name} ${nextOn ? 'on' : 'off'}');
  }

  Future<void> forgetMechanism(MemorySource source) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final removed = await ref
        .read(memoryRepositoryProvider)
        .deleteBySource(userId: userId, source: source);
    if (removed.isEmpty) return;
    final name = sourceOf(source).name.toLowerCase();
    await ref.read(eventRepositoryProvider).log(
          userId,
          'Forgot ${removed.length} from $name',
        );
    ref.invalidate(logProvider);
    await ref.read(memoriesProvider.notifier).reload();
    ref.read(shellProvider.notifier).showToast(
          'Forgot ${removed.length} from $name',
          undo: removed,
        );
  }

  Future<void> forgetLayer(MemoryLayer layer) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final removed = await ref
        .read(memoryRepositoryProvider)
        .deleteByLayer(userId: userId, layer: layer);
    if (removed.isEmpty) return;
    final name = layerOf(layer).name.toLowerCase();
    await ref.read(eventRepositoryProvider).log(userId, 'Forgot all $name');
    ref.invalidate(logProvider);
    await ref.read(memoriesProvider.notifier).reload();
    ref.read(shellProvider.notifier)
        .showToast('Forgot all $name', undo: removed);
  }

  Future<void> forgetEverything() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final removed =
        await ref.read(memoryRepositoryProvider).deleteAll(userId);
    await ref.read(eventRepositoryProvider).log(userId, 'Deleted everything.');
    ref.invalidate(logProvider);
    ref.invalidate(proposalsProvider);
    await ref.read(memoriesProvider.notifier).reload();
    ref.read(shellProvider.notifier)
        .showToast('Everything forgotten', undo: removed);
  }

  // ---------------------------------------------------------------------
  // Dışa aktarma
  // ---------------------------------------------------------------------

  String exportJson() {
    final memories = ref.read(memoriesProvider).value ?? const <Memory>[];
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    final grants = ref.read(grantsProvider).value ?? const <AppGrant>[];
    final events = ref.read(logProvider).value ?? const <MemoryEvent>[];

    Map<String, dynamic> item(Memory m) => {
          'id': m.id,
          'statement': m.statement,
          'source': {
            'mechanism': m.source.id,
            'code': sourceOf(m.source).code,
            'label': sourceOf(m.source).name,
            'connection': m.connection,
            'detail': m.detail,
          },
          'derivation': m.derivation,
          'recorded_at': m.createdAt.toIso8601String(),
          'last_confirmed_at': m.confirmedAt?.toIso8601String(),
          'confidence': m.confidence == null
              ? null
              : {
                  'score': m.confidence,
                  'label': confWordOf(m.confidence),
                  'basis': m.basis,
                },
          'expires_at':
              m.layer == MemoryLayer.live ? m.expiryFrom(settings.expiryDays).toIso8601String() : null,
        };

    final payload = <String, dynamic>{
      'schema': 'umbra.memory/v1',
      'exported_at': DateTime.now().toIso8601String(),
      'layers': {
        for (final l in kLayers)
          l.id.id: memories.where((m) => m.layer == l.id).map(item).toList(),
      },
      'permissions': {
        for (final s in kSourceOrder)
          s.id: {
            'enabled': settings.mechOn(s),
            'stores': s == MemorySource.explicit
                ? 'directly'
                : 'after_confirmation',
          },
      },
      'connections': [
        for (final c in kConnections)
          {
            'id': c.id,
            'name': c.name,
            'mechanism': c.mech.id,
            'enabled': grants.any((g) => g.appId == c.id && g.isActive),
          },
      ],
      'activity': [
        for (final e in events) {'t': e.payload['t'], 'text': e.payload['text']},
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String exportSummary() {
    final memories = ref.read(memoriesProvider).value ?? const <Memory>[];
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();

    final lines = <String>[
      'What Umbra knows about you',
      'Exported ${DateTime.now().toLocal()}',
      '',
    ];
    for (final l in kLayers) {
      final items = memories.where((m) => m.layer == l.id).toList();
      lines.add('${l.name.toUpperCase()} · ${l.tag} (${items.length})');
      lines.add('');
      for (final m in items) {
        final v = MemoryView(m);
        lines.add('• ${m.statement}');
        lines.add('  Source: ${v.srcName} — ${m.detail ?? ''}');
        if (v.isPattern) {
          lines.add(
              '  Confidence: ${confWordOf(m.confidence)}, based on ${m.basis ?? ''}');
        }
        if (v.isLive) {
          lines.add('  Expires: ${v.expiryLine(settings.expiryDays)}');
        }
        if (v.isPref) lines.add('  Last confirmed ${fmtDate(m.confirmedAt)}');
      }
      lines.add('');
    }
    lines.add('Learning permissions:');
    for (final s in kSourceOrder) {
      lines.add(
          '  ${sourceOf(s).code}) ${sourceOf(s).name}: ${settings.mechOn(s) ? 'on' : 'off'}');
    }
    return lines.join('\n');
  }
}

final NotifierProvider<PrivacyViewModel, PrivacyUiState> privacyProvider =
    NotifierProvider<PrivacyViewModel, PrivacyUiState>(PrivacyViewModel.new);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/app_grant.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/memory.dart';
import '../data/providers/data_providers.dart';
import 'shell_controller.dart';

class ConnectionCardVm {
  const ConnectionCardVm({
    required this.def,
    required this.on,
    required this.mechOn,
    required this.memoryCount,
  });

  final ConnectionDef def;
  final bool on;
  final bool mechOn;
  final int memoryCount;

  bool get live => on && mechOn;
  bool get hasMemory => memoryCount > 0;

  Color get tileBg => live ? def.color : const Color(0xFFEEE7D9);
  Color get tileFg => live ? const Color(0xFFFFFDF8) : const Color(0xFF8A8174);
  double get opacity => mechOn ? 1 : 0.55;

  String get statusLine {
    if (!mechOn) return 'Paused in Privacy';
    if (memoryCount > 0) return plural(memoryCount, 'memory');
    return on ? 'Connected' : 'Off';
  }
}

class SourcesUiState {
  const SourcesUiState({required this.cards, required this.loading});

  final List<ConnectionCardVm> cards;
  final bool loading;

  int get activeCount => cards.where((c) => c.live).length;
  String get summary => '$activeCount of ${cards.length} active';
}

/// Kaynaklar sekmesi — bağlantı izinleri ve hafıza sayaçları.
class SourcesViewModel extends Notifier<SourcesUiState> {
  @override
  SourcesUiState build() {
    final memories = ref.watch(memoriesProvider).value ?? const <Memory>[];
    final grants = ref.watch(grantsProvider).value ?? const <AppGrant>[];
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final loading = ref.watch(memoriesProvider).isLoading &&
        ref.watch(grantsProvider).isLoading;

    final cards = <ConnectionCardVm>[
      for (final c in kConnections)
        ConnectionCardVm(
          def: c,
          on: grants.any((g) => g.appId == c.id && g.isActive),
          mechOn: settings.mechOn(c.mech),
          memoryCount: memories.where((m) => m.connection == c.id).length,
        ),
    ];
    return SourcesUiState(cards: cards, loading: loading);
  }

  Future<void> toggle(ConnectionCardVm card) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final next = !card.on;
    await ref.read(grantRepositoryProvider).setConnection(
          userId: userId,
          appId: card.def.id,
          appName: card.def.name,
          active: next,
        );
    await ref.read(eventRepositoryProvider).log(
          userId,
          '${card.def.name} ${next ? 'connected' : 'paused'}.',
        );
    ref.invalidate(logProvider);
    await ref.read(grantsProvider.notifier).reload();
    ref.read(shellProvider.notifier)
        .showToast('${card.def.name} ${next ? 'connected' : 'paused'}');
  }

  Future<void> forget(ConnectionCardVm card) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final memories = ref.read(memoriesProvider).value ?? const <Memory>[];
    final removed = memories.where((m) => m.connection == card.def.id).toList();

    await ref.read(grantRepositoryProvider).removeConnection(
          userId: userId,
          appId: card.def.id,
        );
    if (removed.isNotEmpty) {
      await ref
          .read(memoryRepositoryProvider)
          .deleteMany(removed.map((m) => m.id));
    }
    await ref.read(eventRepositoryProvider).log(
          userId,
          'Removed ${card.def.name}, forgot ${removed.length}.',
        );
    ref.invalidate(logProvider);
    await ref.read(grantsProvider.notifier).reload();
    await ref.read(memoriesProvider.notifier).reload();

    final name = removed.length == 1 ? 'memory' : 'memories';
    ref.read(shellProvider.notifier).showToast(
          'Removed ${card.def.name}, forgot ${removed.length} $name',
          undo: removed,
        );
  }
}

final NotifierProvider<SourcesViewModel, SourcesUiState> sourcesProvider =
    NotifierProvider<SourcesViewModel, SourcesUiState>(SourcesViewModel.new);

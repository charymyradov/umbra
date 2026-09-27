import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/providers/data_providers.dart';
import 'shell_controller.dart';

class MemoryScreenState {
  const MemoryScreenState({
    this.query = '',
    this.filter,
    this.openLayers = const {},
    this.addFor,
    this.addText = '',
  });

  final String query;
  final MemoryLayer? filter;
  final Set<MemoryLayer> openLayers;
  final MemoryLayer? addFor;
  final String addText;

  bool get adding => addFor != null;
  bool get canSaveAdd => addText.trim().isNotEmpty;

  MemoryScreenState copyWith({
    String? query,
    MemoryLayer? Function()? filter,
    Set<MemoryLayer>? openLayers,
    MemoryLayer? Function()? addFor,
    String? addText,
  }) {
    return MemoryScreenState(
      query: query ?? this.query,
      filter: filter != null ? filter() : this.filter,
      openLayers: openLayers ?? this.openLayers,
      addFor: addFor != null ? addFor() : this.addFor,
      addText: addText ?? this.addText,
    );
  }
}

/// Hafıza sekmesi: arama, katman filtresi, akordeonlar ve elle ekleme.
class MemoryScreenController extends Notifier<MemoryScreenState> {
  @override
  MemoryScreenState build() => const MemoryScreenState();

  void setQuery(String v) => state = state.copyWith(query: v);

  void toggleFilter(MemoryLayer layer) {
    final isActive = state.filter == layer;
    state = state.copyWith(
      filter: () => isActive ? null : layer,
      openLayers: {...state.openLayers, layer},
    );
  }

  void toggleOpen(MemoryLayer layer) {
    final next = {...state.openLayers};
    if (!next.remove(layer)) next.add(layer);
    state = state.copyWith(
      openLayers: next,
      addFor: () => state.addFor == layer ? null : state.addFor,
    );
  }

  void startAdd(MemoryLayer layer) {
    state = state.copyWith(addFor: () => layer, addText: '');
  }

  void cancelAdd() {
    state = state.copyWith(addFor: () => null, addText: '');
  }

  void setAddText(String v) => state = state.copyWith(addText: v);

  Future<void> saveAdd() async {
    final userId = ref.read(currentUserIdProvider);
    final layer = state.addFor;
    final text = state.addText.trim();
    if (userId == null || layer == null || text.isEmpty) return;

    final now = DateTime.now();
    final memory = Memory(
      userId: userId,
      layer: layer,
      statement: text,
      source: MemorySource.explicit,
      detail: 'Added in Memory, ${fmtDate(now)}',
      derivation: [
        'You added this in Memory: "$text"',
        'Saved directly — you said it.',
      ],
      confirmedAt: now,
      createdAt: now,
      expiresAt: layer == MemoryLayer.live
          ? now.add(
              Duration(
                days: ref.read(settingsProvider).value?.expiryDays ?? 7,
              ),
            )
          : null,
    );

    await ref.read(memoryRepositoryProvider).insert(memory);
    await ref.read(eventRepositoryProvider).log(userId, 'Added to ${layerOf(layer).name}: "$text"');
    ref.invalidate(logProvider);
    await ref.read(memoriesProvider.notifier).reload();

    state = state.copyWith(addFor: () => null, addText: '');
    _shell.showToast('Added to ${layerOf(layer).name}');
  }

  Future<void> clearLayer(MemoryLayer layer) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final removed = await ref
        .read(memoryRepositoryProvider)
        .deleteByLayer(userId: userId, layer: layer);
    if (removed.isEmpty) return;

    await ref.read(eventRepositoryProvider).log(
          userId,
          'Forgot all ${layerOf(layer).name.toLowerCase()}',
        );
    ref.invalidate(logProvider);
    await ref.read(memoriesProvider.notifier).reload();
    _shell.showToast(
      'Forgot all ${layerOf(layer).name.toLowerCase()}',
      undo: removed,
    );
  }

  ShellController get _shell => ref.read(shellProvider.notifier);
}

final NotifierProvider<MemoryScreenController, MemoryScreenState>
    memoryScreenProvider =
    NotifierProvider<MemoryScreenController, MemoryScreenState>(
  MemoryScreenController.new,
);

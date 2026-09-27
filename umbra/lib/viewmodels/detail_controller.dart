import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/providers/data_providers.dart';
import 'shell_controller.dart';

enum DetailStage { none, edit, review }

class DetailState {
  const DetailState({
    this.memoryId,
    this.stage = DetailStage.none,
    this.editText = '',
  });

  final String? memoryId;
  final DetailStage stage;
  final String editText;

  bool get isEditing => stage == DetailStage.edit;
  bool get isReviewing => stage == DetailStage.review;
  bool get isIdle => stage == DetailStage.none;

  DetailState copyWith({
    String? Function()? memoryId,
    DetailStage? stage,
    String? editText,
  }) {
    return DetailState(
      memoryId: memoryId != null ? memoryId() : this.memoryId,
      stage: stage ?? this.stage,
      editText: editText ?? this.editText,
    );
  }
}

/// Hafıza detay sayfası: seçim, düzenleme ve kimlik onay akışı.
class DetailController extends Notifier<DetailState> {
  @override
  DetailState build() => const DetailState();

  ShellController get _shell => ref.read(shellProvider.notifier);

  Memory? _memory(String? id) {
    if (id == null) return null;
    final all = ref.read(memoriesProvider).value ?? const <Memory>[];
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  void open(String id) {
    state = DetailState(memoryId: id);
    _shell.openMemory(id);
  }

  void close() {
    state = const DetailState();
    _shell.closeMemory();
  }

  void startEdit() {
    final m = _memory(state.memoryId);
    if (m == null) return;
    state = state.copyWith(stage: DetailStage.edit, editText: m.statement);
  }

  void setEditText(String v) => state = state.copyWith(editText: v);

  void cancelEdit() => state = state.copyWith(stage: DetailStage.none);

  /// Identity katmanında önce "önce/sonra" onay adımı gösterilir.
  void primary() {
    final m = _memory(state.memoryId);
    if (m == null) return;
    if (m.layer == MemoryLayer.identity) {
      if (state.editText.trim().isEmpty) return;
      state = state.copyWith(stage: DetailStage.review);
    } else {
      _save();
    }
  }

  Future<void> confirmIdentity() => _save();

  Future<void> _save() async {
    final m = _memory(state.memoryId);
    final text = state.editText.trim();
    if (m == null || text.isEmpty) return;

    final now = DateTime.now();
    final derivation = [
      ...m.derivation,
      'You edited this (was "${m.statement}").',
    ];
    await ref.read(memoryRepositoryProvider).updateStatement(
          id: m.id,
          statement: text,
          derivation: derivation,
          confirmedAt: m.confirmedAt != null ? now : null,
        );
    await _log('Edited "${m.statement}" → "$text"');
    await ref.read(memoriesProvider.notifier).reload();
    state = state.copyWith(stage: DetailStage.none, editText: text);
    _shell.showToast('Updated');
  }

  Future<void> forget() async {
    final m = _memory(state.memoryId);
    if (m == null) return;
    await ref.read(memoryRepositoryProvider).delete(m.id);
    await _log('Deleted "${m.statement}"');
    await ref.read(memoriesProvider.notifier).reload();
    state = const DetailState();
    _shell.closeMemory();
    _shell.showToast('Forgot "${clip(m.statement, 30)}"', undo: [m]);
  }

  Future<void> reconfirm() async {
    final m = _memory(state.memoryId);
    if (m == null) return;
    await _reconfirmMemory(m);
  }

  /// Kart üzerindeki "Yes" tuşu — kimlik onay sayfası açılmadan.
  Future<void> reconfirmById(String id) async {
    final m = _memory(id);
    if (m == null) return;
    await _reconfirmMemory(m);
  }

  /// Liste satırındaki kalem tuşu — detay sayfasını düzenleme modunda açar.
  void openEdit(String id) {
    open(id);
    startEdit();
  }

  Future<void> _reconfirmMemory(Memory m) async {
    final now = DateTime.now();
    final derivation = [
      ...m.derivation,
      'Re-confirmed on ${fmtDate(now)}.',
    ];
    await ref.read(memoryRepositoryProvider).reconfirm(
          id: m.id,
          derivation: derivation,
        );
    await _log('Re-confirmed "${m.statement}"');
    await ref.read(memoriesProvider.notifier).reload();
    _shell.showToast('Marked still true');
  }

  /// Kart üzerindeki "No" tuşu — hafızayı siler.
  Future<void> forgetById(String id) async {
    final all = ref.read(memoriesProvider).value ?? const <Memory>[];
    Memory? target;
    for (final m in all) {
      if (m.id == id) target = m;
    }
    if (target == null) return;
    await ref.read(memoryRepositoryProvider).delete(id);
    await _log('Deleted "${target.statement}"');
    await ref.read(memoriesProvider.notifier).reload();
    _shell.showToast('Forgot "${clip(target.statement, 30)}"', undo: [target]);
  }

  Future<void> undoDelete(List<Memory> memories) async {
    await ref.read(memoryRepositoryProvider).insertMany(memories);
    await ref.read(memoriesProvider.notifier).reload();
    _shell.hideToast();
  }

  Future<void> _log(String text) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(eventRepositoryProvider).log(userId, text);
    ref.invalidate(logProvider);
  }
}

final NotifierProvider<DetailController, DetailState> detailProvider =
    NotifierProvider<DetailController, DetailState>(DetailController.new);

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/memory.dart';

enum AppTab { today, memory, sources, privacy }

enum AppOverlay { none, tell, memoryDetail }

class ToastData {
  const ToastData(this.message, {this.undo});

  final String message;

  /// Geri alınacak silinmiş hafızalar.
  final List<Memory>? undo;

  bool get canUndo => undo != null && undo!.isNotEmpty;
}

class ShellState {
  const ShellState({
    this.tab = AppTab.today,
    this.overlay = AppOverlay.none,
    this.selectedMemoryId,
    this.toast,
    this.pendingBadge = true,
  });

  final AppTab tab;
  final AppOverlay overlay;
  final String? selectedMemoryId;
  final ToastData? toast;
  final bool pendingBadge;

  ShellState copyWith({
    AppTab? tab,
    AppOverlay? overlay,
    String? Function()? selectedMemoryId,
    ToastData? Function()? toast,
    bool? pendingBadge,
  }) {
    return ShellState(
      tab: tab ?? this.tab,
      overlay: overlay ?? this.overlay,
      selectedMemoryId: selectedMemoryId != null
          ? selectedMemoryId()
          : this.selectedMemoryId,
      toast: toast != null ? toast() : this.toast,
      pendingBadge: pendingBadge ?? this.pendingBadge,
    );
  }
}

/// Uygulama kabuğu: sekme, alt sayfa örtüsü ve bildirim (toast) durumu.
class ShellController extends Notifier<ShellState> {
  Timer? _toastTimer;

  @override
  ShellState build() {
    ref.onDispose(() => _toastTimer?.cancel());
    return const ShellState();
  }

  void goTab(AppTab tab) {
    state = state.copyWith(tab: tab, overlay: AppOverlay.none);
  }

  void openTell() => state = state.copyWith(overlay: AppOverlay.tell);

  void closeOverlay() => state = state.copyWith(overlay: AppOverlay.none);

  void openMemory(String id) {
    state = state.copyWith(
      overlay: AppOverlay.memoryDetail,
      selectedMemoryId: () => id,
    );
  }

  void closeMemory() {
    state = state.copyWith(
      overlay: AppOverlay.none,
      selectedMemoryId: () => null,
    );
  }

  void setPendingBadge(bool value) {
    state = state.copyWith(pendingBadge: value);
  }

  void showToast(String message, {List<Memory>? undo}) {
    _toastTimer?.cancel();
    state = state.copyWith(
      toast: () => ToastData(message, undo: undo),
    );
    _toastTimer = Timer(const Duration(seconds: 4), hideToast);
  }

  void hideToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    state = state.copyWith(toast: () => null);
  }
}

final NotifierProvider<ShellController, ShellState> shellProvider =
    NotifierProvider<ShellController, ShellState>(ShellController.new);

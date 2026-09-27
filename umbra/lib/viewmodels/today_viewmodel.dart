import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/app_grant.dart';
import '../data/models/app_settings.dart';
import '../data/models/memory.dart';
import '../data/models/proposal.dart';
import '../data/providers/data_providers.dart';
import 'presentation.dart';
import 'rules.dart';
import 'today_controller.dart';

class TodayUiState {
  const TodayUiState({
    required this.loading,
    required this.dateLabel,
    required this.firstName,
    required this.initial,
    this.hero,
    this.more = const [],
    this.pending,
    this.pendingTotal = 0,
    this.pendingIndex = 0,
    this.editingProposalId,
    this.editText = '',
    this.openWhy = false,
  });

  final bool loading;
  final String dateLabel;
  final String firstName;
  final String initial;
  final SuggestionView? hero;
  final List<SuggestionView> more;
  final PendingView? pending;
  final int pendingTotal;
  final int pendingIndex;
  final String? editingProposalId;
  final String editText;
  final bool openWhy;

  bool get hasHero => hero != null;
  bool get planEmpty => hero == null;
  bool get hasMore => more.isNotEmpty;
  bool get hasPending => pending != null;
  bool get pendingMany => pendingTotal > 1;

  String get pendingPos =>
      pendingTotal > 1 ? '${pendingIndex + 1} of $pendingTotal' : '';
}

/// Bugün sekmesinin ekran durumu — hafıza, ayar, izin ve önerilerden türetilir.
class TodayViewModel extends Notifier<TodayUiState> {
  @override
  TodayUiState build() {
    final ctrl = ref.watch(todayProvider);
    final memoriesAsync = ref.watch(memoriesProvider);
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final grants = ref.watch(grantsProvider).value ?? const <AppGrant>[];
    final proposals =
        ref.watch(proposalsProvider).value ?? const <Proposal>[];
    final profile = ref.watch(profileProvider).value;

    final memories = memoriesAsync.value ?? const <Memory>[];
    final suggestions = buildSuggestions(memories, settings);

    SuggestionView? hero;
    if (suggestions.isNotEmpty) {
      final focusId = ctrl.focusId;
      hero = suggestions.first;
      if (focusId != null) {
        for (final s in suggestions) {
          if (s.id == focusId) hero = s;
        }
      }
    }
    final more = [
      for (final s in suggestions)
        if (s.id != hero?.id) s,
    ];

    final allowed = [
      for (final p in proposals)
        if (isProposalAllowed(
          source: p.source,
          connection: p.connection,
          settings: settings,
          grants: grants,
        ))
          PendingView(p),
    ];
    final total = allowed.length;
    PendingView? pending;
    if (total > 0) {
      pending = allowed[ctrl.pendingIndex % total];
    }

    final now = DateTime.now();
    return TodayUiState(
      loading:
          memoriesAsync.isLoading && memoriesAsync.value == null,
      dateLabel: fmtTodayHeader(now),
      firstName: profile?.firstName ?? 'there',
      initial: profile?.initial ?? 'U',
      hero: hero,
      more: more,
      pending: pending,
      pendingTotal: total,
      pendingIndex: total == 0 ? 0 : ctrl.pendingIndex % total,
      editingProposalId: ctrl.editingProposalId,
      editText: ctrl.editText,
      openWhy: ctrl.openWhy,
    );
  }

  TodayController get _ctrl => ref.read(todayProvider.notifier);

  void focus(String id) => _ctrl.focus(id);
  void toggleWhy() => _ctrl.toggleWhy();
  void nextPending() => _ctrl.nextPending();

  void startEditProposal(String id, String text) =>
      _ctrl.startEditProposal(id, text);

  void cancelEditProposal() => _ctrl.cancelEditProposal();

  void setEditProposalText(String v) => _ctrl.setEditText(v);

  Future<void> skipSuggestion(String id, String title) =>
      _ctrl.skipSuggestion(id, title);

  Future<void> startSuggestion({
    required String id,
    required String title,
    required bool canAskMorning,
  }) =>
      _ctrl.startSuggestion(
        id: id,
        title: title,
        canAskMorning: canAskMorning,
      );

  Future<void> keepPending(Proposal p, {String? editedText}) =>
      _ctrl.keepProposal(p, editedText: editedText);

  Future<void> rejectPending(Proposal p) => _ctrl.rejectProposal(p);
}

final NotifierProvider<TodayViewModel, TodayUiState> todayUiProvider =
    NotifierProvider<TodayViewModel, TodayUiState>(TodayViewModel.new);

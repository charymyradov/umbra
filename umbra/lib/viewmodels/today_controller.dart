import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/models/proposal.dart';
import '../data/providers/data_providers.dart';
import 'shell_controller.dart';

class TodayState {
  const TodayState({
    this.focusId,
    this.openWhy = false,
    this.pendingIndex = 0,
    this.editingProposalId,
    this.editText = '',
  });

  final String? focusId;
  final bool openWhy;
  final int pendingIndex;
  final String? editingProposalId;
  final String editText;

  TodayState copyWith({
    String? Function()? focusId,
    bool? openWhy,
    int? pendingIndex,
    String? Function()? editingProposalId,
    String? editText,
  }) {
    return TodayState(
      focusId: focusId != null ? focusId() : this.focusId,
      openWhy: openWhy ?? this.openWhy,
      pendingIndex: pendingIndex ?? this.pendingIndex,
      editingProposalId: editingProposalId != null
          ? editingProposalId()
          : this.editingProposalId,
      editText: editText ?? this.editText,
    );
  }
}

/// Bugün sekmesi: öneriler, "To review" kartları ve sohbet kökenli sinyaller.
class TodayController extends Notifier<TodayState> {
  @override
  TodayState build() => const TodayState();

  ShellController get _shell => ref.read(shellProvider.notifier);

  AppSettings _settings() =>
      ref.read(settingsProvider).value ?? const AppSettings();

  Future<void> _saveSettings(AppSettings next) =>
      ref.read(settingsProvider.notifier).save(next);

  Future<void> _log(String text) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(eventRepositoryProvider).log(userId, text);
    ref.invalidate(logProvider);
  }

  void focus(String id) {
    state = state.copyWith(focusId: () => id, openWhy: false);
  }

  void toggleWhy() => state = state.copyWith(openWhy: !state.openWhy);

  void nextPending() {
    state = state.copyWith(
      pendingIndex: state.pendingIndex + 1,
      editingProposalId: () => null,
    );
  }

  void startEditProposal(String id, String text) {
    state = state.copyWith(
      editingProposalId: () => id,
      editText: text,
    );
  }

  void cancelEditProposal() {
    state = state.copyWith(editingProposalId: () => null);
  }

  void setEditText(String v) => state = state.copyWith(editText: v);

  // -----------------------------------------------------------------------
  // Öneri kartları
  // -----------------------------------------------------------------------

  Future<void> skipSuggestion(String id, String title) async {
    final current = _settings();
    await _saveSettings(current.withSuggestion(id, 'hidden'));
    state = state.copyWith(openWhy: false, focusId: () => null);
    await _log('"Not now" on $title.');
    _shell.showToast('Removed from today');
  }

  Future<void> startSuggestion({
    required String id,
    required String title,
    required bool canAskMorning,
  }) async {
    var current = _settings();
    await _saveSettings(current.withSuggestion(id, 'done'));
    state = state.copyWith(openWhy: false);
    await _log('Started $title.');

    if (canAskMorning && !current.morningAsked) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final now = DateTime.now();
        await ref.read(eventRepositoryProvider).addProposal(
          userId,
          Proposal(
            id: 'q_morning_${now.millisecondsSinceEpoch}',
            layer: MemoryLayer.pattern,
            statement: 'Mornings might work too.',
            prompt:
                'You started reading at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} — usually it’s evenings.',
            source: MemorySource.behavioral,
            confidence: 0.2,
            basis: '1 session',
            steps: ['You tapped Start on "$title".'],
            createdAt: now,
          ),
        );
        ref.invalidate(proposalsProvider);
        current = current.copyWith(morningAsked: true);
        await _saveSettings(current);
        _shell.showToast('Enjoy. I noticed something — see To review.');
        return;
      }
    }
    _shell.showToast('Enjoy your reading');
  }

  // -----------------------------------------------------------------------
  // To review kartları
  // -----------------------------------------------------------------------

  Future<void> keepProposal(Proposal p, {String? editedText}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final memoryRepo = ref.read(memoryRepositoryProvider);
    final eventRepo = ref.read(eventRepositoryProvider);
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();

    final text = (editedText ?? '').trim().isEmpty
        ? p.statement
        : editedText!.trim();
    final now = DateTime.now();
    final steps = <String>[
      ...p.steps,
      if (editedText != null && editedText.trim().isNotEmpty && editedText.trim() != p.statement)
        'You edited it to "$text".',
      'You tapped Keep on ${fmtDate(now)}.',
    ];

    final memory = Memory(
      userId: userId,
      layer: p.layer,
      statement: text,
      source: p.source,
      connection: p.connection,
      detail: p.prompt,
      derivation: steps,
      confidence: p.confidence,
      basis: p.basis,
      confirmedAt: now,
      createdAt: now,
      expiresAt: p.layer == MemoryLayer.live
          ? now.add(Duration(days: settings.expiryDays))
          : null,
    );

    await memoryRepo.insert(memory);
    await eventRepo.resolveProposal(userId, proposalId: p.id, action: 'keep');
    await eventRepo.log(userId, 'Kept "$text"');

    state = state.copyWith(
      editingProposalId: () => null,
      pendingIndex: 0,
    );
    ref.invalidate(proposalsProvider);
    ref.invalidate(logProvider);
    _shell.showToast('Saved to ${layerOf(p.layer).name}');
  }

  Future<void> rejectProposal(Proposal p) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(eventRepositoryProvider)
        .resolveProposal(userId, proposalId: p.id, action: 'reject');
    await ref
        .read(eventRepositoryProvider)
        .log(userId, 'Rejected "${p.statement}" — not stored.');
    state = state.copyWith(
      editingProposalId: () => null,
      pendingIndex: 0,
    );
    ref.invalidate(proposalsProvider);
    ref.invalidate(logProvider);
    _shell.showToast('Not stored');
  }
}

final NotifierProvider<TodayController, TodayState> todayProvider =
    NotifierProvider<TodayController, TodayState>(TodayController.new);

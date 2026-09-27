import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formats.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/models/memory.dart';
import '../data/models/memory_event.dart';
import '../data/models/proposal.dart';
import '../data/providers/data_providers.dart';
import 'shell_controller.dart';

class TellState {
  const TellState({
    this.mode = 'remember',
    this.text = '',
    this.layer = MemoryLayer.preference,
    this.chatInput = '',
  });

  final String mode;
  final String text;
  final MemoryLayer layer;
  final String chatInput;

  bool get isRemember => mode == 'remember';
  bool get isTalk => mode == 'talk';
  bool get canSave => text.trim().isNotEmpty;

  TellState copyWith({
    String? mode,
    String? text,
    MemoryLayer? layer,
    String? chatInput,
  }) {
    return TellState(
      mode: mode ?? this.mode,
      text: text ?? this.text,
      layer: layer ?? this.layer,
      chatInput: chatInput ?? this.chatInput,
    );
  }
}

/// "Tell me" alt sayfası: hatırlatma kaydı ve sohbet.
class TellController extends Notifier<TellState> {
  @override
  TellState build() => const TellState();

  ShellController get _shell => ref.read(shellProvider.notifier);

  void setMode(String mode) => state = state.copyWith(mode: mode);
  void setText(String v) => state = state.copyWith(text: v);
  void setLayer(MemoryLayer l) => state = state.copyWith(layer: l);
  void setChatInput(String v) => state = state.copyWith(chatInput: v);

  void seed(String value, {MemoryLayer? layer}) {
    state = state.copyWith(text: value, layer: layer ?? MemoryLayer.preference);
  }

  void reset() => state = const TellState();

  Future<void> save() async {
    final userId = ref.read(currentUserIdProvider);
    final text = state.text.trim();
    final layer = state.layer;
    if (userId == null || text.isEmpty) return;

    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    final now = DateTime.now();
    final memory = Memory(
      userId: userId,
      layer: layer,
      statement: text,
      source: MemorySource.explicit,
      detail: 'Tell me, ${fmtDate(now)}',
      derivation: [
        'You wrote: "$text"',
        'Saved directly — you said it.',
      ],
      confirmedAt: now,
      createdAt: now,
      expiresAt: layer == MemoryLayer.live
          ? now.add(Duration(days: settings.expiryDays))
          : null,
    );

    await ref.read(memoryRepositoryProvider).insert(memory);
    await ref.read(eventRepositoryProvider).log(userId, 'You told me "$text"');
    ref.invalidate(logProvider);
    await ref.read(memoriesProvider.notifier).reload();

    state = const TellState();
    _shell.closeOverlay();
    _shell.showToast('Saved to ${layerOf(layer).name}');
  }

  // ---------------------------------------------------------------------
  // Sohbet
  // ---------------------------------------------------------------------

  Future<void> send({String? override}) async {
    final userId = ref.read(currentUserIdProvider);
    final text = (override ?? state.chatInput).trim();
    if (userId == null || text.isEmpty) return;

    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    final eventRepo = ref.read(eventRepositoryProvider);
    final conversationalOn = settings.mechOn(MemorySource.conversational);

    Proposal? proposal;
    final minutes = RegExp(r'(\d+)\s*(min|minutes)', caseSensitive: false)
        .firstMatch(text);
    if (minutes != null) {
      proposal = Proposal(
        id: 'c_short_${DateTime.now().millisecondsSinceEpoch}',
        layer: MemoryLayer.live,
        statement: 'Only ~${minutes.group(1)} minutes today.',
        prompt: 'You said: "$text"',
        source: MemorySource.conversational,
        steps: [
          'You wrote: "$text"',
          'Umbra read it as something worth remembering.',
        ],
        createdAt: DateTime.now(),
      );
    } else if (RegExp(r'burn|tired|exhaust|break from',
            caseSensitive: false)
        .hasMatch(text)) {
      proposal = Proposal(
        id: 'c_break_${DateTime.now().millisecondsSinceEpoch}',
        layer: MemoryLayer.live,
        statement: 'A break from heavy nonfiction.',
        prompt: 'You said: "$text"',
        source: MemorySource.conversational,
        steps: [
          'You wrote: "$text"',
          'Umbra read it as something worth remembering.',
        ],
        createdAt: DateTime.now(),
      );
    } else if (RegExp(r'fiction|novel', caseSensitive: false).hasMatch(text)) {
      proposal = Proposal(
        id: 'c_fic_${DateTime.now().millisecondsSinceEpoch}',
        layer: MemoryLayer.preference,
        statement: 'More fiction lately.',
        prompt: 'You said: "$text"',
        source: MemorySource.conversational,
        steps: [
          'You wrote: "$text"',
          'Umbra read it as something worth remembering.',
        ],
        createdAt: DateTime.now(),
      );
    } else if (RegExp(r'learn|studying', caseSensitive: false).hasMatch(text)) {
      proposal = Proposal(
        id: 'c_learn_${DateTime.now().millisecondsSinceEpoch}',
        layer: MemoryLayer.preference,
        statement: 'Learning: $text',
        prompt: 'You said: "$text"',
        source: MemorySource.conversational,
        steps: [
          'You wrote: "$text"',
          'Umbra read it as something worth remembering.',
        ],
        createdAt: DateTime.now(),
      );
    }

    String reply;
    if (!conversationalOn) {
      reply = 'Got it. Conversation learning is off, so nothing is kept.';
    } else if (proposal == null) {
      reply = 'Thanks. Nothing to remember there.';
    } else if (minutes != null) {
      reply = 'Got it — I shortened tonight’s reading. '
          'There’s a card on Today if you want me to remember this.';
    } else {
      reply = 'Got it. There’s a card on Today if you want me to remember this.';
    }

    await eventRepo.addChat(userId, who: 'you', text: text);
    await eventRepo.addChat(userId, who: 'umbra', text: reply);
    ref.invalidate(chatProvider);

    if (proposal != null && conversationalOn) {
      await eventRepo.addProposal(userId, proposal);
      ref.invalidate(proposalsProvider);
    }

    state = state.copyWith(chatInput: '');
  }

  String layerNote(MemoryLayer layer) {
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    return switch (layer) {
      MemoryLayer.identity => 'Stable — edits need confirmation',
      MemoryLayer.preference =>
        "I'll check in after ${settings.staleAfterDays} days",
      MemoryLayer.live => 'Auto-deletes in ${settings.expiryDays} days',
      MemoryLayer.pattern => 'Saved as something you told me',
    };
  }
}

/// Sohbet balonu görünümü.
class ChatBubble {
  const ChatBubble({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

/// Sohbet geçmişini eski → yeni sıraya çevirir.
List<ChatBubble> buildChat(List<MemoryEvent> events) {
  final bubbles = <ChatBubble>[];
  for (final e in events) {
    final map = e.payload;
    final who = '${map['who'] ?? 'you'}';
    final text = '${map['text'] ?? ''}';
    if (text.isEmpty) continue;
    bubbles.add(ChatBubble(text: text, fromUser: who == 'you'));
  }
  return bubbles;
}

const List<String> kTellSeeds = [
  'Learning Portuguese',
  'One book at a time',
  'On holiday next week',
];

const List<String> kChatSeeds = [
  'Only 15 minutes today',
  'Burned out on nonfiction',
];

MemoryLayer tellSeedLayer(String seed) =>
    RegExp(r'holiday|week', caseSensitive: false).hasMatch(seed)
        ? MemoryLayer.live
        : MemoryLayer.preference;

final NotifierProvider<TellController, TellState> tellProvider =
    NotifierProvider<TellController, TellState>(TellController.new);

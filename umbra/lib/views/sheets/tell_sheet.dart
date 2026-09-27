import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/catalogs.dart';
import '../../data/models/enums.dart';
import '../../data/models/memory_event.dart';
import '../../data/providers/data_providers.dart';
import '../../viewmodels/shell_controller.dart';
import '../../viewmodels/tell_controller.dart';
import '../widgets/common.dart';

const List<MemoryLayer> kTellLayers = [
  MemoryLayer.identity,
  MemoryLayer.preference,
  MemoryLayer.live,
];

/// Alt sayfa: "Remember this" formu ve "Just talk" sohbeti.
class TellSheet extends ConsumerWidget {
  const TellSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tellProvider);
    final vm = ref.read(tellProvider.notifier);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => ref.read(shellProvider.notifier).closeOverlay(),
            child: ColoredBox(color: AppColors.shell.withValues(alpha: .4)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SegmentedRow(
                  items: [
                    (
                      'Remember this',
                      state.isRemember,
                      () => vm.setMode('remember'),
                    ),
                    ('Just talk', state.isTalk, () => vm.setMode('talk')),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.isRemember)
                  _RememberForm(state: state, vm: vm)
                else
                  _TalkPane(state: state, vm: vm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Remember this
// ---------------------------------------------------------------------------

class _RememberForm extends StatefulWidget {
  const _RememberForm({required this.state, required this.vm});

  final TellState state;
  final TellController vm;

  @override
  State<_RememberForm> createState() => _RememberFormState();
}

class _RememberFormState extends State<_RememberForm> {
  late final _textController = TextEditingController(text: widget.state.text);

  @override
  void didUpdateWidget(covariant _RememberForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncText(widget.state.text);
  }

  void _syncText(String text) {
    if (_textController.text == text) return;
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 3,
            minLines: 3,
            onChanged: vm.setText,
            style: AppTypography.serifStyle(size: 19),
            decoration: const InputDecoration(
              hintText: 'Something I should remember…',
              hintStyle: TextStyle(color: AppColors.faint),
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final seed in kTellSeeds) ...[
                _Chip(
                  label: seed,
                  onTap: () => vm.seed(seed, layer: tellSeedLayer(seed)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final l in kTellLayers) ...[
              Expanded(
                child: _LayerChoice(
                  def: layerOf(l),
                  selected: state.layer == l,
                  onTap: () => vm.setLayer(l),
                ),
              ),
              if (l != kTellLayers.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          vm.layerNote(state.layer),
          textAlign: TextAlign.center,
          style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
        ),
        const SizedBox(height: 12),
        UmbraButton(
          label: 'Save',
          height: 54,
          fontSize: 15,
          enabled: state.canSave,
          onTap: vm.save,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: AppTypography.sansStyle(size: 13, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

class _LayerChoice extends StatelessWidget {
  const _LayerChoice({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final LayerDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? def.bg : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? def.color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayerShape(def: def, size: 10),
              const SizedBox(height: 6),
              Text(
                def.name,
                style: AppTypography.sansStyle(size: 13, color: def.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Just talk
// ---------------------------------------------------------------------------

class _TalkPane extends ConsumerStatefulWidget {
  const _TalkPane({required this.state, required this.vm});

  final TellState state;
  final TellController vm;

  @override
  ConsumerState<_TalkPane> createState() => _TalkPaneState();
}

class _TalkPaneState extends ConsumerState<_TalkPane> {
  late final _textController = TextEditingController(
    text: widget.state.chatInput,
  );

  @override
  void didUpdateWidget(covariant _TalkPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncText(widget.state.chatInput);
  }

  void _syncText(String text) {
    if (_textController.text == text) return;
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final events = ref.watch(chatProvider).value ?? const <MemoryEvent>[];
    final bubbles = buildChat(events);
    final empty = bubbles.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (empty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "How's your day looking?",
                    textAlign: TextAlign.center,
                    style: AppTypography.serifStyle(
                      size: 19,
                      italic: true,
                      color: AppColors.faint,
                    ),
                  ),
                )
              else
                for (final b in bubbles)
                  Align(
                    alignment: b.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * .82 - 40,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: b.fromUser ? AppColors.ink : AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        b.text,
                        style: AppTypography.sansStyle(
                          size: 14,
                          height: 1.45,
                          color: b.fromUser ? AppColors.onDark : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        if (empty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final seed in kChatSeeds) ...[
                  _Chip(
                    label: seed,
                    onTap: () => vm.send(override: seed),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  onChanged: vm.setChatInput,
                  onSubmitted: (_) => vm.send(),
                  style: AppTypography.sansStyle(size: 15),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: AppColors.faint),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => vm.send(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: AppColors.onDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "I'll ask before keeping anything.",
          textAlign: TextAlign.center,
          style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/enums.dart';
import '../../data/providers/data_providers.dart';
import '../../viewmodels/detail_controller.dart';
import '../../viewmodels/presentation.dart';
import '../../viewmodels/shell_controller.dart';
import '../../viewmodels/today_viewmodel.dart';
import '../widgets/common.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(todayUiProvider);
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          _Header(ui: ui),
          const SizedBox(height: 30),
          if (ui.hasHero) _HeroCard(ui: ui, settings: settings),
          if (ui.planEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EmptyBox(
                title: 'Nothing to suggest yet',
                actionLabel: "Tell me what you're reading",
                onAction: () =>
                    ref.read(shellProvider.notifier).openTell(),
              ),
            ),
          ],
          if (ui.hasMore) _UpNext(ui: ui),
          if (ui.hasPending) _PendingCard(ui: ui),
          if (!ui.hasHero && !ui.hasPending) const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.ui});

  final TodayUiState ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ui.dateLabel.toUpperCase(),
                  style: AppTypography.sansStyle(
                    size: 12,
                    color: AppColors.faint,
                    letterSpacing: .08,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, ${ui.firstName}',
                  style: AppTypography.serifStyle(size: 32, height: 1.05),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(shellProvider.notifier).goTab(AppTab.memory),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                ui.initial,
                style: AppTypography.serifStyle(size: 19, color: AppColors.onDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero kartı
// ---------------------------------------------------------------------------

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.ui, required this.settings});

  final TodayUiState ui;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ui.hero!;
    final vm = ref.read(todayUiProvider.notifier);
    final canAskMorning = settings.mechOn(MemorySource.behavioral);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D2B2620),
            blurRadius: 30,
            offset: Offset(0, 12),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverTile(
                bg: hero.cbg,
                fg: hero.cfg,
                kind: hero.kind,
                title: hero.title,
                author: hero.author,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hero.when.toUpperCase(),
                        style: AppTypography.sansStyle(
                          size: 12,
                          color: AppColors.faint,
                          letterSpacing: .06,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hero.title,
                        style: AppTypography.serifStyle(size: 22, height: 1.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hero.sub,
                        style:
                            AppTypography.sansStyle(size: 13, color: AppColors.muted),
                      ),
                      if (hero.hasProg) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 4,
                                  child: Stack(
                                    children: [
                                      const ColoredBox(color: AppColors.lineSoft),
                                      FractionallySizedBox(
                                        widthFactor: _progFraction(hero.prog),
                                        child: const ColoredBox(color: AppColors.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hero.prog ?? '',
                              style: AppTypography.sansStyle(
                                  size: 11, color: AppColors.faint),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Pill(
                        label: hero.pill,
                        bg: hero.pillBg,
                        fg: hero.pillFg,
                        border: hero.pillBorder,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hero.done) ...[
            const SizedBox(height: 18),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.goodBg,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.good),
                  const SizedBox(width: 8),
                  Text('Reading',
                      style: AppTypography.sansStyle(
                          size: 15, color: AppColors.good)),
                ],
              ),
            ),
          ],
          if (hero.active) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: UmbraButton(
                    label: 'Start reading',
                    height: 52,
                    fontSize: 15,
                    onTap: () => vm.startSuggestion(
                      id: hero.id,
                      title: hero.title,
                      canAskMorning: canAskMorning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SquareButton(
                  icon: Icons.close,
                  onTap: () => vm.skipSuggestion(hero.id, hero.title),
                ),
                const SizedBox(width: 8),
                _SquareButton(
                  border: ui.openWhy ? AppColors.ink : AppColors.line,
                  background: ui.openWhy ? AppColors.ink : Colors.transparent,
                  onTap: vm.toggleWhy,
                  child: Text(
                    '?',
                    style: AppTypography.serifStyle(
                      size: 20,
                      color: ui.openWhy ? AppColors.onDark : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (ui.openWhy && hero.active) ...[
            const SizedBox(height: 14),
            Text(
              hero.basisText,
              style: AppTypography.sansStyle(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            for (final b in hero.basis) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                decoration: BoxDecoration(
                  color: b.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: b.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => ref.read(detailProvider.notifier).open(b.memoryId),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          b.text,
                          style: AppTypography.sansStyle(size: 13, height: 1.35),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(detailProvider.notifier).forgetById(b.memoryId),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(
                        'Not true',
                        style: AppTypography.sansStyle(
                            size: 12, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static double _progFraction(String? prog) {
    if (prog == null) return 0;
    final n = double.tryParse(prog.replaceAll('%', ''));
    if (n == null) return 0;
    return (n / 100).clamp(0, 1);
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    this.icon,
    this.child,
    required this.onTap,
    this.border = AppColors.line,
    this.background = Colors.transparent,
  });

  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  final Color border;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border),
        borderRadius: BorderRadius.circular(26),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: child ??
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.muted,
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Up next
// ---------------------------------------------------------------------------

class _UpNext extends StatelessWidget {
  const _UpNext({required this.ui});

  final TodayUiState ui;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text('Up next', style: AppTypography.serifStyle(size: 21)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: ui.more.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = ui.more[i];
              return _MoreCard(suggestion: s);
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              _Legend(color: AppColors.ink, filled: true, label: 'You told me'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.faint, filled: false, label: 'Inferred'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreCard extends ConsumerWidget {
  const _MoreCard({required this.suggestion});

  final SuggestionView suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(todayUiProvider.notifier).focus(suggestion.id),
            child: CoverTile(
              bg: suggestion.cbg,
              fg: suggestion.cfg,
              kind: suggestion.kind,
              title: suggestion.title,
              width: 128,
              height: 176,
              titleSize: 18,
              footerWidget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    suggestion.mins,
                    style: AppTypography.sansStyle(
                        size: 10, color: suggestion.cfg.withValues(alpha: .85)),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: suggestion.cfg, width: 1.5),
                      shape: BoxShape.circle,
                      color: suggestion.dotFill,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            suggestion.when,
            style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.filled,
    required this.label,
  });

  final Color color;
  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: filled ? null : Border.all(color: color, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTypography.sansStyle(size: 11, color: AppColors.faint)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// To review
// ---------------------------------------------------------------------------

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.ui});

  final TodayUiState ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ui.pending!;
    final vm = ref.read(todayUiProvider.notifier);
    final editing = ui.editingProposalId == pending.proposal.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('To review',
                        style: AppTypography.serifStyle(size: 21)),
                    if (ui.pendingPos.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(ui.pendingPos,
                          style: AppTypography.sansStyle(
                              size: 13, color: AppColors.faint)),
                    ],
                  ],
                ),
              ),
              if (ui.pendingMany)
                TextButton(
                  onPressed: vm.nextPending,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text('Next',
                      style: AppTypography.sansStyle(
                          size: 13, color: AppColors.muted)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x592B2620),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pending.srcBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pending.glyph,
                        style: AppTypography.serifStyle(
                            size: 15, color: AppColors.card),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pending.srcLine,
                        style: AppTypography.sansStyle(
                            size: 12, color: AppColors.faint),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warnBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Not saved',
                          style: AppTypography.sansStyle(
                              size: 11, color: AppColors.warn)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  pending.prompt,
                  style: AppTypography.sansStyle(
                      size: 14, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pending.layer.bg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Remember as ${pending.layer.name.toLowerCase()}'
                                  .toUpperCase(),
                              style: AppTypography.sansStyle(
                                size: 11,
                                color: pending.layer.color,
                                letterSpacing: .06,
                              ),
                            ),
                          ),
                          if (pending.isPattern)
                            ConfidenceDots(values: pending.dots)
                          else if (pending.isLive)
                            Text(
                              'Expires in ${settingsOf(ref).expiryDays}d',
                              style: AppTypography.sansStyle(
                                  size: 11, color: AppColors.good),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!editing)
                        Text(
                          pending.text,
                          style: AppTypography.serifStyle(size: 19, height: 1.25),
                        )
                      else
                        _TextArea(
                          initial: ui.editText,
                          onChanged: (v) => ref
                              .read(todayUiProvider.notifier)
                              .setEditProposalText(v),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!editing)
                  Row(
                    children: [
                      Expanded(
                        child: UmbraButton(
                          label: 'Keep',
                          height: 48,
                          onTap: () => vm.keepPending(pending.proposal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: UmbraButton(
                          label: 'Not true',
                          height: 48,
                          filled: false,
                          onTap: () => vm.rejectPending(pending.proposal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SquareButton(
                        icon: Icons.edit_outlined,
                        onTap: () => vm.startEditProposal(
                          pending.proposal.id,
                          pending.text,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: UmbraButton(
                          label: 'Keep edited',
                          height: 48,
                          enabled: ui.editText.trim().isNotEmpty,
                          onTap: () => vm.keepPending(
                            pending.proposal,
                            editedText: ui.editText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: vm.cancelEditProposal,
                        child: Text('Cancel',
                            style: AppTypography.sansStyle(
                                size: 14, color: AppColors.muted)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

AppSettings settingsOf(WidgetRef ref) =>
    ref.watch(settingsProvider).value ?? const AppSettings();

/// Metin alanı — dışarıdan gelen değeri senkron tutar.
class _TextArea extends StatefulWidget {
  const _TextArea({required this.initial, required this.onChanged}) : maxLines = 2;

  final String initial;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<_TextArea> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.selection = TextSelection.collapsed(
        offset: widget.initial.length,
      );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        minLines: widget.maxLines,
        onChanged: widget.onChanged,
        style: AppTypography.serifStyle(size: 17),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(10),
          isDense: true,
        ),
      ),
    );
  }
}

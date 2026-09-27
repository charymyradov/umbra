import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/catalogs.dart';
import '../../data/models/enums.dart';
import '../../viewmodels/onboarding_controller.dart';
import '../widgets/common.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                if (state.canBack)
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: vm.back,
                  )
                else
                  const SizedBox(width: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: i <= state.step
                                  ? AppColors.ink
                                  : AppColors.line,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: switch (state.step) {
              0 => const _StepWelcome(),
              1 => const _StepIdentity(),
              2 => const _StepInterests(),
              3 => const _StepRhythm(),
              _ => const _StepLearning(),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
          child: UmbraButton(
            label: state.saving ? '...' : state.nextLabel,
            onTap: state.saving ? () {} : vm.next,
            height: 58,
            fontSize: 16,
            enabled: state.canAdvance && !state.saving,
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: AppTypography.sansStyle(size: 13, color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 0 — Karşılama
// ---------------------------------------------------------------------------

class _StepWelcome extends StatelessWidget {
  const _StepWelcome();

  static const _features = [
    (Icons.remove_red_eye_outlined, 'See all of it'),
    (Icons.check_circle_outline, 'Approve what I infer'),
    (Icons.file_download_outlined, 'Export or delete anytime'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 36),
        const _WelcomeMark(),
        const SizedBox(height: 36),
        Text('Umbra', style: AppTypography.serifStyle(size: 44, height: 1)),
        const SizedBox(height: 14),
        Text(
          'Your reading companion, with a memory you can see.',
          style: AppTypography.serifStyle(
            size: 22,
            italic: true,
            color: AppColors.muted,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            for (final (icon, label) in _features)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minHeight: 112),
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 22, color: AppColors.ink),
                      const SizedBox(height: 18),
                      Text(
                        label,
                        style: AppTypography.sansStyle(size: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: -12,
            child: Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1 — Kimlik
// ---------------------------------------------------------------------------

class _StepIdentity extends ConsumerWidget {
  const _StepIdentity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'First, who are you?',
          style: AppTypography.serifStyle(size: 34, height: 1.1),
        ),
        const SizedBox(height: 24),
        _LargeField(hint: 'Name', value: state.name, onChanged: vm.setName),
        const SizedBox(height: 12),
        _LargeField(
          hint: 'What you do',
          value: state.role,
          onChanged: vm.setRole,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Saved to Identity',
              style: AppTypography.sansStyle(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _LargeField extends StatefulWidget {
  const _LargeField({
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_LargeField> createState() => _LargeFieldState();
}

class _LargeFieldState extends State<_LargeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _LargeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: widget.value.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        cursorColor: AppColors.ink,
        style: AppTypography.sansStyle(size: 18),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.sansStyle(size: 18, color: AppColors.faint),
          filled: false,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 19,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 — İlgi alanları
// ---------------------------------------------------------------------------

class _StepInterests extends ConsumerWidget {
  const _StepInterests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What pulls you in?',
          style: AppTypography.serifStyle(size: 34, height: 1.1),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 10.0;
            final w = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (label, bg, fg) in kTopics)
                  _TopicTile(
                    width: w,
                    label: label,
                    bg: bg,
                    fg: fg,
                    selected: state.topics.contains(label),
                    onTap: () => vm.toggleTopic(label),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        Text(
          'Goals',
          style: AppTypography.sansStyle(size: 13, color: AppColors.faint),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in kGoals)
              _SelectChip(
                label: g,
                selected: state.goals.contains(g),
                onTap: () => vm.toggleGoal(g),
              ),
          ],
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.width,
    required this.label,
    required this.bg,
    required this.fg,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final Color bg;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: selected ? 1 : .42,
          child: Container(
            width: width,
            height: 92,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.bottomLeft,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    style: AppTypography.serifStyle(
                      size: 19,
                      color: fg,
                      height: 1.1,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(right: 0, top: -2, child: _CheckBadge()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 13, color: AppColors.ink, weight: 3),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.sansStyle(
              size: 14,
              color: selected ? AppColors.onDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 — Ritim
// ---------------------------------------------------------------------------

class _StepRhythm extends ConsumerWidget {
  const _StepRhythm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you read?',
          style: AppTypography.serifStyle(size: 34, height: 1.1),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            for (final (label, sun) in kTimes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _TimeTile(
                    label: label,
                    sun: sun,
                    selected: state.times.contains(label),
                    onTap: () => vm.toggleTime(label),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'A good session',
          style: AppTypography.sansStyle(size: 13, color: AppColors.faint),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lineSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = kSessionLengths.length;
                final segW = constraints.maxWidth / count;
                final found = kSessionLengths.indexOf(state.sessionLength);
                final index = found < 0 ? 0 : found;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: index * segW + 2,
                      top: 0,
                      width: segW - 4,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F2B2620),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (final len in kSessionLengths)
                            Expanded(
                              child: _LengthButton(
                                label: len,
                                onTap: () => vm.setSessionLength(len),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Formats',
          style: AppTypography.sansStyle(size: 13, color: AppColors.faint),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final f in kFormats)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SelectChip(
                    label: f,
                    selected: state.formats.contains(f),
                    onTap: () => vm.toggleFormat(f),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.sun,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color sun;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 96,
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected ? null : Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: sun, shape: BoxShape.circle),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AppTypography.sansStyle(
                  size: 11,
                  color: selected ? AppColors.onDark : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LengthButton extends StatelessWidget {
  const _LengthButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(label, style: AppTypography.serifStyle(size: 22)),
            const SizedBox(width: 3),
            Text(
              'min',
              style: AppTypography.sansStyle(
                size: 12,
                color: AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 — Öğrenme mekanizmaları
// ---------------------------------------------------------------------------

class _StepLearning extends ConsumerWidget {
  const _StepLearning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How may I learn?',
          style: AppTypography.serifStyle(size: 34, height: 1.1),
        ),
        const SizedBox(height: 10),
        Text(
          'Anything I notice waits for your OK.',
          style: AppTypography.sansStyle(
            size: 15,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        for (final s in kSourceOrder) ...[
          MechRow(
            source: s,
            on: state.mech[s] ?? true,
            onToggle: () => vm.toggleMech(s),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class MechRow extends StatelessWidget {
  const MechRow({
    super.key,
    required this.source,
    required this.on,
    required this.onToggle,
    this.count,
    this.rule,
    this.onForget,
  });

  final MemorySource source;
  final bool on;
  final VoidCallback onToggle;
  final int? count;
  final String? rule;
  final VoidCallback? onForget;

  @override
  Widget build(BuildContext context) {
    final def = sourceOf(source);
    final locked = source == MemorySource.explicit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? def.color : AppColors.disabled,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              def.code,
              style: AppTypography.serifStyle(size: 18, color: AppColors.card),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.name,
                  style: AppTypography.sansStyle(
                    size: 15,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (rule == null)
                  Text(
                    def.short,
                    style: AppTypography.sansStyle(
                      size: 12,
                      color: AppColors.faint,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        rule!,
                        style: AppTypography.sansStyle(
                          size: 12,
                          color: locked || on
                              ? AppColors.muted
                              : AppColors.faint,
                        ),
                      ),
                      if (count != null && count! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTypography.sansStyle(
                            size: 12,
                            color: AppColors.faint,
                          ),
                        ),
                        TextButton(
                          onPressed: onForget,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forget $count',
                            style: AppTypography.sansStyle(
                              size: 12,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (locked)
            Text(
              'Always on',
              style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
            )
          else
            UmbraToggle(value: on, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }
}

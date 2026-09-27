import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formats.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/memory.dart';
import '../../data/providers/data_providers.dart';
import '../../viewmodels/detail_controller.dart';
import '../../viewmodels/presentation.dart';
import '../widgets/common.dart';

/// Alt sayfa: seçilen hafızanın kartı, düzenleme/onay akışı ve köken zinciri.
class MemoryDetailSheet extends ConsumerWidget {
  const MemoryDetailSheet({super.key, required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailProvider);
    final all = ref.watch(memoriesProvider).value ?? const <Memory>[];
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    Memory? memory;
    for (final m in all) {
      if (m.id == memoryId) memory = m;
    }
    if (memory == null) return const SizedBox.shrink();

    final view = MemoryView(memory);
    final ctrl = ref.read(detailProvider.notifier);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: ctrl.close,
            child: ColoredBox(color: AppColors.shell.withValues(alpha: .4)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
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
                  const SizedBox(height: 20),
                  _HeroCard(
                    view: view,
                    detail: detail,
                    expiryDays: settings.expiryDays,
                  ),
                  const SizedBox(height: 20),
                  if (detail.isEditing) _EditActions(view: view),
                  if (detail.isReviewing)
                    _IdentityReview(
                      before: view.text,
                      after: detail.editText,
                      detail: detail,
                    ),
                  _HowIKnow(view: view),
                  const SizedBox(height: 14),
                  _Facts(view: view, expiryDays: settings.expiryDays),
                  if (_usesOf(ref, memory.id).isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _Uses(names: _usesOf(ref, memory.id)),
                  ],
                  if (detail.isIdle) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: UmbraButton(
                            label: 'Forget',
                            height: 52,
                            fontSize: 14,
                            color: AppColors.danger,
                            onTap: ctrl.forget,
                          ),
                        ),
                        if (view.isPref) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: UmbraButton(
                              label: 'Still true',
                              height: 52,
                              fontSize: 14,
                              filled: false,
                              color: AppColors.card,
                              borderColor: AppColors.card,
                              onTap: ctrl.reconfirm,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: UmbraButton(
                            label: 'Edit',
                            height: 52,
                            fontSize: 14,
                            filled: false,
                            color: AppColors.card,
                            borderColor: AppColors.card,
                            onTap: ctrl.startEdit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bu hafızayı kullanan öneri başlıkları.
  static List<String> _usesOf(WidgetRef ref, String memoryId) {
    final memories = ref.watch(memoriesProvider).value ?? const <Memory>[];
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final names = <String>[];
    for (final s in buildSuggestions(memories, settings)) {
      for (final b in s.basis) {
        if (b.memoryId == memoryId) {
          names.add(s.title);
          break;
        }
      }
    }
    return names;
  }
}

// ---------------------------------------------------------------------------
// Kart
// ---------------------------------------------------------------------------

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.view,
    required this.detail,
    required this.expiryDays,
  });

  final MemoryView view;
  final DetailState detail;
  final int expiryDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(detailProvider.notifier);
    final l = view.layer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: l.bg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    LayerShape(def: l, size: 10),
                    const SizedBox(width: 8),
                    Text(
                      '${l.name} · ${l.tag}'.toUpperCase(),
                      style: AppTypography.sansStyle(
                        size: 11,
                        color: l.color,
                        letterSpacing: .08,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: ctrl.close,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!detail.isEditing)
            Text(
              view.text,
              style: AppTypography.serifStyle(size: 26, height: 1.2),
            )
          else
            _StatementArea(
              key: ValueKey('edit_${view.id}'),
              initial: detail.editText,
              onChanged: ctrl.setEditText,
            ),
          if (view.hasConf) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                ConfidenceDots(values: view.dots, size: 8, gap: 4),
                const SizedBox(width: 10),
                Text(
                  '${view.confWord} · ${view.memory.basis ?? ''}',
                  style: AppTypography.sansStyle(size: 13, color: AppColors.blue),
                ),
              ],
            ),
          ],
          if (view.isLive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: Stack(
                        children: [
                          const ColoredBox(color: Color(0xFFD5E0CB)),
                          FractionallySizedBox(
                            widthFactor: view.expiryRatio(expiryDays),
                            child: const ColoredBox(color: AppColors.good),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  view.expiryLine(expiryDays),
                  style: AppTypography.sansStyle(size: 13, color: AppColors.good),
                ),
              ],
            ),
          ],
          if (view.isPref) ...[
            const SizedBox(height: 16),
            Text(
              'Last confirmed ${view.confirmedFmt}',
              style: AppTypography.sansStyle(size: 13, color: AppColors.warn),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatementArea extends StatefulWidget {
  const _StatementArea({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_StatementArea> createState() => _StatementAreaState();
}

class _StatementAreaState extends State<_StatementArea> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _c,
        maxLines: 3,
        minLines: 3,
        onChanged: widget.onChanged,
        style: AppTypography.serifStyle(size: 18),
        decoration: const InputDecoration(
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Düzenleme / kimlik onayı
// ---------------------------------------------------------------------------

class _EditActions extends ConsumerWidget {
  const _EditActions({required this.view});

  final MemoryView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(detailProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (view.isIdentity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'Identity changes are reviewed before saving.',
                style: AppTypography.sansStyle(size: 13, color: AppColors.muted),
              ),
            ),
          if (view.isIdentity) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: UmbraButton(
                  label: view.isIdentity ? 'Review change' : 'Save',
                  height: 50,
                  onTap: ctrl.primary,
                ),
              ),
              TextButton(
                onPressed: ctrl.cancelEdit,
                child: Text(
                  'Cancel',
                  style: AppTypography.sansStyle(size: 14, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityReview extends ConsumerWidget {
  const _IdentityReview({
    required this.before,
    required this.after,
    required this.detail,
  });

  final String before;
  final String after;
  final DetailState detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(detailProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm identity change',
            style: AppTypography.sansStyle(size: 14, weight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BeforeAfter(
                  label: 'Before',
                  color: AppColors.dangerBg,
                  labelColor: AppColors.danger,
                  text: before,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeforeAfter(
                  label: 'After',
                  color: AppColors.goodBg,
                  labelColor: AppColors.good,
                  text: after,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: UmbraButton(
                  label: 'Confirm',
                  height: 48,
                  onTap: ctrl.confirmIdentity,
                ),
              ),
              TextButton(
                onPressed: ctrl.cancelEdit,
                child: Text(
                  'Keep original',
                  style: AppTypography.sansStyle(size: 14, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({
    required this.label,
    required this.color,
    required this.labelColor,
    required this.text,
  });

  final String label;
  final Color color;
  final Color labelColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.sansStyle(size: 11, color: labelColor),
          ),
          const SizedBox(height: 4),
          Text(text, style: AppTypography.sansStyle(size: 14, height: 1.35)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Köken zinciri
// ---------------------------------------------------------------------------

class _HowIKnow extends StatelessWidget {
  const _HowIKnow({required this.view});

  final MemoryView view;

  @override
  Widget build(BuildContext context) {
    final steps = view.memory.derivation;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How I know this', style: AppTypography.serifStyle(size: 20)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: view.srcBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  view.srcCode,
                  style: AppTypography.serifStyle(size: 18, color: AppColors.card),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      view.srcName,
                      style: AppTypography.sansStyle(
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      view.certainty,
                      style: AppTypography.sansStyle(
                        size: 12,
                        color: AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == steps.length - 1
                                ? AppColors.ink
                                : AppColors.disabled,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i != steps.length - 1)
                          Container(
                            width: 1.5,
                            height: 22,
                            color: AppColors.line,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        steps[i],
                        style: AppTypography.sansStyle(size: 14, height: 1.45),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Küçük bilgi kutuları
// ---------------------------------------------------------------------------

class _Facts extends StatelessWidget {
  const _Facts({required this.view, required this.expiryDays});

  final MemoryView view;
  final int expiryDays;

  @override
  Widget build(BuildContext context) {
    final m = view.memory;
    final facts = <(String, String)>[
      ('Recorded', fmtDate(m.createdAt)),
      ('Source', '${view.srcCode} · ${view.source.name}'),
      if (view.isPattern)
        (
          'Confidence',
          '${view.confWord} · ${(view.memory.confidence! * 100).round()}%',
        ),
      if (view.isLive) ('Auto-deletes', fmtDate(view.expiryFrom(expiryDays))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 160 / 66,
      children: [
        for (final (k, v) in facts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k,
                  style: AppTypography.sansStyle(size: 11, color: AppColors.faint),
                ),
                const SizedBox(height: 4),
                Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sansStyle(size: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Uses extends StatelessWidget {
  const _Uses({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Shaping: ${listJoin(names)}',
            style: AppTypography.sansStyle(size: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

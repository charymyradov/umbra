import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formats.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/catalogs.dart';
import '../../data/models/memory.dart';
import '../../data/providers/data_providers.dart';
import '../../viewmodels/detail_controller.dart';
import '../../viewmodels/memory_screen_controller.dart';
import '../../viewmodels/presentation.dart';
import '../widgets/common.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(memoryScreenProvider);
    final ms = ref.watch(memoryScreenProvider.notifier);
    final memories = ref.watch(memoriesProvider).value ?? const <Memory>[];
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    final all = [for (final m in memories) MemoryView(m)];
    final told = all.where((v) => v.told).length;
    final summary = all.isEmpty
        ? 'Nothing stored.'
        : '$told told by you · ${all.length - told} inferred, then confirmed';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ScreenTitle(title: 'What I know', subtitle: summary),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 104 / 112,
            children: [
              for (final l in kLayers)
                _LayerTile(
                  def: l,
                  count: all.where((v) => v.layerId == l.id).length,
                  selected: ctrl.filter == l.id,
                  onTap: () => ms.toggleFilter(l.id),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.faint),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: ms.setQuery,
                    style: AppTypography.sansStyle(size: 15),
                    cursorColor: AppColors.ink,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: AppColors.faint),
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (final l in kLayers) ...[
            _LayerSection(
              def: l,
              items: [
                for (final v in all)
                  if (v.layerId == l.id &&
                      (ctrl.filter == null || ctrl.filter == l.id) &&
                      v.matches(ctrl.query))
                    v,
              ],
              open: ctrl.openLayers.contains(l.id),
              adding: ctrl.addFor == l.id,
              addText: ctrl.addText,
              canSave: ctrl.canSaveAdd,
              staleAfterDays: settings.staleAfterDays,
              expiryDays: settings.expiryDays,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Katman kutusu (2×2)
// ---------------------------------------------------------------------------

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.def,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final LayerDef def;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: def.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? def.color : AppColors.line,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    def.tag.toUpperCase(),
                    style: AppTypography.sansStyle(
                      size: 11,
                      color: def.color,
                      letterSpacing: .08,
                    ),
                  ),
                  LayerShape(def: def, size: 14),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    def.name,
                    style: AppTypography.sansStyle(
                      size: 15,
                      weight: FontWeight.w500,
                      color: def.color,
                    ),
                  ),
                  Text(
                    '$count',
                    style: AppTypography.serifStyle(
                      size: 30,
                      height: 1,
                      color: def.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Katman akordeonu
// ---------------------------------------------------------------------------

class _LayerSection extends ConsumerWidget {
  const _LayerSection({
    required this.def,
    required this.items,
    required this.open,
    required this.adding,
    required this.addText,
    required this.canSave,
    required this.staleAfterDays,
    required this.expiryDays,
  });

  final LayerDef def;
  final List<MemoryView> items;
  final bool open;
  final bool adding;
  final String addText;
  final bool canSave;
  final int staleAfterDays;
  final int expiryDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.read(memoryScreenProvider.notifier);
    final count = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: open ? def.bg : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => ms.toggleOpen(def.id),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: def.bg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: LayerShape(def: def, size: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.name,
                          style: AppTypography.serifStyle(size: 19, height: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == 0
                              ? def.empty
                              : plural(count, 'memory'),
                          style: AppTypography.sansStyle(
                            size: 12,
                            color: AppColors.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: def.bg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: 8),
          for (final v in items) ...[
            _MemoryCard(view: v, staleAfterDays: staleAfterDays),
            const SizedBox(height: 8),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                def.empty,
                textAlign: TextAlign.center,
                style: AppTypography.sansStyle(size: 13, color: AppColors.faint),
              ),
            ),
          if (adding)
            _AddCard(
              def: def,
              text: addText,
              canSave: canSave,
              onText: ms.setAddText,
              onSave: ms.saveAdd,
              onCancel: ms.cancelAdd,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!adding)
                Expanded(
                  child: DashedButton(
                    label: 'Add',
                    icon: Icons.add,
                    onTap: () => ms.startAdd(def.id),
                  ),
                )
              else
                const Spacer(),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ms.clearLayer(def.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 46),
                  ),
                  child: Text(
                    'Forget all',
                    style: AppTypography.sansStyle(
                      size: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hafıza kartı
// ---------------------------------------------------------------------------

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.view, required this.staleAfterDays});

  final MemoryView view;
  final int staleAfterDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.read(detailProvider.notifier);
    final stale = view.staleAfter(staleAfterDays);
    final expiryDays =
        ref.watch(settingsProvider).value?.expiryDays ?? 7;
    final liveDays = view.isLive ? view.daysLeftFrom(expiryDays) : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: view.isLive && view.layer.cardBorder != null
            ? Border.all(color: view.layer.cardBorder!, width: 1.5)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => detail.open(view.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.text,
                          style: AppTypography.serifStyle(size: 17, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: view.srcBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                view.srcCode,
                                style: AppTypography.serifStyle(
                                  size: 11,
                                  color: AppColors.card,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                view.shortMeta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sansStyle(
                                  size: 12,
                                  color: AppColors.faint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (view.hasConf) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ConfidenceDots(values: view.dots),
                        const SizedBox(height: 5),
                        Text(
                          view.confWord,
                          style: AppTypography.sansStyle(
                            size: 10,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ] else if (view.isLive) ...[
                    const SizedBox(width: 12),
                    _DaysRing(days: liveDays, color: view.layer.color),
                  ],
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => detail.openEdit(view.id),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (stale)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              color: AppColors.warnBg,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Still true?',
                      style: AppTypography.sansStyle(
                        size: 13,
                        color: AppColors.warn,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => detail.reconfirmById(view.id),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 34),
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      'Yes',
                      style: AppTypography.sansStyle(
                        size: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => detail.forgetById(view.id),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 34),
                    ),
                    child: Text(
                      'No',
                      style: AppTypography.sansStyle(
                        size: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int expiryDaysOf(WidgetRef ref) =>
      ref.watch(settingsProvider).value?.expiryDays ?? 7;
}

class _DaysRing extends StatelessWidget {
  const _DaysRing({required this.days, required this.color});

  final int days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$days',
              style: AppTypography.serifStyle(size: 15, color: color),
            ),
            Text(
              'days',
              style: AppTypography.sansStyle(
                size: 8,
                height: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Elle ekleme
// ---------------------------------------------------------------------------

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.def,
    required this.text,
    required this.canSave,
    required this.onText,
    required this.onSave,
    required this.onCancel,
  });

  final LayerDef def;
  final String text;
  final bool canSave;
  final ValueChanged<String> onText;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: def.color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GrowArea(
            key: ValueKey('add_${def.id}'),
            initial: text,
            hint: def.addPlaceholder,
            onChanged: onText,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              def.addNote,
              style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: UmbraButton(
                  label: 'Add to ${def.name}',
                  height: 44,
                  fontSize: 14,
                  enabled: canSave,
                  onTap: onSave,
                ),
              ),
              TextButton(
                onPressed: onCancel,
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

/// Kontrolcüsü dışarıdan gelen metinle senkron kalan çok satırlı alan.
class _GrowArea extends StatefulWidget {
  const _GrowArea({
    super.key,
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_GrowArea> createState() => _GrowAreaState();
}

class _GrowAreaState extends State<_GrowArea> {
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
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _c,
        maxLines: 2,
        minLines: 2,
        onChanged: widget.onChanged,
        style: AppTypography.serifStyle(size: 16),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.faint),
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

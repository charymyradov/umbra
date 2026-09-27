import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../viewmodels/privacy_viewmodel.dart';
import '../widgets/common.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(privacyProvider);
    final vm = ref.read(privacyProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: ScreenTitle(
              title: 'Privacy',
              subtitle: "You're in control. No double-checks.",
            ),
          ),
          const SizedBox(height: 28),

          // --- Kaynak dağılımı ------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Where memories come from',
                      style: AppTypography.sansStyle(
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${ui.memCount}',
                      style: AppTypography.serifStyle(size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        for (final (fraction, color) in ui.srcBar)
                          if (fraction > 0)
                            Expanded(
                              flex: (fraction * 1000).round(),
                              child: ColoredBox(color: color),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // --- How I learn ----------------------------------------------------
          Text(
            'How I learn',
            style: AppTypography.serifStyle(size: 20),
          ),
          const SizedBox(height: 8),
          for (final r in ui.mechRows) ...[
            _MechRow(row: r, vm: vm),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),

          // --- Dışa aktarma ---------------------------------------------------
          _ExportCard(
            onJson: () => _share(context, vm.exportJson()),
            onSummary: () => _share(context, vm.exportSummary()),
          ),
          const SizedBox(height: 28),

          // --- Katman silme ---------------------------------------------------
          Text('Forget a layer', style: AppTypography.serifStyle(size: 20)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 74 / 84,
            children: [
              for (final l in ui.layers)
                Opacity(
                  opacity: l.opacity,
                  child: Material(
                    color: l.def.bg,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: l.count == 0
                          ? null
                          : () => vm.forgetLayer(l.def.id),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${l.count}',
                            style: AppTypography.serifStyle(
                              size: 24,
                              height: 1,
                              color: l.def.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.def.name,
                            style: AppTypography.sansStyle(
                              size: 11,
                              color: l.def.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // --- Son olaylar ----------------------------------------------------
          Text('Recent', style: AppTypography.serifStyle(size: 20)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ui.log.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Nothing yet.',
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.sansStyle(size: 13, color: AppColors.faint),
                    ),
                  )
                : Column(
                    children: [
                      for (final l in ui.log)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: l.first
                                ? null
                                : const Border(
                                    top: BorderSide(color: AppColors.lineSoft),
                                  ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 44,
                                child: Text(
                                  l.when,
                                  style: AppTypography.sansStyle(
                                    size: 13,
                                    color: AppColors.faint,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  l.text,
                                  style: AppTypography.sansStyle(
                                    size: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          Material(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => _confirmForgetEverything(context, vm),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    'Forget everything',
                    style: AppTypography.sansStyle(
                      size: 15,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the share sheet.')),
      );
    }
  }

  void _confirmForgetEverything(BuildContext context, PrivacyViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Forget everything?', style: AppTypography.serifStyle(size: 22)),
        content: Text(
          'Every memory is deleted. This cannot be undone.',
          style: AppTypography.sansStyle(size: 14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.sansStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.forgetEverything();
            },
            child: Text(
              'Forget',
              style: AppTypography.sansStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "How I learn" satırı
// ---------------------------------------------------------------------------

class _MechRow extends StatelessWidget {
  const _MechRow({required this.row, required this.vm});

  final MechRowVm row;
  final PrivacyViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: row.def.color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              row.def.code,
              style: AppTypography.serifStyle(size: 17, color: AppColors.card),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.def.name,
                  style: AppTypography.sansStyle(size: 14, weight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      row.rule,
                      style: AppTypography.sansStyle(
                        size: 12,
                        color: row.ruleColor,
                      ),
                    ),
                    if (row.hasMem) ...[
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => vm.forgetMechanism(row.def.id),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Forget ${row.count}',
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
          if (row.locked)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Always on',
                style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
              ),
            )
          else
            UmbraToggle(
              value: row.on,
              width: 48,
              height: 30,
              travel: 18,
              onChanged: (_) => vm.toggleMech(row.def.id),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Take it with you"
// ---------------------------------------------------------------------------

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.onJson, required this.onSummary});

  final VoidCallback onJson;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -40,
            top: -40,
            child: _Circle(color: AppColors.shellSoft),
          ),
          const Positioned(
            right: -12,
            top: -58,
            child: _Circle(color: AppColors.ink),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Take it with you',
                  style: AppTypography.serifStyle(
                    size: 26,
                    color: AppColors.onDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Every item, with its source and history.',
                  style: AppTypography.sansStyle(
                    size: 13,
                    color: AppColors.onDarkMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: UmbraButton(
                        label: 'JSON',
                        height: 48,
                        fontSize: 14,
                        color: AppColors.onDark,
                        textColor: AppColors.ink,
                        onTap: onJson,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: UmbraButton(
                        label: 'Summary',
                        height: 48,
                        fontSize: 14,
                        filled: false,
                        textColor: AppColors.onDark,
                        borderColor: AppColors.muted,
                        onTap: onSummary,
                      ),
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

class _Circle extends StatelessWidget {
  const _Circle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

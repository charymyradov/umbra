import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../viewmodels/sources_viewmodel.dart';
import '../widgets/common.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(sourcesProvider);
    final vm = ref.read(sourcesProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ScreenTitle(
              title: 'Sources',
              subtitle: ui.summary,
            ),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 158 / 214,
            children: [
              for (final c in ui.cards)
                _ConnectionCard(
                  card: c,
                  onToggle: () => vm.toggle(c),
                  onForget: () => vm.forget(c),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.card,
    required this.onToggle,
    required this.onForget,
  });

  final ConnectionCardVm card;
  final VoidCallback onToggle;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Opacity(
        opacity: card.opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: card.tileBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    card.def.glyph,
                    style: AppTypography.serifStyle(size: 22, color: card.tileFg),
                  ),
                ),
                UmbraToggle(
                  value: card.on,
                  width: 42,
                  height: 26,
                  travel: 16,
                  trackOn: AppColors.ink,
                  trackOff: AppColors.track,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              card.def.name,
              style: AppTypography.sansStyle(size: 15, weight: FontWeight.w500),
            ),
            const SizedBox(height: 3),
            Text(
              card.def.reads,
              style: AppTypography.sansStyle(size: 12, color: AppColors.faint),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      card.statusLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sansStyle(
                        size: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  if (card.hasMemory)
                    GestureDetector(
                      onTap: onForget,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
                        child: Text(
                          'Forget',
                          style: AppTypography.sansStyle(
                            size: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/detail_controller.dart';
import '../../viewmodels/shell_controller.dart';
import '../../viewmodels/today_viewmodel.dart';
import '../memory/memory_screen.dart';
import '../privacy/privacy_screen.dart';
import '../sheets/memory_detail_sheet.dart';
import '../sheets/tell_sheet.dart';
import '../sources/sources_screen.dart';
import '../today/today_screen.dart';
import '../widgets/nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.framed});

  /// Geniş ekranda telefon maketi gösterilir.
  final bool framed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellProvider);
    final pending = ref.watch(todayUiProvider).pendingTotal;
    final padding = MediaQuery.paddingOf(context);
    final bottomInset = framed ? 0.0 : padding.bottom;
    final overlayOpen = shell.overlay != AppOverlay.none;

    return Stack(
        children: [
          Positioned.fill(
            child: switch (shell.tab) {
              AppTab.today => const TodayScreen(),
              AppTab.memory => const MemoryScreen(),
              AppTab.sources => const SourcesScreen(),
              AppTab.privacy => const PrivacyScreen(),
            },
          ),
          if (shell.toast != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 102 + bottomInset,
              child: ToastBar(
                toast: shell.toast!,
                onUndo: () {
                  final undo = shell.toast?.undo;
                  if (undo == null || undo.isEmpty) return;
                  ref.read(detailProvider.notifier).undoDelete(undo);
                },
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 26 + bottomInset,
            child: IgnorePointer(
              ignoring: overlayOpen,
              child: Opacity(
                opacity: overlayOpen ? 0 : 1,
                child: BottomNavBar(
                  current: shell.tab,
                  badge: pending > 0 && shell.tab != AppTab.today,
                  onSelect: (tab) =>
                      ref.read(shellProvider.notifier).goTab(tab),
                  onTell: () => ref.read(shellProvider.notifier).openTell(),
                ),
              ),
            ),
          ),
          if (framed)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          if (shell.overlay == AppOverlay.memoryDetail &&
              shell.selectedMemoryId != null)
            Positioned.fill(
              child: MemoryDetailSheet(memoryId: shell.selectedMemoryId!),
            ),
          if (shell.overlay == AppOverlay.tell)
            const Positioned.fill(child: TellSheet()),
        ],
    );
  }
}

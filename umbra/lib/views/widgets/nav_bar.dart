import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../viewmodels/shell_controller.dart';
import 'common.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.current,
    required this.badge,
    required this.onSelect,
    required this.onTell,
  });

  final AppTab current;
  final bool badge;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onTell;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D2B2620),
            blurRadius: 30,
            offset: Offset(0, 12),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavButton(
            icon: Icons.menu_book_outlined,
            selected: current == AppTab.today,
            badge: badge,
            onTap: () => onSelect(AppTab.today),
          ),
          _NavButton(
            icon: Icons.layers_outlined,
            selected: current == AppTab.memory,
            onTap: () => onSelect(AppTab.memory),
          ),
          GestureDetector(
            onTap: onTell,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.onDark),
            ),
          ),
          _NavButton(
            icon: Icons.apps,
            selected: current == AppTab.sources,
            onTap: () => onSelect(AppTab.sources),
          ),
          _NavButton(
            icon: Icons.shield_outlined,
            selected: current == AppTab.privacy,
            onTap: () => onSelect(AppTab.privacy),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppColors.onDark : AppColors.faint,
              ),
            ),
            if (badge && !selected)
              const Positioned(
                top: 8,
                right: 8,
                child: _BadgeDot(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFC0772E),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.card, width: 2),
      ),
    );
  }
}

/// Prototipteki alttan bildirim çubuğu (Undo ile).
class ToastBar extends StatelessWidget {
  const ToastBar({super.key, required this.toast, required this.onUndo});

  final ToastData toast;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 30,
            offset: Offset(0, 14),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                toast.message,
                style: AppTypography.sansStyle(
                  size: 14,
                  color: AppColors.onDark,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (toast.canUndo)
            UmbraButton(
              label: 'Undo',
              onTap: onUndo,
              height: 40,
              fontSize: 14,
              color: AppColors.thumb,
              textColor: AppColors.onDark,
            ),
        ],
      ),
    );
  }
}

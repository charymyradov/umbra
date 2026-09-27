import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Prototipteki 390×844 cihaz çerçevesi.
///
/// Geniş ekranda (masaüstü) telefon maketi gösterilir, dar ekranda uygulama
/// tüm alanı kaplar ve gerçek sistem çubuğu boşluğu kullanılır.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final framed = size.width >= 620;

    final content = ColoredBox(
      color: AppColors.bg,
      child: Column(
        children: [
          _StatusBar(mock: framed, topInset: padding.top),
          Expanded(child: child),
        ],
      ),
    );

    if (!framed) return content;

    return Center(
      child: Container(
        width: 412,
        height: 866,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.shell,
          borderRadius: BorderRadius.circular(62),
          boxShadow: const [
            BoxShadow(
              color: Color(0x732B2620),
              blurRadius: 80,
              offset: Offset(0, 40),
              spreadRadius: -30,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(51),
          child: content,
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.mock, required this.topInset});

  final bool mock;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    if (!mock) return SizedBox(height: topInset);
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 6, 30, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '9:41',
              style: AppTypography.sansStyle(size: 15, weight: FontWeight.w600),
            ),
            const Spacer(),
            const _SignalBars(),
            const SizedBox(width: 6),
            const _Battery(),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();

  @override
  Widget build(BuildContext context) {
    const heights = [5.0, 7.0, 9.0, 11.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final h in heights) ...[
          Container(
            width: 3,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (h != heights.last) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 12,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: .7,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

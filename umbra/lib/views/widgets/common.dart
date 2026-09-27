import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/catalogs.dart';

// ---------------------------------------------------------------------------
// Katman şekli (kare / daire / kesikli)
// ---------------------------------------------------------------------------

class LayerShape extends StatelessWidget {
  const LayerShape({
    super.key,
    required this.def,
    this.size = 14,
  });

  final LayerDef def;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = def.shapeRadius >= 999 ? size / 2 : def.shapeRadius;
    if (def.shapeBorderWidth > 0 && def.shapeBorder != null) {
      return CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          color: def.shapeBorder!,
          width: def.shapeBorderWidth,
          radius: radius,
          fill: def.shapeFill,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: def.shapeFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.width,
    required this.radius,
    this.fill,
  });

  final Color color;
  final double width;
  final double radius;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (fill != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = fill!,
      );
    }
    final inset = width / 2;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(math.max(0, radius - inset)),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final total = metric.length;
    const dashes = 10;
    final seg = total / dashes;
    final on = seg * 0.55;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < dashes; i++) {
      canvas.drawPath(metric.extractPath(i * seg, i * seg + on), paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.width != width ||
      old.radius != radius ||
      old.fill != fill;
}

/// Kesikli çizgili kart çerçevesi.
class DashedRect extends StatelessWidget {
  const DashedRect({
    super.key,
    required this.child,
    required this.color,
    this.radius = 18,
    this.width = 1.5,
    this.padding,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double width;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color, radius, width),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color, this.radius, this.width);

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    const dash = 7.0;
    const gap = 5.0;
    var distance = 0.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    while (distance < metric.length) {
      canvas.drawPath(
        metric.extractPath(
          distance,
          math.min(distance + dash, metric.length),
        ),
        paint,
      );
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Anahtar (switch)
// ---------------------------------------------------------------------------

class UmbraToggle extends StatelessWidget {
  const UmbraToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.trackOn = const Color(0xFF4B6A42),
    this.trackOff = AppColors.track,
    this.width = 48,
    this.height = 30,
    this.travel = 18,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color trackOn;
  final Color trackOff;
  final double width;
  final double height;
  final double travel;

  @override
  Widget build(BuildContext context) {
    final thumb = height - 6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: width + 4,
        height: height + 6,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? trackOn : trackOff,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumb,
                height: thumb,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Küçük parçalar
// ---------------------------------------------------------------------------

class ConfidenceDots extends StatelessWidget {
  const ConfidenceDots({
    super.key,
    required this.values,
    this.size = 6,
    this.gap = 3,
    this.on = AppColors.blue,
    this.off = const Color(0xFFD3DDE7),
  });

  final List<bool> values;
  final double size;
  final double gap;
  final Color on;
  final Color off;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: values[i] ? on : off,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

/// "Book cover" — prototipteki renkli kitap sırtı.
class CoverTile extends StatelessWidget {
  const CoverTile({
    super.key,
    required this.bg,
    required this.fg,
    required this.kind,
    required this.title,
    this.author,
    this.footer,
    this.footerWidget,
    this.width = 104,
    this.height = 150,
    this.titleSize = 17,
  });

  final Color bg;
  final Color fg;
  final String kind;
  final String title;
  final String? author;
  final String? footer;
  final Widget? footerWidget;
  final double width;
  final double height;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(14)),
        boxShadow: const [
          BoxShadow(color: Color(0x802B2620), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.toUpperCase(),
            style: AppTypography.sansStyle(
              size: 9,
              color: fg.withValues(alpha: .8),
              letterSpacing: .1,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.serifStyle(size: titleSize, color: fg, height: 1.05),
          ),
          const Spacer(),
          if (footerWidget != null)
            footerWidget!
          else if (author != null)
            Text(
              author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sansStyle(size: 9, color: fg.withValues(alpha: .8)),
            ),
        ],
      ),
    );
  }
}

/// Yuvarlak etiket (pill).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.bg = Colors.transparent,
    this.fg = AppColors.muted,
    this.border = BorderSide.none,
    this.height = 26,
  });

  final String label;
  final Color bg;
  final Color fg;
  final BorderSide border;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: border == BorderSide.none ? null : Border.fromBorderSide(border),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Text(
        label,
        style: AppTypography.sansStyle(size: 12, color: fg),
      ),
    );
  }
}

/// Kesikli çizgili "Add" butonu.
class DashedButton extends StatelessWidget {
  const DashedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 46,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: CustomPaint(
          painter: _DashedBorderPainter(AppColors.hairline, height / 2, 1.5),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppColors.muted),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.sansStyle(size: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary / secondary butonlar.
class UmbraButton extends StatelessWidget {
  const UmbraButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.height = 48,
    this.color = AppColors.ink,
    this.textColor,
    this.borderColor,
    this.fontSize = 14,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final double height;
  final Color color;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: Material(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(height / 2),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: filled
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(color: borderColor ?? AppColors.line),
                  ),
            child: Text(
              label,
              style: AppTypography.sansStyle(
                size: fontSize,
                weight: FontWeight.w500,
                color: textColor ??
                    (filled ? AppColors.onDark : AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçili görünüm değiştiren segment (ör. "Remember this / Just talk").
class SegmentedRow extends StatelessWidget {
  const SegmentedRow({super.key, required this.items});

  final List<(String label, bool selected, VoidCallback onTap)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lineSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final (label, selected, onTap) in items)
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x1F2B2620),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: AppTypography.sansStyle(size: 14, color: AppColors.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sayfa başlığı.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.serifStyle(size: 32, height: 1.05),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTypography.sansStyle(size: 14, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Kesikli çizgili boş durum kutusu.
class EmptyBox extends StatelessWidget {
  const EmptyBox({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(AppColors.hairline, 28, 1.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.serifStyle(size: 22),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              UmbraButton(
                label: actionLabel!,
                onTap: onAction ?? () {},
                height: 44,
                fontSize: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

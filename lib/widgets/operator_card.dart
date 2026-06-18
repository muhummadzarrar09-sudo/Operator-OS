import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';

/// Premium dark tactical card used by the Phase 1 visual layer.
class OperatorCard extends StatelessWidget {
  final String? label;
  final String? title;
  final String? body;
  final IconData? icon;
  final Widget? child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final VoidCallback? onTap;

  const OperatorCard({
    this.label,
    this.title,
    this.body,
    this.icon,
    this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? OperatorPalette.parchmentGold;
    final content = Container(
      decoration: BoxDecoration(
        gradient: OperatorGradients.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OperatorPalette.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: OperatorGradients.ember)),
          ),
          Padding(
            padding: padding,
            child: child ?? _DefaultContent(
              label: label,
              title: title,
              body: body,
              icon: icon,
              trailing: trailing,
              accent: accent,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: content,
    );
  }
}

class _DefaultContent extends StatelessWidget {
  final String? label;
  final String? title;
  final String? body;
  final IconData? icon;
  final Widget? trailing;
  final Color accent;

  const _DefaultContent({
    required this.label,
    required this.title,
    required this.body,
    required this.icon,
    required this.trailing,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null) ...[
                Text(label!, style: OperatorTextStyles.overline),
                const SizedBox(height: 6),
              ],
              if (title != null) Text(title!, style: OperatorTextStyles.title),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!, style: OperatorTextStyles.body),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

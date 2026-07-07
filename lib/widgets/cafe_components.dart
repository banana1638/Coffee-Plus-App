import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_typography.dart';

class CafeSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadiusGeometry borderRadius;
  final bool clip;

  const CafeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.appSurface,
        borderRadius: borderRadius,
        border: Border.all(color: context.appBorder),
      ),
      child: Padding(padding: padding, child: child),
    );

    return Container(
      margin: margin,
      child: clip ? ClipRRect(borderRadius: borderRadius, child: content) : content,
    );
  }
}

class CafeSectionHeader extends StatelessWidget {
  final String label;
  final String? trailing;

  const CafeSectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label.toUpperCase(), style: AppTypography.sectionLabel(context))),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTypography.ledger(context, fontSize: 11).copyWith(color: context.appTextMuted),
          ),
      ],
    );
  }
}

class CafeMoneyText extends StatelessWidget {
  final num amount;
  final double fontSize;
  final bool signed;

  const CafeMoneyText({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = signed && amount > 0 ? '+ ' : '';
    return Text(
      '${prefix}RM ${amount.toStringAsFixed(2)}',
      style: AppTypography.money(context, fontSize: fontSize),
    );
  }
}

class CafeLedgerText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign? textAlign;
  final Color? color;

  const CafeLedgerText({
    super.key,
    required this.text,
    this.fontSize = 13,
    this.textAlign,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: AppTypography.ledger(context, fontSize: fontSize).copyWith(color: color),
    );
  }
}

class CafeDivider extends StatelessWidget {
  const CafeDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.appBorder);
  }
}

class PerforatedDivider extends StatelessWidget {
  final int holes;
  final double diameter;

  const PerforatedDivider({super.key, this.holes = 22, this.diameter = 8});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(holes, (index) {
        return Expanded(
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: context.appBackground,
                shape: BoxShape.circle,
                border: Border.all(color: context.appBorder),
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/pitwall_theme.dart';

class PitwallCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? borderColor;

  const PitwallCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PitwallTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? PitwallTheme.cardBorder,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class TimingText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const TimingText(
    this.text, {
    super.key,
    this.fontSize,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: PitwallTheme.monoStyle.copyWith(
        fontSize: fontSize,
        color: color ?? Colors.white,
        fontWeight: fontWeight,
      ),
    );
  }
}

class TeamBadge extends StatelessWidget {
  final String teamName;
  final Color teamColor;

  const TeamBadge({
    super.key,
    required this.teamName,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.1),
        border: Border.all(color: teamColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        teamName.toUpperCase(),
        style: TextStyle(
          color: teamColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

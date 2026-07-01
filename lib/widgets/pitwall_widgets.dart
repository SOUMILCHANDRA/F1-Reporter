import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PitwallCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? borderColor;

  const PitwallCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? AppConfig.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TimingText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const TimingText(
    this.text, {
    super.key,
    this.fontSize = 12,
    this.fontWeight = FontWeight.normal,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppConfig.monoStyle.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppConfig.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: teamColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        teamName,
        style: TextStyle(
          color: teamColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

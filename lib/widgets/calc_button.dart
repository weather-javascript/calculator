// lib/widgets/calc_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

enum ButtonStyle { number, operator, function, action, clear, special }

class CalcButton extends StatefulWidget {
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final ButtonStyle style;
  final double? width;
  final double? height;
  final Color? overrideColor;
  final bool isActive;
  final double fontSize;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.style = ButtonStyle.number,
    this.width,
    this.height,
    this.overrideColor,
    this.isActive = false,
    this.fontSize = 18,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bg {
    if (widget.overrideColor != null) return widget.overrideColor!;
    switch (widget.style) {
      case ButtonStyle.number:
        return AppTheme.btnNumber;
      case ButtonStyle.operator:
        return AppTheme.btnOperator;
      case ButtonStyle.function:
        return AppTheme.btnFunction;
      case ButtonStyle.action:
        return AppTheme.btnAction;
      case ButtonStyle.clear:
        return AppTheme.btnClear;
      case ButtonStyle.special:
        return AppTheme.btnSpecial;
    }
  }

  Color get _fg {
    switch (widget.style) {
      case ButtonStyle.action:
        return AppTheme.textPrimary;
      case ButtonStyle.clear:
        return const Color(0xFFFFCDD2);
      case ButtonStyle.special:
        return const Color(0xFFE9D5FF);
      case ButtonStyle.operator:
        return AppTheme.accentCyan;
      case ButtonStyle.function:
        return AppTheme.accentOrange;
      default:
        return AppTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height ?? 64,
          decoration: BoxDecoration(
            color: widget.isActive ? _bg : _bg.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: widget.isActive
                    ? AppTheme.accentCyan.withOpacity(0.6)
                    : AppTheme.borderColor.withOpacity(0.4),
                width: widget.isActive ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6)
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.label,
                style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: _fg,
                    height: 1.0),
                textAlign: TextAlign.center),
            if (widget.sublabel != null) ...[
              const SizedBox(height: 2),
              Text(widget.sublabel!,
                  style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 10,
                      color: _fg.withOpacity(0.6),
                      height: 1.0),
                  textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }
}

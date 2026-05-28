// lib/widgets/multi_input_field.dart

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class InputField extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;
  final String placeholder;
  final Color? accentColor;

  const InputField({
    super.key,
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.placeholder = '0',
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accentCyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.08) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? color.withOpacity(0.6) : AppTheme.borderColor,
                width: isActive ? 1.5 : 1)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? color : AppTheme.textMuted,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                    child: Text(value.isEmpty ? placeholder : value,
                        style: TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: value.isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  _CursorBlink(color: color),
                ],
              ]),
            ]),
      ),
    );
  }
}

class _CursorBlink extends StatefulWidget {
  final Color color;
  const _CursorBlink({required this.color});
  @override
  State<_CursorBlink> createState() => _CursorBlinkState();
}

class _CursorBlinkState extends State<_CursorBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _ctrl,
      child: Container(width: 2, height: 18, color: widget.color));
}

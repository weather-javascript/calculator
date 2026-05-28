// lib/widgets/calc_display.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class CalcDisplay extends StatelessWidget {
  final String expression;
  final String result;
  final bool hasError;
  final bool isCalculating;
  final String modeName;
  final Color modeColor;

  const CalcDisplay({
    super.key,
    required this.expression,
    required this.result,
    required this.hasError,
    required this.isCalculating,
    required this.modeName,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24)),
        border: Border(bottom: BorderSide(
          color: modeColor.withOpacity(0.3), width: 1.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: modeColor.withOpacity(0.4))),
              child: Text(modeName, style: TextStyle(
                fontFamily: 'Space Grotesk', fontSize: 11,
                fontWeight: FontWeight.w600, color: modeColor, letterSpacing: 0.8))),
            if (isCalculating)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(modeColor))),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onLongPress: () {
              if (expression.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: expression));
            }
            },
            child: Container(
              alignment: Alignment.centerRight,
              constraints: const BoxConstraints(minHeight: 28),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, reverse: true,
                child: Text(expression.isEmpty ? ' ' : expression,
                  style: const TextStyle(fontFamily: 'IBM Plex Mono',
                    fontSize: 18, color: AppTheme.textSecondary, height: 1.4)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: () {
              if (result.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: result));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('結果をコピーしました'),
                  backgroundColor: AppTheme.surfaceCard,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                  child: child)),
              child: Container(
                key: ValueKey(result),
                alignment: Alignment.centerRight,
                constraints: const BoxConstraints(minHeight: 56),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, reverse: true,
                  child: Text(result.isEmpty ? '0' : result,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: _fs(result),
                      fontWeight: FontWeight.w300,
                      color: hasError ? AppTheme.accentRed
                          : (result.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary),
                      height: 1.2)),
                ),
              ),
            ),
          ),
        ]),
    );
  }

  double _fs(String r) {
    if (r.length > 20) return 20;
    if (r.length > 14) return 28;
    if (r.length > 10) return 36;
    return 44;
  }
}

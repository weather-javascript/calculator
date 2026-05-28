// lib/features/algebra/widgets/algebra_keyboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/algebra_screen.dart';

class AlgebraKeyboard extends StatelessWidget {
  final void Function(String) onAppend;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onCalculate;
  final bool loading;
  final Color accentColor;
  final String activeField;
  final AlgebraTab mode;
  final void Function(String) onFieldSelect;

  const AlgebraKeyboard({
    super.key,
    required this.onAppend,
    required this.onBackspace,
    required this.onClear,
    required this.onCalculate,
    required this.loading,
    required this.accentColor,
    required this.activeField,
    required this.mode,
    required this.onFieldSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isNumericOnly =
        mode == AlgebraTab.quadratic || mode == AlgebraTab.linear2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        if (!isNumericOnly) ...[
          _row([
            _key('AC', _Style.clear, onClear),
            _key('⌫', _Style.fn, onBackspace),
            _key('(', _Style.fn, () => onAppend('(')),
            _key(')', _Style.fn, () => onAppend(')')),
          ]),
          _row([
            _key('x²', _Style.special, () => onAppend('^2')),
            _key('xⁿ', _Style.special, () => onAppend('^')),
            _key('√', _Style.special, () => onAppend('sqrt(')),
            _key('x', _Style.fn, () => onAppend('x')),
          ]),
        ] else ...[
          _row([
            _key('AC', _Style.clear, onClear),
            _key('⌫', _Style.fn, onBackspace),
            _key('-', _Style.op, () => onAppend('-')),
            _key('.', _Style.num, () => onAppend('.')),
          ]),
        ],
        _row([
          _key('7', _Style.num, () => onAppend('7')),
          _key('8', _Style.num, () => onAppend('8')),
          _key('9', _Style.num, () => onAppend('9')),
          _key('÷', _Style.op, () => onAppend('/')),
        ]),
        _row([
          _key('4', _Style.num, () => onAppend('4')),
          _key('5', _Style.num, () => onAppend('5')),
          _key('6', _Style.num, () => onAppend('6')),
          _key('×', _Style.op, () => onAppend('*')),
        ]),
        _row([
          _key('1', _Style.num, () => onAppend('1')),
          _key('2', _Style.num, () => onAppend('2')),
          _key('3', _Style.num, () => onAppend('3')),
          _key('+', _Style.op, () => onAppend('+')),
        ]),
        _row([
          _key('0', _Style.num, () => onAppend('0')),
          if (!isNumericOnly) _key('.', _Style.num, () => onAppend('.')),
          if (isNumericOnly) _key('00', _Style.num, () => onAppend('00')),
          _key('=', _Style.action, onCalculate, loading: loading, flex: 2),
        ]),
      ]),
    );
  }

  Widget _row(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: children.map((w) => w).toList()),
      );

  Widget _key(String label, _Style style, VoidCallback onTap,
      {bool loading = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _CalcKey(
          label: label,
          style: style,
          onTap: onTap,
          loading: loading,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

enum _Style { num, op, fn, special, clear, action }

class _CalcKey extends StatefulWidget {
  final String label;
  final _Style style;
  final VoidCallback onTap;
  final bool loading;
  final Color accentColor;
  const _CalcKey(
      {required this.label,
      required this.style,
      required this.onTap,
      required this.loading,
      required this.accentColor});
  @override
  State<_CalcKey> createState() => _CalcKeyState();
}

class _CalcKeyState extends State<_CalcKey>
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
    switch (widget.style) {
      case _Style.num:
        return AppTheme.btnNumber;
      case _Style.op:
        return AppTheme.btnOperator;
      case _Style.fn:
        return AppTheme.btnFunction;
      case _Style.special:
        return AppTheme.btnSpecial;
      case _Style.clear:
        return AppTheme.btnClear;
      case _Style.action:
        return widget.accentColor.withOpacity(0.85);
    }
  }

  Color get _fg {
    switch (widget.style) {
      case _Style.op:
        return AppTheme.accentCyan;
      case _Style.special:
        return const Color(0xFFE9D5FF);
      case _Style.clear:
        return const Color(0xFFFFCDD2);
      case _Style.fn:
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
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2),
                blurRadius: 4,
              )
            ],
          ),
          child: Center(
              child: widget.loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.textPrimary)))
                  : Text(widget.label,
                      style: TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _fg))),
        ),
      ),
    );
  }
}

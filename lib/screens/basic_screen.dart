// lib/screens/basic_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../core/engine/math_engine_service.dart';
import '../core/router/app_modes.dart';
import '../widgets/calc_button.dart' as cb;

class BasicScreen extends StatelessWidget {
  const BasicScreen({super.key});

  Future<void> _calc(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final raw = state.currentExpression.trim();
    if (raw.isEmpty) return;
    state.setCalculating(true);
    final res =
        await MathEngineService().evaluate(MathEngineService.preprocess(raw));
    state.setResult(
        raw, res.success ? MathEngineService.formatNum(res.result) : res.result,
        isError: !res.success);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(builder: (ctx, state, _) {
      switch (state.mode) {
        case CalcMode.applied:
          return _applied(ctx, state);
        case CalcMode.functions:
          return _functions(ctx, state);
        default:
          return _basic(ctx, state);
      }
    });
  }

  // ── 四則演算 ──────────────────────────────────────────
  Widget _basic(BuildContext ctx, CalculatorState s) => _pad([
        _row([
          _b('AC', cb.ButtonStyle.clear, () => s.clearAll()),
          _b('+/-', cb.ButtonStyle.function, () => s.inputOperator('*-1')),
          _b('%', cb.ButtonStyle.function, () => s.inputOperator('/100')),
          _b('÷', cb.ButtonStyle.operator, () => s.inputOperator('/')),
        ]),
        _row([
          _b('7', cb.ButtonStyle.number, () => s.inputDigit('7')),
          _b('8', cb.ButtonStyle.number, () => s.inputDigit('8')),
          _b('9', cb.ButtonStyle.number, () => s.inputDigit('9')),
          _b('×', cb.ButtonStyle.operator, () => s.inputOperator('*')),
        ]),
        _row([
          _b('4', cb.ButtonStyle.number, () => s.inputDigit('4')),
          _b('5', cb.ButtonStyle.number, () => s.inputDigit('5')),
          _b('6', cb.ButtonStyle.number, () => s.inputDigit('6')),
          _b('−', cb.ButtonStyle.operator, () => s.inputOperator('-')),
        ]),
        _row([
          _b('1', cb.ButtonStyle.number, () => s.inputDigit('1')),
          _b('2', cb.ButtonStyle.number, () => s.inputDigit('2')),
          _b('3', cb.ButtonStyle.number, () => s.inputDigit('3')),
          _b('+', cb.ButtonStyle.operator, () => s.inputOperator('+')),
        ]),
        _row([
          _bWide('0', cb.ButtonStyle.number, () => s.inputDigit('0')),
          _b('.', cb.ButtonStyle.number, () => s.inputDecimal()),
          _b('=', cb.ButtonStyle.action, () => _calc(ctx)),
        ]),
      ]);

  // ── 応用計算 ──────────────────────────────────────────
  Widget _applied(BuildContext ctx, CalculatorState s) => _pad([
        _row([
          _b('AC', cb.ButtonStyle.clear, () => s.clearAll()),
          _b('⌫', cb.ButtonStyle.function, () => s.backspace()),
          _b('(', cb.ButtonStyle.function, () => s.inputOperator('(')),
          _b(')', cb.ButtonStyle.function, () => s.inputOperator(')')),
        ]),
        _row([
          _b('√', cb.ButtonStyle.special, () => s.inputFunction('sqrt(')),
          _b('x²', cb.ButtonStyle.special, () => s.inputOperator('^2')),
          _b('xⁿ', cb.ButtonStyle.special, () => s.inputOperator('^')),
          _b('|x|', cb.ButtonStyle.special, () => s.inputFunction('abs(')),
        ]),
        _row([
          _b('7', cb.ButtonStyle.number, () => s.inputDigit('7')),
          _b('8', cb.ButtonStyle.number, () => s.inputDigit('8')),
          _b('9', cb.ButtonStyle.number, () => s.inputDigit('9')),
          _b('÷', cb.ButtonStyle.operator, () => s.inputOperator('/')),
        ]),
        _row([
          _b('4', cb.ButtonStyle.number, () => s.inputDigit('4')),
          _b('5', cb.ButtonStyle.number, () => s.inputDigit('5')),
          _b('6', cb.ButtonStyle.number, () => s.inputDigit('6')),
          _b('×', cb.ButtonStyle.operator, () => s.inputOperator('*')),
        ]),
        _row([
          _b('1', cb.ButtonStyle.number, () => s.inputDigit('1')),
          _b('2', cb.ButtonStyle.number, () => s.inputDigit('2')),
          _b('3', cb.ButtonStyle.number, () => s.inputDigit('3')),
          _b('−', cb.ButtonStyle.operator, () => s.inputOperator('-')),
        ]),
        _row([
          _b('0', cb.ButtonStyle.number, () => s.inputDigit('0')),
          _b('.', cb.ButtonStyle.number, () => s.inputDecimal()),
          _b('π', cb.ButtonStyle.special, () => s.inputDigit('pi')),
          _b('=', cb.ButtonStyle.action, () => _calc(ctx)),
        ]),
      ]);

  // ── 関数 ─────────────────────────────────────────────
  Widget _functions(BuildContext ctx, CalculatorState s) => _pad([
        _row([
          _b('AC', cb.ButtonStyle.clear, () => s.clearAll()),
          _b('⌫', cb.ButtonStyle.function, () => s.backspace()),
          _b('(', cb.ButtonStyle.function, () => s.inputOperator('(')),
          _b(')', cb.ButtonStyle.function, () => s.inputOperator(')')),
        ]),
        _row([
          _b('sin', cb.ButtonStyle.special, () => s.inputFunction('sin(')),
          _b('cos', cb.ButtonStyle.special, () => s.inputFunction('cos(')),
          _b('tan', cb.ButtonStyle.special, () => s.inputFunction('tan(')),
          _b('π', cb.ButtonStyle.special, () => s.inputDigit('pi')),
        ]),
        _row([
          _b('log', cb.ButtonStyle.special, () => s.inputFunction('log10('),
              sublabel: 'log₁₀'),
          _b('ln', cb.ButtonStyle.special, () => s.inputFunction('log('),
              sublabel: 'logₑ'),
          _b('exp', cb.ButtonStyle.special, () => s.inputFunction('exp('),
              sublabel: 'eˣ'),
          _b('e', cb.ButtonStyle.special, () => s.inputDigit('e')),
        ]),
        _row([
          _b('7', cb.ButtonStyle.number, () => s.inputDigit('7')),
          _b('8', cb.ButtonStyle.number, () => s.inputDigit('8')),
          _b('9', cb.ButtonStyle.number, () => s.inputDigit('9')),
          _b('÷', cb.ButtonStyle.operator, () => s.inputOperator('/')),
        ]),
        _row([
          _b('4', cb.ButtonStyle.number, () => s.inputDigit('4')),
          _b('5', cb.ButtonStyle.number, () => s.inputDigit('5')),
          _b('6', cb.ButtonStyle.number, () => s.inputDigit('6')),
          _b('×', cb.ButtonStyle.operator, () => s.inputOperator('*')),
        ]),
        _row([
          _b('1', cb.ButtonStyle.number, () => s.inputDigit('1')),
          _b('2', cb.ButtonStyle.number, () => s.inputDigit('2')),
          _b('3', cb.ButtonStyle.number, () => s.inputDigit('3')),
          _b('+', cb.ButtonStyle.operator, () => s.inputOperator('+')),
        ]),
        _row([
          _b('0', cb.ButtonStyle.number, () => s.inputDigit('0')),
          _b('.', cb.ButtonStyle.number, () => s.inputDecimal()),
          _b('^', cb.ButtonStyle.function, () => s.inputOperator('^')),
          _b('=', cb.ButtonStyle.action, () => _calc(ctx)),
        ]),
      ]);

  // ── ヘルパー ─────────────────────────────────────────
  Widget _pad(List<Widget> rows) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: rows));

  Widget _row(List<Widget> btns) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          children: btns
              .map((b) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: b)))
              .toList()));

  Widget _b(String label, cb.ButtonStyle style, VoidCallback onTap,
          {String? sublabel}) =>
      cb.CalcButton(
          label: label,
          sublabel: sublabel,
          style: style,
          onTap: onTap,
          height: 62);

  Widget _bWide(String label, cb.ButtonStyle style, VoidCallback onTap) =>
      cb.CalcButton(label: label, style: style, onTap: onTap, height: 62);
}

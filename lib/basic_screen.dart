// lib/screens/basic_screen.dart
// 四則演算 + 応用計算 + 関数

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../services/math_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;

class BasicScreen extends StatelessWidget {
  const BasicScreen({super.key});

  Future<void> _calculate(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final engine = MathEngineService();

    final raw = state.currentExpression.trim();
    if (raw.isEmpty) return;

    state.setCalculating(true);

    final expr = MathEngineService.preprocessExpression(raw);
    final result = await engine.evaluate(expr);
    final formatted = result.success
        ? MathEngineService.formatResult(result.result)
        : result.result;

    state.setResult(
      raw,
      formatted,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
      builder: (context, state, _) {
        return _buildButtons(context, state);
      },
    );
  }

  Widget _buildButtons(BuildContext context, CalculatorState state) {
    final mode = state.mode;
    if (mode == CalculatorMode.applied) return _appliedLayout(context, state);
    if (mode == CalculatorMode.functions) return _functionsLayout(context, state);
    return _basicLayout(context, state);
  }

  Widget _basicLayout(BuildContext context, CalculatorState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _row(context, state, [
            _btn('AC', cb.ButtonStyle.clear, () => state.clearAll()),
            _btn('+/-', cb.ButtonStyle.function, () => state.inputOperator('*-1')),
            _btn('%', cb.ButtonStyle.function, () => state.inputOperator('/100')),
            _btn('÷', cb.ButtonStyle.operator, () => state.inputOperator('/')),
          ]),
          _row(context, state, [
            _btn('7', cb.ButtonStyle.number, () => state.inputDigit('7')),
            _btn('8', cb.ButtonStyle.number, () => state.inputDigit('8')),
            _btn('9', cb.ButtonStyle.number, () => state.inputDigit('9')),
            _btn('×', cb.ButtonStyle.operator, () => state.inputOperator('*')),
          ]),
          _row(context, state, [
            _btn('4', cb.ButtonStyle.number, () => state.inputDigit('4')),
            _btn('5', cb.ButtonStyle.number, () => state.inputDigit('5')),
            _btn('6', cb.ButtonStyle.number, () => state.inputDigit('6')),
            _btn('−', cb.ButtonStyle.operator, () => state.inputOperator('-')),
          ]),
          _row(context, state, [
            _btn('1', cb.ButtonStyle.number, () => state.inputDigit('1')),
            _btn('2', cb.ButtonStyle.number, () => state.inputDigit('2')),
            _btn('3', cb.ButtonStyle.number, () => state.inputDigit('3')),
            _btn('+', cb.ButtonStyle.operator, () => state.inputOperator('+')),
          ]),
          _row(context, state, [
            _btnWide('0', cb.ButtonStyle.number, () => state.inputDigit('0')),
            _btn('.', cb.ButtonStyle.number, () => state.inputDecimal()),
            _btn('=', cb.ButtonStyle.action, () => _calculate(context)),
          ]),
        ],
      ),
    );
  }

  Widget _appliedLayout(BuildContext context, CalculatorState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _row(context, state, [
            _btn('AC', cb.ButtonStyle.clear, () => state.clearAll()),
            _btn('⌫', cb.ButtonStyle.function, () => state.backspace()),
            _btn('(', cb.ButtonStyle.function, () => state.inputOperator('(')),
            _btn(')', cb.ButtonStyle.function, () => state.inputOperator(')')),
          ]),
          _row(context, state, [
            _btn('√', cb.ButtonStyle.special, () => state.inputFunction('sqrt('), sublabel: 'sqrt'),
            _btn('x²', cb.ButtonStyle.special, () => state.inputOperator('^2'), sublabel: 'pow'),
            _btn('xⁿ', cb.ButtonStyle.special, () => state.inputOperator('^'), sublabel: 'pow'),
            _btn('|x|', cb.ButtonStyle.special, () => state.inputFunction('abs('), sublabel: 'abs'),
          ]),
          _row(context, state, [
            _btn('7', cb.ButtonStyle.number, () => state.inputDigit('7')),
            _btn('8', cb.ButtonStyle.number, () => state.inputDigit('8')),
            _btn('9', cb.ButtonStyle.number, () => state.inputDigit('9')),
            _btn('÷', cb.ButtonStyle.operator, () => state.inputOperator('/')),
          ]),
          _row(context, state, [
            _btn('4', cb.ButtonStyle.number, () => state.inputDigit('4')),
            _btn('5', cb.ButtonStyle.number, () => state.inputDigit('5')),
            _btn('6', cb.ButtonStyle.number, () => state.inputDigit('6')),
            _btn('×', cb.ButtonStyle.operator, () => state.inputOperator('*')),
          ]),
          _row(context, state, [
            _btn('1', cb.ButtonStyle.number, () => state.inputDigit('1')),
            _btn('2', cb.ButtonStyle.number, () => state.inputDigit('2')),
            _btn('3', cb.ButtonStyle.number, () => state.inputDigit('3')),
            _btn('−', cb.ButtonStyle.operator, () => state.inputOperator('-')),
          ]),
          _row(context, state, [
            _btn('0', cb.ButtonStyle.number, () => state.inputDigit('0')),
            _btn('.', cb.ButtonStyle.number, () => state.inputDecimal()),
            _btn('π', cb.ButtonStyle.special, () => state.inputDigit('pi')),
            _btn('=', cb.ButtonStyle.action, () => _calculate(context)),
          ]),
        ],
      ),
    );
  }

  Widget _functionsLayout(BuildContext context, CalculatorState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _row(context, state, [
            _btn('AC', cb.ButtonStyle.clear, () => state.clearAll()),
            _btn('⌫', cb.ButtonStyle.function, () => state.backspace()),
            _btn('(', cb.ButtonStyle.function, () => state.inputOperator('(')),
            _btn(')', cb.ButtonStyle.function, () => state.inputOperator(')')),
          ]),
          _row(context, state, [
            _btn('sin', cb.ButtonStyle.special, () => state.inputFunction('sin(')),
            _btn('cos', cb.ButtonStyle.special, () => state.inputFunction('cos(')),
            _btn('tan', cb.ButtonStyle.special, () => state.inputFunction('tan(')),
            _btn('π', cb.ButtonStyle.special, () => state.inputDigit('pi')),
          ]),
          _row(context, state, [
            _btn('log', cb.ButtonStyle.special,
                () => state.inputFunction('log10('), sublabel: 'log₁₀'),
            _btn('ln', cb.ButtonStyle.special,
                () => state.inputFunction('log('), sublabel: 'logₑ'),
            _btn('exp', cb.ButtonStyle.special,
                () => state.inputFunction('exp('), sublabel: 'eˣ'),
            _btn('e', cb.ButtonStyle.special, () => state.inputDigit('e')),
          ]),
          _row(context, state, [
            _btn('7', cb.ButtonStyle.number, () => state.inputDigit('7')),
            _btn('8', cb.ButtonStyle.number, () => state.inputDigit('8')),
            _btn('9', cb.ButtonStyle.number, () => state.inputDigit('9')),
            _btn('÷', cb.ButtonStyle.operator, () => state.inputOperator('/')),
          ]),
          _row(context, state, [
            _btn('4', cb.ButtonStyle.number, () => state.inputDigit('4')),
            _btn('5', cb.ButtonStyle.number, () => state.inputDigit('5')),
            _btn('6', cb.ButtonStyle.number, () => state.inputDigit('6')),
            _btn('×', cb.ButtonStyle.operator, () => state.inputOperator('*')),
          ]),
          _row(context, state, [
            _btn('1', cb.ButtonStyle.number, () => state.inputDigit('1')),
            _btn('2', cb.ButtonStyle.number, () => state.inputDigit('2')),
            _btn('3', cb.ButtonStyle.number, () => state.inputDigit('3')),
            _btn('+', cb.ButtonStyle.operator, () => state.inputOperator('+')),
          ]),
          _row(context, state, [
            _btn('0', cb.ButtonStyle.number, () => state.inputDigit('0')),
            _btn('.', cb.ButtonStyle.number, () => state.inputDecimal()),
            _btn('^', cb.ButtonStyle.function, () => state.inputOperator('^')),
            _btn('=', cb.ButtonStyle.action, () => _calculate(context)),
          ]),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Builder helpers
  // ──────────────────────────────────────────────

  Widget _row(BuildContext context, CalculatorState state, List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: buttons
            .map((b) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: b,
                )))
            .toList(),
      ),
    );
  }

  Widget _btn(
    String label,
    cb.ButtonStyle style,
    VoidCallback onTap, {
    String? sublabel,
  }) {
    return cb.CalcButton(
      label: label,
      sublabel: sublabel,
      style: style,
      onTap: onTap,
      height: 62,
    );
  }

  Widget _btnWide(String label, cb.ButtonStyle style, VoidCallback onTap) {
    return cb.CalcButton(
      label: label,
      style: style,
      onTap: onTap,
      height: 62,
    );
  }
}

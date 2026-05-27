// lib/screens/calculus_screen.dart
// 微分・積分（記号微分 + 数値積分）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../services/math_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

class CalculusScreen extends StatefulWidget {
  const CalculusScreen({super.key});

  @override
  State<CalculusScreen> createState() => _CalculusScreenState();
}

class _CalculusScreenState extends State<CalculusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDiff = true; // true=微分, false=積分

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isDiff = _tabController.index == 0);
      context.read<CalculatorState>().clearAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _calcDifferentiate(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final engine = MathEngineService();
    final expr = state.field1.trim();
    final variable = state.field2.trim().isEmpty ? 'x' : state.field2.trim();

    if (expr.isEmpty) return;
    state.setCalculating(true);

    final processed = MathEngineService.preprocessExpression(expr);
    final result = await engine.differentiate(processed, variable: variable);
    state.setResult(
      'd/d$variable ($expr)',
      result.success ? result.result : result.result,
      isError: !result.success,
    );
  }

  Future<void> _calcIntegrate(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final engine = MathEngineService();
    final expr = state.field1.trim();
    final variable = state.field2.trim().isEmpty ? 'x' : state.field2.trim();
    final lower = state.field3.trim();
    final upper = state.field4.trim();

    if (expr.isEmpty) return;
    state.setCalculating(true);

    final processed = MathEngineService.preprocessExpression(expr);

    if (lower.isEmpty || upper.isEmpty) {
      // Indefinite: symbolic hint
      final result = await engine.integrateSymbolic(processed, variable: variable);
      state.setResult(
        '∫($expr)d$variable',
        result.result,
        isError: !result.success,
      );
    } else {
      // Definite: numerical Simpson's
      final a = double.tryParse(lower);
      final b = double.tryParse(upper);
      if (a == null || b == null) {
        state.setResult('積分', 'Error: 積分範囲が無効', isError: true);
        return;
      }
      final result = await engine.integrateNumerical(
        processed, a, b, variable: variable,
      );
      state.setResult(
        '∫[$lower→$upper]($expr)d$variable',
        result.success ? MathEngineService.formatResult(result.result) : result.result,
        isError: !result.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
      builder: (context, state, _) {
        return Column(
          children: [
            // Tab bar: 微分 / 積分
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                labelColor: AppTheme.accentGreen,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: '微分  d/dx'),
                  Tab(text: '積分  ∫'),
                ],
              ),
            ),

            // Input fields
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _isDiff
                  ? _diffInputs(context, state)
                  : _integralInputs(context, state),
            ),

            // Keyboard
            Expanded(
              child: _buildKeyboard(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _diffInputs(BuildContext context, CalculatorState state) {
    return Column(
      children: [
        InputField(
          label: 'f(x) — 微分する関数',
          value: state.field1,
          isActive: state.activeField == 'field1',
          onTap: () => state.setActiveField('field1'),
          placeholder: '例: x^3 + 2*x',
          accentColor: AppTheme.accentGreen,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputField(
                label: '変数',
                value: state.field2,
                isActive: state.activeField == 'field2',
                onTap: () => state.setActiveField('field2'),
                placeholder: 'x',
                accentColor: AppTheme.accentGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _integralInputs(BuildContext context, CalculatorState state) {
    return Column(
      children: [
        InputField(
          label: 'f(x) — 積分する関数',
          value: state.field1,
          isActive: state.activeField == 'field1',
          onTap: () => state.setActiveField('field1'),
          placeholder: '例: x^2, sin(x)',
          accentColor: AppTheme.accentGreen,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputField(
                label: '変数',
                value: state.field2,
                isActive: state.activeField == 'field2',
                onTap: () => state.setActiveField('field2'),
                placeholder: 'x',
                accentColor: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: InputField(
                      label: '下限 a',
                      value: state.field3,
                      isActive: state.activeField == 'field3',
                      onTap: () => state.setActiveField('field3'),
                      placeholder: '空=不定積分',
                      accentColor: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InputField(
                      label: '上限 b',
                      value: state.field4,
                      isActive: state.activeField == 'field4',
                      onTap: () => state.setActiveField('field4'),
                      placeholder: '空=不定積分',
                      accentColor: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyboard(BuildContext context, CalculatorState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _row([
            _btn('AC', cb.ButtonStyle.clear, () => state.clearAll()),
            _btn('⌫', cb.ButtonStyle.function, () => state.backspace()),
            _btn('(', cb.ButtonStyle.function,
                () => state.appendToActive('(')),
            _btn(')', cb.ButtonStyle.function,
                () => state.appendToActive(')')),
          ]),
          _row([
            _btn('sin', cb.ButtonStyle.special,
                () => state.appendToActive('sin(')),
            _btn('cos', cb.ButtonStyle.special,
                () => state.appendToActive('cos(')),
            _btn('tan', cb.ButtonStyle.special,
                () => state.appendToActive('tan(')),
            _btn('π', cb.ButtonStyle.special,
                () => state.appendToActive('pi')),
          ]),
          _row([
            _btn('ln', cb.ButtonStyle.special,
                () => state.appendToActive('log('), sublabel: 'logₑ'),
            _btn('exp', cb.ButtonStyle.special,
                () => state.appendToActive('exp(')),
            _btn('√', cb.ButtonStyle.special,
                () => state.appendToActive('sqrt(')),
            _btn('^', cb.ButtonStyle.function,
                () => state.appendToActive('^')),
          ]),
          _row([
            _btn('7', cb.ButtonStyle.number, () => state.appendToActive('7')),
            _btn('8', cb.ButtonStyle.number, () => state.appendToActive('8')),
            _btn('9', cb.ButtonStyle.number, () => state.appendToActive('9')),
            _btn('*', cb.ButtonStyle.operator,
                () => state.appendToActive('*')),
          ]),
          _row([
            _btn('4', cb.ButtonStyle.number, () => state.appendToActive('4')),
            _btn('5', cb.ButtonStyle.number, () => state.appendToActive('5')),
            _btn('6', cb.ButtonStyle.number, () => state.appendToActive('6')),
            _btn('-', cb.ButtonStyle.operator,
                () => state.appendToActive('-')),
          ]),
          _row([
            _btn('1', cb.ButtonStyle.number, () => state.appendToActive('1')),
            _btn('2', cb.ButtonStyle.number, () => state.appendToActive('2')),
            _btn('3', cb.ButtonStyle.number, () => state.appendToActive('3')),
            _btn('+', cb.ButtonStyle.operator,
                () => state.appendToActive('+')),
          ]),
          _row([
            _btn('0', cb.ButtonStyle.number, () => state.appendToActive('0')),
            _btn('.', cb.ButtonStyle.number, () => state.appendToActive('.')),
            _btn('x', cb.ButtonStyle.function,
                () => state.appendToActive('x')),
            _btn(_isDiff ? "d/dx" : "∫", cb.ButtonStyle.action, () {
              if (_isDiff) {
                _calcDifferentiate(context);
              } else {
                _calcIntegrate(context);
              }
            }, fontSize: 14),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> btns) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: btns
              .map((b) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: b,
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _btn(String label, cb.ButtonStyle style, VoidCallback onTap,
      {String? sublabel, double fontSize = 18}) {
    return cb.CalcButton(
      label: label,
      sublabel: sublabel,
      style: style,
      onTap: onTap,
      height: 58,
      fontSize: fontSize,
    );
  }
}

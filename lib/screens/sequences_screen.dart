// lib/screens/sequences_screen.dart
// 数列: シグマ (Σ) / 積 (Π)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../services/math_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});

  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  bool _isSigma = true;

  Future<void> _calculate(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final engine = MathEngineService();

    final expr = state.field1.trim();
    final variable = state.field2.trim().isEmpty ? 'k' : state.field2.trim();
    final start = int.tryParse(state.field3.trim());
    final end = int.tryParse(state.field4.trim());

    if (expr.isEmpty || start == null || end == null) {
      state.setResult('数列計算', 'Error: 式と範囲を入力してください', isError: true);
      return;
    }

    state.setCalculating(true);
    final processed = MathEngineService.preprocessExpression(expr);

    MathResult result;
    String displayExpr;

    if (_isSigma) {
      result = await engine.sigma(processed, start, end, variable: variable);
      displayExpr = 'Σ[$variable=$start..$end] ($expr)';
    } else {
      result = await engine.product(processed, start, end, variable: variable);
      displayExpr = 'Π[$variable=$start..$end] ($expr)';
    }

    state.setResult(
      displayExpr,
      result.success
          ? MathEngineService.formatResult(result.result)
          : result.result,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFEC4899);

    return Consumer<CalculatorState>(
      builder: (context, state, _) {
        return Column(
          children: [
            // Toggle Σ / Π
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _toggle('Σ 和（シグマ）', true, accentColor),
                  const SizedBox(width: 8),
                  _toggle('Π 積', false, accentColor),
                ],
              ),
            ),

            // Input fields
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Column(
                children: [
                  InputField(
                    label: _isSigma ? 'Σ f(k) — 一般項' : 'Π f(k) — 一般項',
                    value: state.field1,
                    isActive: state.activeField == 'field1',
                    onTap: () => state.setActiveField('field1'),
                    placeholder: '例: k^2, 1/k, 2^k',
                    accentColor: accentColor,
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
                          placeholder: 'k',
                          accentColor: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InputField(
                          label: '下限 (始点)',
                          value: state.field3,
                          isActive: state.activeField == 'field3',
                          onTap: () => state.setActiveField('field3'),
                          placeholder: '1',
                          accentColor: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InputField(
                          label: '上限 (終点)',
                          value: state.field4,
                          isActive: state.activeField == 'field4',
                          onTap: () => state.setActiveField('field4'),
                          placeholder: '100',
                          accentColor: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Examples
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _examplesRow(state, accentColor),
            ),

            // Keyboard
            Expanded(child: _buildKeyboard(context, state, accentColor)),
          ],
        );
      },
    );
  }

  Widget _toggle(String label, bool value, Color accentColor) {
    final isActive = _isSigma == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _isSigma = value);
          context.read<CalculatorState>().clearAll();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.15) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? accentColor.withOpacity(0.5) : AppTheme.borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? accentColor : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _examplesRow(CalculatorState state, Color accentColor) {
    final examples = _isSigma
        ? [('k', 'k'), ('k²', 'k^2'), ('1/k', '1/k'), ('2^k', '2^k')]
        : [('k', 'k'), ('k²', 'k^2'), ('k+1', 'k+1')];

    return Wrap(
      spacing: 6,
      children: examples.map((ex) {
        return GestureDetector(
          onTap: () {
            state.setActiveField('field1');
            // Clear and set field1
            while (state.field1.isNotEmpty) state.backspace();
            for (final c in ex.$2.split('')) {
              state.appendToActive(c);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.25),
              ),
            ),
            child: Text(
              ex.$1,
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 12,
                color: accentColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyboard(
      BuildContext context, CalculatorState state, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _row([
            _btn('AC', cb.ButtonStyle.clear, () => state.clearAll()),
            _btn('⌫', cb.ButtonStyle.function, () => state.backspace()),
            _btn('(', cb.ButtonStyle.function, () => state.appendToActive('(')),
            _btn(')', cb.ButtonStyle.function, () => state.appendToActive(')')),
          ]),
          _row([
            _btn('7', cb.ButtonStyle.number, () => state.appendToActive('7')),
            _btn('8', cb.ButtonStyle.number, () => state.appendToActive('8')),
            _btn('9', cb.ButtonStyle.number, () => state.appendToActive('9')),
            _btn('÷', cb.ButtonStyle.operator, () => state.appendToActive('/')),
          ]),
          _row([
            _btn('4', cb.ButtonStyle.number, () => state.appendToActive('4')),
            _btn('5', cb.ButtonStyle.number, () => state.appendToActive('5')),
            _btn('6', cb.ButtonStyle.number, () => state.appendToActive('6')),
            _btn('×', cb.ButtonStyle.operator, () => state.appendToActive('*')),
          ]),
          _row([
            _btn('1', cb.ButtonStyle.number, () => state.appendToActive('1')),
            _btn('2', cb.ButtonStyle.number, () => state.appendToActive('2')),
            _btn('3', cb.ButtonStyle.number, () => state.appendToActive('3')),
            _btn('+', cb.ButtonStyle.operator, () => state.appendToActive('+')),
          ]),
          _row([
            _btn('0', cb.ButtonStyle.number, () => state.appendToActive('0')),
            _btn('.', cb.ButtonStyle.number, () => state.appendToActive('.')),
            _btn('^', cb.ButtonStyle.function, () => state.appendToActive('^')),
            _btn(_isSigma ? 'Σ' : 'Π', cb.ButtonStyle.action,
                () => _calculate(context)),
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

  Widget _btn(String label, cb.ButtonStyle style, VoidCallback onTap) {
    return cb.CalcButton(
      label: label,
      style: style,
      onTap: onTap,
      height: 62,
    );
  }
}

// lib/screens/combinatorics_screen.dart
// 場合の数: 順列 (nPr), 組合せ (nCr), 階乗 (n!)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../services/math_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

enum CombiMode { permutation, combination, factorial }

class CombinatoricsScreen extends StatefulWidget {
  const CombinatoricsScreen({super.key});

  @override
  State<CombinatoricsScreen> createState() => _CombinatoricsScreenState();
}

class _CombinatoricsScreenState extends State<CombinatoricsScreen> {
  CombiMode _combiMode = CombiMode.permutation;

  Future<void> _calculate(BuildContext context) async {
    final state = context.read<CalculatorState>();
    final engine = MathEngineService();
    state.setCalculating(true);

    MathResult result;
    String expression;

    switch (_combiMode) {
      case CombiMode.permutation:
        final n = int.tryParse(state.field1.trim());
        final r = int.tryParse(state.field2.trim());
        if (n == null || r == null) {
          state.setResult('nPr', 'Error: n, r は整数で入力してください', isError: true);
          return;
        }
        expression = '${state.field1}P${state.field2}';
        result = await engine.permutation(n, r);
        break;

      case CombiMode.combination:
        final n = int.tryParse(state.field1.trim());
        final r = int.tryParse(state.field2.trim());
        if (n == null || r == null) {
          state.setResult('nCr', 'Error: n, r は整数で入力してください', isError: true);
          return;
        }
        expression = '${state.field1}C${state.field2}';
        result = await engine.combination(n, r);
        break;

      case CombiMode.factorial:
        final n = int.tryParse(state.field1.trim());
        if (n == null) {
          state.setResult('n!', 'Error: n は整数で入力してください', isError: true);
          return;
        }
        expression = '${state.field1}!';
        result = await engine.factorial(n);
        break;
    }

    state.setResult(
      expression,
      result.success
          ? MathEngineService.formatResult(result.result)
          : result.result,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
      builder: (context, state, _) {
        return Column(
          children: [
            // Mode selector
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _modeChip('nPr\n順列', CombiMode.permutation),
                  const SizedBox(width: 8),
                  _modeChip('nCr\n組合せ', CombiMode.combination),
                  const SizedBox(width: 8),
                  _modeChip('n!\n階乗', CombiMode.factorial),
                ],
              ),
            ),

            // Input fields
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _combiMode == CombiMode.factorial
                  ? InputField(
                      label: 'n — 整数',
                      value: state.field1,
                      isActive: state.activeField == 'field1',
                      onTap: () => state.setActiveField('field1'),
                      placeholder: '例: 10',
                      accentColor: AppTheme.accentPurple,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: 'n — 総数',
                            value: state.field1,
                            isActive: state.activeField == 'field1',
                            onTap: () => state.setActiveField('field1'),
                            placeholder: '例: 10',
                            accentColor: AppTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InputField(
                            label: 'r — 選ぶ数',
                            value: state.field2,
                            isActive: state.activeField == 'field2',
                            onTap: () => state.setActiveField('field2'),
                            placeholder: '例: 3',
                            accentColor: AppTheme.accentPurple,
                          ),
                        ),
                      ],
                    ),
            ),

            // Formula display
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _formulaCard(),
            ),

            // Keyboard
            Expanded(child: _buildKeyboard(context, state)),
          ],
        );
      },
    );
  }

  Widget _modeChip(String label, CombiMode mode) {
    final isActive = _combiMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _combiMode = mode);
          context.read<CalculatorState>().clearAll();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accentPurple.withOpacity(0.2)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppTheme.accentPurple.withOpacity(0.6)
                  : AppTheme.borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.accentPurple : AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulaCard() {
    final formulas = {
      CombiMode.permutation: 'nPr = n! / (n-r)!',
      CombiMode.combination: 'nCr = n! / (r! × (n-r)!)',
      CombiMode.factorial:   'n! = n × (n-1) × ⋯ × 1',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.accentPurple.withOpacity(0.2),
        ),
      ),
      child: Text(
        formulas[_combiMode]!,
        style: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
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
            _btn('CE', cb.ButtonStyle.function, () => state.clearEntry()),
            if (_combiMode != CombiMode.factorial)
              _btn('→r', cb.ButtonStyle.function,
                  () => state.setActiveField('field2')),
            if (_combiMode == CombiMode.factorial)
              _btn('', cb.ButtonStyle.number, () {}),
          ]),
          _row([
            _btn('7', cb.ButtonStyle.number, () => state.appendToActive('7')),
            _btn('8', cb.ButtonStyle.number, () => state.appendToActive('8')),
            _btn('9', cb.ButtonStyle.number, () => state.appendToActive('9')),
            _btn('→n', cb.ButtonStyle.function,
                () => state.setActiveField('field1')),
          ]),
          _row([
            _btn('4', cb.ButtonStyle.number, () => state.appendToActive('4')),
            _btn('5', cb.ButtonStyle.number, () => state.appendToActive('5')),
            _btn('6', cb.ButtonStyle.number, () => state.appendToActive('6')),
            _btn('', cb.ButtonStyle.number, () {}),
          ]),
          _row([
            _btn('1', cb.ButtonStyle.number, () => state.appendToActive('1')),
            _btn('2', cb.ButtonStyle.number, () => state.appendToActive('2')),
            _btn('3', cb.ButtonStyle.number, () => state.appendToActive('3')),
            _btn('', cb.ButtonStyle.number, () {}),
          ]),
          _row([
            _btn('0', cb.ButtonStyle.number, () => state.appendToActive('0')),
            _btn('00', cb.ButtonStyle.number,
                () => state.appendToActive('00')),
            _btn('000', cb.ButtonStyle.number,
                () => state.appendToActive('000')),
            _btn(
              _combiMode == CombiMode.permutation
                  ? 'nPr'
                  : _combiMode == CombiMode.combination
                      ? 'nCr'
                      : 'n!',
              cb.ButtonStyle.action,
              () => _calculate(context),
              fontSize: 14,
            ),
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
      {double fontSize = 18}) {
    return cb.CalcButton(
      label: label,
      style: style,
      onTap: onTap,
      height: 62,
      fontSize: fontSize,
    );
  }
}

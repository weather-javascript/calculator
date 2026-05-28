// lib/screens/combinatorics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../core/engine/math_engine_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

enum _CombiMode { permutation, combination, factorial }

class CombinatoricsScreen extends StatefulWidget {
  const CombinatoricsScreen({super.key});
  @override
  State<CombinatoricsScreen> createState() => _CombinatoricsScreenState();
}

class _CombinatoricsScreenState extends State<CombinatoricsScreen> {
  _CombiMode _cm = _CombiMode.permutation;
  final _color = const Color(0xFF8B5CF6);

  Future<void> _calc(BuildContext ctx) async {
    final s = ctx.read<CalculatorState>();
    final engine = MathEngineService();
    s.setCalculating(true);

    if (_cm == _CombiMode.factorial) {
      final n = int.tryParse(s.field1.trim());
      if (n == null) {
        s.setResult('n!', 'Error: 整数を入力', isError: true);
        return;
      }
      final r = await engine.factorial(n);
      s.setResult('${s.field1}!', r.success ? r.result : r.result,
          isError: !r.success);
    } else {
      final n = int.tryParse(s.field1.trim()),
          r2 = int.tryParse(s.field2.trim());
      if (n == null || r2 == null) {
        s.setResult('', 'Error: 整数を入力', isError: true);
        return;
      }
      final res = _cm == _CombiMode.permutation
          ? await engine.permutation(n, r2)
          : await engine.combination(n, r2);
      final label = _cm == _CombiMode.permutation
          ? '${s.field1}P${s.field2}'
          : '${s.field1}C${s.field2}';
      s.setResult(label, res.success ? res.result : res.result,
          isError: !res.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
        builder: (ctx, s, _) => Column(children: [
              // モード選択
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(children: [
                    _chip('nPr\n順列', _CombiMode.permutation),
                    const SizedBox(width: 8),
                    _chip('nCr\n組合せ', _CombiMode.combination),
                    const SizedBox(width: 8),
                    _chip('n!\n階乗', _CombiMode.factorial),
                  ])),
              // 公式
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: _color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _color.withOpacity(0.2))),
                      child: Text(
                          _cm == _CombiMode.permutation
                              ? 'nPr = n! / (n-r)!'
                              : _cm == _CombiMode.combination
                                  ? 'nCr = n! / (r! × (n-r)!)'
                                  : 'n! = n × (n-1) × ⋯ × 1',
                          style: const TextStyle(
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 13,
                              color: AppTheme.textSecondary),
                          textAlign: TextAlign.center))),
              // 入力フィールド
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _cm == _CombiMode.factorial
                      ? InputField(
                          label: '整数 n',
                          value: s.field1,
                          isActive: s.activeField == 'field1',
                          onTap: () => s.setActiveField('field1'),
                          placeholder: '例: 10',
                          accentColor: _color)
                      : Row(children: [
                          Expanded(
                              child: InputField(
                                  label: 'n — 総数',
                                  value: s.field1,
                                  isActive: s.activeField == 'field1',
                                  onTap: () => s.setActiveField('field1'),
                                  placeholder: '例: 10',
                                  accentColor: _color)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: InputField(
                                  label: 'r — 選ぶ数',
                                  value: s.field2,
                                  isActive: s.activeField == 'field2',
                                  onTap: () => s.setActiveField('field2'),
                                  placeholder: '例: 3',
                                  accentColor: _color)),
                        ])),
              // キーボード
              Expanded(child: _keyboard(ctx, s)),
            ]));
  }

  Widget _chip(String label, _CombiMode m) {
    final active = _cm == m;
    return Expanded(
        child: GestureDetector(
      onTap: () {
        setState(() => _cm = m);
        context.read<CalculatorState>().clearAll();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? _color.withOpacity(0.2) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? _color.withOpacity(0.6) : AppTheme.borderColor,
                width: active ? 1.5 : 1)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? _color : AppTheme.textMuted,
                height: 1.4)),
      ),
    ));
  }

  Widget _keyboard(BuildContext ctx, CalculatorState s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _r([
          _b('AC', cb.ButtonStyle.clear, s.clearAll),
          _b('⌫', cb.ButtonStyle.function, s.backspace),
          _b('CE', cb.ButtonStyle.function, s.clearEntry),
          _cm != _CombiMode.factorial
              ? _b('→r', cb.ButtonStyle.function,
                  () => s.setActiveField('field2'))
              : _b('', cb.ButtonStyle.number, () {})
        ]),
        _r([
          _b('7', cb.ButtonStyle.number, () => s.appendToActive('7')),
          _b('8', cb.ButtonStyle.number, () => s.appendToActive('8')),
          _b('9', cb.ButtonStyle.number, () => s.appendToActive('9')),
          _b('→n', cb.ButtonStyle.function, () => s.setActiveField('field1'))
        ]),
        _r([
          _b('4', cb.ButtonStyle.number, () => s.appendToActive('4')),
          _b('5', cb.ButtonStyle.number, () => s.appendToActive('5')),
          _b('6', cb.ButtonStyle.number, () => s.appendToActive('6')),
          _b('', cb.ButtonStyle.number, () {})
        ]),
        _r([
          _b('1', cb.ButtonStyle.number, () => s.appendToActive('1')),
          _b('2', cb.ButtonStyle.number, () => s.appendToActive('2')),
          _b('3', cb.ButtonStyle.number, () => s.appendToActive('3')),
          _b('', cb.ButtonStyle.number, () {})
        ]),
        _r([
          _b('0', cb.ButtonStyle.number, () => s.appendToActive('0')),
          _b('00', cb.ButtonStyle.number, () => s.appendToActive('00')),
          _b('000', cb.ButtonStyle.number, () => s.appendToActive('000')),
          _b(
              _cm == _CombiMode.permutation
                  ? 'nPr'
                  : _cm == _CombiMode.combination
                      ? 'nCr'
                      : 'n!',
              cb.ButtonStyle.action,
              () => _calc(ctx),
              fs: 14)
        ]),
      ]),
    );
  }

  Widget _r(List<Widget> ch) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          children: ch
              .map((w) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: w)))
              .toList()));

  Widget _b(String l, cb.ButtonStyle s, VoidCallback fn, {double fs = 18}) =>
      cb.CalcButton(label: l, style: s, onTap: fn, height: 62, fontSize: fs);
}

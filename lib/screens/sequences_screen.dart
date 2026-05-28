// lib/screens/sequences_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../core/engine/math_engine_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});
  @override State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  bool _isSigma = true;
  final _color = const Color(0xFFD946EF);

  Future<void> _calc(BuildContext ctx) async {
    final s = ctx.read<CalculatorState>();
    final engine = MathEngineService();
    final expr = s.field1.trim();
    final v = s.field2.trim().isEmpty ? 'k' : s.field2.trim();
    final start = int.tryParse(s.field3.trim());
    final end = int.tryParse(s.field4.trim());
    if (expr.isEmpty || start == null || end == null) {
      s.setResult('', 'Error: 式と範囲を入力してください', isError: true);
      return;
    }
    s.setCalculating(true);
    final processed = MathEngineService.preprocess(expr);
    final res = _isSigma
      ? await engine.sigma(processed, start, end, v: v)
      : await engine.product(processed, start, end, v: v);
    final label = _isSigma
      ? 'Σ[$v=$start..$end]($expr)'
      : 'Π[$v=$start..$end]($expr)';
    s.setResult(label, res.success ? MathEngineService.formatNum(res.result) : res.result,
      isError: !res.success);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(builder: (ctx, s, _) => Column(children: [
      // Σ / Π 切替
      Padding(
        padding: const EdgeInsets.fromLTRB(12,8,12,4),
        child: Row(children: [
          _toggle('Σ 和（シグマ）', true),
          const SizedBox(width: 8),
          _toggle('Π 積（パイ）', false),
        ])),
      // 入力
      Padding(
        padding: const EdgeInsets.fromLTRB(12,4,12,0),
        child: Column(children: [
          InputField(
            label: _isSigma ? 'Σ f(k) — 一般項' : 'Π f(k) — 一般項',
            value: s.field1, isActive: s.activeField == 'field1',
            onTap: () => s.setActiveField('field1'),
            placeholder: '例: k^2, 1/k, 2^k', accentColor: _color),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: InputField(label: '変数', value: s.field2,
              isActive: s.activeField == 'field2',
              onTap: () => s.setActiveField('field2'),
              placeholder: 'k', accentColor: _color)),
            const SizedBox(width: 8),
            Expanded(child: InputField(label: '下限（始点）', value: s.field3,
              isActive: s.activeField == 'field3',
              onTap: () => s.setActiveField('field3'),
              placeholder: '1', accentColor: _color)),
            const SizedBox(width: 8),
            Expanded(child: InputField(label: '上限（終点）', value: s.field4,
              isActive: s.activeField == 'field4',
              onTap: () => s.setActiveField('field4'),
              placeholder: '100', accentColor: _color)),
          ]),
        ])),
      // キーボード
      Expanded(child: _keyboard(ctx, s)),
    ]));
  }

  Widget _toggle(String label, bool val) {
    final active = _isSigma == val;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _isSigma = val); context.read<CalculatorState>().clearAll(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _color.withOpacity(0.5) : AppTheme.borderColor,
            width: active ? 1.5 : 1)),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? _color : AppTheme.textMuted)),
      ),
    ));
  }

  Widget _keyboard(BuildContext ctx, CalculatorState s) {
    void ap(String v) => s.appendToActive(v);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _r([_b('AC', cb.ButtonStyle.clear, s.clearAll),
            _b('⌫', cb.ButtonStyle.function, s.backspace),
            _b('(', cb.ButtonStyle.function, () => ap('(')),
            _b(')', cb.ButtonStyle.function, () => ap(')'))]),
        _r([_b('7', cb.ButtonStyle.number, () => ap('7')),
            _b('8', cb.ButtonStyle.number, () => ap('8')),
            _b('9', cb.ButtonStyle.number, () => ap('9')),
            _b('÷', cb.ButtonStyle.operator, () => ap('/'))]),
        _r([_b('4', cb.ButtonStyle.number, () => ap('4')),
            _b('5', cb.ButtonStyle.number, () => ap('5')),
            _b('6', cb.ButtonStyle.number, () => ap('6')),
            _b('×', cb.ButtonStyle.operator, () => ap('*'))]),
        _r([_b('1', cb.ButtonStyle.number, () => ap('1')),
            _b('2', cb.ButtonStyle.number, () => ap('2')),
            _b('3', cb.ButtonStyle.number, () => ap('3')),
            _b('+', cb.ButtonStyle.operator, () => ap('+'))]),
        _r([_b('0', cb.ButtonStyle.number, () => ap('0')),
            _b('.', cb.ButtonStyle.number, () => ap('.')),
            _b('^', cb.ButtonStyle.function, () => ap('^')),
            _b(_isSigma ? 'Σ' : 'Π', cb.ButtonStyle.action, () => _calc(ctx))]),
      ]),
    );
  }

  Widget _r(List<Widget> ch) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: ch.map((w) => Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList()));

  Widget _b(String l, cb.ButtonStyle st, VoidCallback fn) =>
    cb.CalcButton(label: l, style: st, onTap: fn, height: 62);
}

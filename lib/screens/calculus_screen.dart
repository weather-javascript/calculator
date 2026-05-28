// lib/screens/calculus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../core/engine/math_engine_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;
import '../widgets/multi_input_field.dart';

class CalculusScreen extends StatefulWidget {
  const CalculusScreen({super.key});
  @override
  State<CalculusScreen> createState() => _CalculusScreenState();
}

class _CalculusScreenState extends State<CalculusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isDiff = true;
  final _color = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      setState(() => _isDiff = _tab.index == 0);
      context.read<CalculatorState>().clearAll();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _calcDiff(BuildContext ctx) async {
    final s = ctx.read<CalculatorState>();
    final engine = MathEngineService();
    final expr = s.field1.trim();
    final v = s.field2.trim().isEmpty ? 'x' : s.field2.trim();
    if (expr.isEmpty) return;
    s.setCalculating(true);
    final res =
        await engine.differentiate(MathEngineService.preprocess(expr), v: v);
    s.setResult('d/d$v ($expr)', res.result, isError: !res.success);
  }

  Future<void> _calcInt(BuildContext ctx) async {
    final s = ctx.read<CalculatorState>();
    final engine = MathEngineService();
    final expr = s.field1.trim();
    final v = s.field2.trim().isEmpty ? 'x' : s.field2.trim();
    final lo = s.field3.trim(), hi = s.field4.trim();
    if (expr.isEmpty) return;
    s.setCalculating(true);
    final processed = MathEngineService.preprocess(expr);
    if (lo.isEmpty || hi.isEmpty) {
      s.setResult('∫($expr)d$v', '不定積分: ∫($expr)d$v + C\n（定積分は下限・上限を入力してください）');
    } else {
      final a = double.tryParse(lo), b = double.tryParse(hi);
      if (a == null || b == null) {
        s.setResult('', 'Error: 積分範囲が無効', isError: true);
        return;
      }
      final res = await engine.integrateNumerical(processed, a, b, v: v);
      s.setResult('∫[$lo→$hi]($expr)d$v',
          res.success ? MathEngineService.formatNum(res.result) : res.result,
          isError: !res.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
        builder: (ctx, s, _) => Column(children: [
              // タブ
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                      color: _color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _color.withOpacity(0.5))),
                  labelColor: _color,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  tabs: const [Tab(text: '微分  d/dx'), Tab(text: '積分  ∫')],
                ),
              ),
              // 入力
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _isDiff ? _diffInputs(s) : _intInputs(s)),
              // キーボード
              Expanded(child: _keyboard(ctx, s)),
            ]));
  }

  Widget _diffInputs(CalculatorState s) => Column(children: [
        InputField(
            label: 'f(x) — 微分する関数',
            value: s.field1,
            isActive: s.activeField == 'field1',
            onTap: () => s.setActiveField('field1'),
            placeholder: '例: x^3 + 2*x',
            accentColor: _color),
        const SizedBox(height: 8),
        InputField(
            label: '変数',
            value: s.field2,
            isActive: s.activeField == 'field2',
            onTap: () => s.setActiveField('field2'),
            placeholder: 'x',
            accentColor: _color),
      ]);

  Widget _intInputs(CalculatorState s) => Column(children: [
        InputField(
            label: 'f(x) — 積分する関数',
            value: s.field1,
            isActive: s.activeField == 'field1',
            onTap: () => s.setActiveField('field1'),
            placeholder: '例: x^2, sin(x)',
            accentColor: _color),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: InputField(
                  label: '変数',
                  value: s.field2,
                  isActive: s.activeField == 'field2',
                  onTap: () => s.setActiveField('field2'),
                  placeholder: 'x',
                  accentColor: _color)),
          const SizedBox(width: 8),
          Expanded(
              child: InputField(
                  label: '下限 a',
                  value: s.field3,
                  isActive: s.activeField == 'field3',
                  onTap: () => s.setActiveField('field3'),
                  placeholder: '省略=不定積分',
                  accentColor: _color)),
          const SizedBox(width: 8),
          Expanded(
              child: InputField(
                  label: '上限 b',
                  value: s.field4,
                  isActive: s.activeField == 'field4',
                  onTap: () => s.setActiveField('field4'),
                  placeholder: '省略=不定積分',
                  accentColor: _color)),
        ]),
      ]);

  Widget _keyboard(BuildContext ctx, CalculatorState s) {
    void ap(String v) => s.appendToActive(v);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _r([
          _b('AC', cb.ButtonStyle.clear, s.clearAll),
          _b('⌫', cb.ButtonStyle.function, s.backspace),
          _b('(', cb.ButtonStyle.function, () => ap('(')),
          _b(')', cb.ButtonStyle.function, () => ap(')'))
        ]),
        _r([
          _b('sin', cb.ButtonStyle.special, () => ap('sin(')),
          _b('cos', cb.ButtonStyle.special, () => ap('cos(')),
          _b('tan', cb.ButtonStyle.special, () => ap('tan(')),
          _b('π', cb.ButtonStyle.special, () => ap('pi'))
        ]),
        _r([
          _b('ln', cb.ButtonStyle.special, () => ap('log(')),
          _b('exp', cb.ButtonStyle.special, () => ap('exp(')),
          _b('√', cb.ButtonStyle.special, () => ap('sqrt(')),
          _b('^', cb.ButtonStyle.function, () => ap('^'))
        ]),
        _r([
          _b('7', cb.ButtonStyle.number, () => ap('7')),
          _b('8', cb.ButtonStyle.number, () => ap('8')),
          _b('9', cb.ButtonStyle.number, () => ap('9')),
          _b('*', cb.ButtonStyle.operator, () => ap('*'))
        ]),
        _r([
          _b('4', cb.ButtonStyle.number, () => ap('4')),
          _b('5', cb.ButtonStyle.number, () => ap('5')),
          _b('6', cb.ButtonStyle.number, () => ap('6')),
          _b('-', cb.ButtonStyle.operator, () => ap('-'))
        ]),
        _r([
          _b('1', cb.ButtonStyle.number, () => ap('1')),
          _b('2', cb.ButtonStyle.number, () => ap('2')),
          _b('3', cb.ButtonStyle.number, () => ap('3')),
          _b('+', cb.ButtonStyle.operator, () => ap('+'))
        ]),
        _r([
          _b('0', cb.ButtonStyle.number, () => ap('0')),
          _b('.', cb.ButtonStyle.number, () => ap('.')),
          _b('x', cb.ButtonStyle.function, () => ap('x')),
          _b(_isDiff ? 'd/dx' : '∫', cb.ButtonStyle.action,
              () => _isDiff ? _calcDiff(ctx) : _calcInt(ctx),
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
      cb.CalcButton(label: l, style: s, onTap: fn, height: 58, fontSize: fs);
}

// lib/features/limits/screens/limits_screen.dart
// 極限: lim x→a f(x)、左右極限、ロピタルの定理

import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';

enum LimitsTab { limit, lhopital }

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key});
  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  LimitsTab _mode = LimitsTab.limit;

  final _f = <String, String>{
    'expr': '',
    'point': '',
    'num': '',
    'den': '',
    'variable': '',
  };
  String _activeField = 'expr';
  String _direction = 'both'; // 'both' | 'left' | 'right'
  String _result = '';
  bool _isError = false;

  final _color = AppModes.colorOf(CalcMode.limits);

  // よく使う極限の例
  static const _examples = [
    ('sin(x)/x', 'x→0'),
    ('(1+1/x)^x', 'x→∞'),
    ('(x^2-1)/(x-1)', 'x→1'),
    ('x*sin(1/x)', 'x→0'),
    ('(exp(x)-1)/x', 'x→0'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {
          _mode = LimitsTab.values[_tab.index];
          _f.updateAll((_, __) => '');
          _result = '';
        }));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _ap(String v) =>
      setState(() => _f[_activeField] = _f[_activeField]! + v);
  void _bs() => setState(() {
        final c = _f[_activeField]!;
        if (c.isNotEmpty) _f[_activeField] = c.substring(0, c.length - 1);
      });

  Future<void> _calculate() async {
    final engine = MathEngineService();
    setState(() {
      _result = '';
    });

    final v = _f['variable']!.isEmpty ? 'x' : _f['variable']!;
    MathResult res;

    if (_mode == LimitsTab.limit) {
      final expr = MathEngineService.preprocess(_f['expr']!);
      final pt = _f['point']!.isEmpty ? '0' : _f['point']!;
      res = await engine.limit(expr, pt, v: v, direction: _direction);
    } else {
      final num = MathEngineService.preprocess(_f['num']!);
      final den = MathEngineService.preprocess(_f['den']!);
      final pt = _f['point']!.isEmpty ? '0' : _f['point']!;
      res = await engine.lhopital(num, den, pt, v: v);
    }

    setState(() {
      _result = res.result;
      _isError = !res.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabs(),
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _buildInputPanel()),
      if (_result.isNotEmpty) _buildResult(),
      // 例クイックボタン
      if (_mode == LimitsTab.limit) _buildExamples(),
      Expanded(child: _buildKeyboard()),
    ]);
  }

  Widget _buildTabs() {
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
          color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        for (int i = 0; i < 2; i++)
          Expanded(
              child: GestureDetector(
            onTap: () => _tab.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _tab.index == i
                    ? _color.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: _tab.index == i
                    ? Border.all(color: _color.withOpacity(0.5))
                    : null,
              ),
              child: Center(
                  child: Text(
                i == 0 ? 'lim x→a f(x)' : "ロピタルの定理",
                style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tab.index == i ? _color : AppTheme.textMuted),
              )),
            ),
          )),
      ]),
    );
  }

  Widget _buildInputPanel() {
    if (_mode == LimitsTab.limit) {
      return Column(children: [
        // 式
        _field('f(x) — 極限を求める関数', 'expr', hint: '例: sin(x)/x'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _field('収束点 a', 'point', hint: '例: 0, Infinity, pi')),
          const SizedBox(width: 8),
          Expanded(child: _field('変数 (省略可)', 'variable', hint: 'x')),
        ]),
        const SizedBox(height: 8),
        // 方向
        Row(children: [
          const Text('極限の方向:',
              style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 11,
                  color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          _dirBtn('両側', 'both'),
          const SizedBox(width: 6),
          _dirBtn('左 (x→a⁻)', 'left'),
          const SizedBox(width: 6),
          _dirBtn('右 (x→a⁺)', 'right'),
        ]),
      ]);
    } else {
      // ロピタル
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: const Text(
              'lim f(x)/g(x) = lim f\'(x)/g\'(x)\n（0/0 または ∞/∞ の不定形に適用）',
              style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 12,
                  color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        _field('分子 f(x)', 'num', hint: '例: sin(x)'),
        const SizedBox(height: 6),
        _field('分母 g(x)', 'den', hint: '例: x'),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _field('収束点 a', 'point', hint: '0')),
          const SizedBox(width: 8),
          Expanded(child: _field('変数', 'variable', hint: 'x')),
        ]),
      ]);
    }
  }

  Widget _field(String label, String key, {String hint = ''}) {
    final active = _activeField == key;
    return GestureDetector(
      onTap: () => setState(() => _activeField = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.08) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? _color.withOpacity(0.6) : AppTheme.borderColor,
              width: active ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600,
                  color: active ? _color : AppTheme.textMuted)),
          const SizedBox(height: 3),
          Text(_f[key]!.isEmpty ? hint : _f[key]!,
              style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 15,
                  color: _f[key]!.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _dirBtn(String label, String val) {
    final active = _direction == val;
    return GestureDetector(
      onTap: () => setState(() => _direction = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? _color.withOpacity(0.5) : AppTheme.borderColor,
              width: active ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                color: active ? _color : AppTheme.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _isError
                ? AppTheme.accentRed.withOpacity(0.08)
                : _color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _isError
                    ? AppTheme.accentRed.withOpacity(0.3)
                    : _color.withOpacity(0.3))),
        child: SelectableText(_result,
            style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 15,
                color: _isError ? AppTheme.accentRed : AppTheme.textPrimary)),
      ),
    );
  }

  Widget _buildExamples() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Wrap(
          spacing: 6,
          children: _examples
              .map((e) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _f['expr'] = e.$1;
                        _f['point'] = e.$2
                            .replaceAll('x→', '')
                            .replaceAll('∞', 'Infinity');
                        _activeField = 'expr';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _color.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _color.withOpacity(0.25))),
                      child: Text('${e.$1}  ${e.$2}',
                          style: TextStyle(
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 11,
                              color: _color)),
                    ),
                  ))
              .toList()),
    );
  }

  Widget _buildKeyboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _kr([
          _k('AC', () {
            setState(() {
              _f.updateAll((k, _) => '');
              _result = '';
            });
          }, r: true),
          _k('⌫', _bs, o: true),
          _k('(', () => _ap('(')),
          _k(')', () => _ap(')')),
        ]),
        _kr([
          _k('∞', () => _ap('Infinity'), b: true),
          _k('π', () => _ap('pi'), b: true),
          _k('e', () => _ap('e'), b: true),
          _k('^', () => _ap('^'), o: true),
        ]),
        _kr([
          _k('7', () => _ap('7')),
          _k('8', () => _ap('8')),
          _k('9', () => _ap('9')),
          _k('/', () => _ap('/'), o: true),
        ]),
        _kr([
          _k('4', () => _ap('4')),
          _k('5', () => _ap('5')),
          _k('6', () => _ap('6')),
          _k('*', () => _ap('*'), o: true),
        ]),
        _kr([
          _k('1', () => _ap('1')),
          _k('2', () => _ap('2')),
          _k('3', () => _ap('3')),
          _k('-', () => _ap('-'), o: true),
        ]),
        _kr([
          _k('0', () => _ap('0')),
          _k('.', () => _ap('.')),
          _k('+', () => _ap('+'), o: true),
          _k('lim', _calculate, a: true),
        ]),
      ]),
    );
  }

  Widget _kr(List<Widget> ch) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
            children: ch
                .map((w) => Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: w),
                    ))
                .toList()),
      );

  Widget _k(String lbl, VoidCallback fn,
      {bool r = false, bool o = false, bool b = false, bool a = false}) {
    Color bg, fg;
    if (a) {
      bg = _color.withOpacity(0.85);
      fg = AppTheme.textPrimary;
    } else if (r) {
      bg = AppTheme.btnClear;
      fg = const Color(0xFFFFCDD2);
    } else if (o) {
      bg = AppTheme.btnOperator;
      fg = AppTheme.accentCyan;
    } else if (b) {
      bg = AppTheme.btnSpecial;
      fg = const Color(0xFFE9D5FF);
    } else {
      bg = AppTheme.btnNumber;
      fg = AppTheme.textPrimary;
    }
    return GestureDetector(
      onTap: fn,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4)
          ],
        ),
        child: Center(
            child: Text(lbl,
                style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg))),
      ),
    );
  }
}

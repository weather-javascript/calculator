// lib/features/algebra/screens/algebra_screen.dart
// 代数・方程式: 展開・因数分解・2次方程式・連立方程式

import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/algebra_keyboard.dart';

enum AlgebraTab { expand, factor, quadratic, linear2, equation }

class AlgebraScreen extends StatefulWidget {
  const AlgebraScreen({super.key});
  @override
  State<AlgebraScreen> createState() => _AlgebraScreenState();
}

class _AlgebraScreenState extends State<AlgebraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  AlgebraTab _current = AlgebraTab.expand;

  // input fields
  final Map<String, String> _fields = {
    'main': '',
    'a': '',
    'b': '',
    'c': '',
    'a1': '',
    'b1': '',
    'c1': '',
    'a2': '',
    'b2': '',
    'c2': '',
    'lhs': '',
    'rhs': '',
  };
  String _activeField = 'main';
  String _result = '';
  bool _isError = false;
  bool _loading = false;

  final _color = AppModes.colorOf(CalcMode.algebra);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: AlgebraTab.values.length, vsync: this);
    _tab.addListener(() {
      setState(() {
        _current = AlgebraTab.values[_tab.index];
        _fields.updateAll((_, __) => '');
        _activeField = 'main';
        _result = '';
      });
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _append(String v) =>
      setState(() => _fields[_activeField] = (_fields[_activeField]! + v));
  void _backspace() => setState(() {
        final cur = _fields[_activeField]!;
        if (cur.isNotEmpty) {
          _fields[_activeField] = cur.substring(0, cur.length - 1);
        }
      });
  void _clearAll() => setState(() {
        _fields.updateAll((_, __) => '');
        _result = '';
      });

  Future<void> _calculate() async {
    final engine = MathEngineService();
    setState(() {
      _loading = true;
      _result = '';
    });
    MathResult res;

    switch (_current) {
      case AlgebraTab.expand:
        res =
            await engine.expand(MathEngineService.preprocess(_fields['main']!));
        break;
      case AlgebraTab.factor:
        res =
            await engine.factor(MathEngineService.preprocess(_fields['main']!));
        break;
      case AlgebraTab.quadratic:
        final a = double.tryParse(_fields['a']!) ?? 0;
        final b = double.tryParse(_fields['b']!) ?? 0;
        final c = double.tryParse(_fields['c']!) ?? 0;
        res = await engine.quadratic(a, b, c);
        break;
      case AlgebraTab.linear2:
        res = await engine.solveLinear2(
          double.tryParse(_fields['a1']!) ?? 0,
          double.tryParse(_fields['b1']!) ?? 0,
          double.tryParse(_fields['c1']!) ?? 0,
          double.tryParse(_fields['a2']!) ?? 0,
          double.tryParse(_fields['b2']!) ?? 0,
          double.tryParse(_fields['c2']!) ?? 0,
        );
        break;
      case AlgebraTab.equation:
        res = await engine.solveEquation(
          MathEngineService.preprocess(_fields['lhs']!),
          rhs: _fields['rhs']!.isEmpty
              ? '0'
              : MathEngineService.preprocess(_fields['rhs']!),
        );
        break;
    }
    setState(() {
      _loading = false;
      _result = res.result;
      _isError = !res.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // タブバー
      _buildTabBar(),
      // 入力パネル
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: _buildInputPanel(),
      ),
      // 結果表示
      if (_result.isNotEmpty || _loading) _buildResult(),
      // キーボード
      Expanded(
          child: AlgebraKeyboard(
        onAppend: _append,
        onBackspace: _backspace,
        onClear: _clearAll,
        onCalculate: _calculate,
        loading: _loading,
        accentColor: _color,
        activeField: _activeField,
        mode: _current,
        onFieldSelect: (f) => setState(() => _activeField = f),
      )),
    ]);
  }

  Widget _buildTabBar() {
    const labels = ['展開', '因数分解', '2次方程式', '連立', '方程式'];
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AlgebraTab.values.length,
        itemBuilder: (ctx, i) {
          final active = _tab.index == i;
          return GestureDetector(
            onTap: () => _tab.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      active ? _color.withOpacity(0.6) : AppTheme.borderColor,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _color : AppTheme.textMuted,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputPanel() {
    switch (_current) {
      case AlgebraTab.expand:
      case AlgebraTab.factor:
        return _singleField('式を入力', 'main', '例: (x+2)^2, x^3-8');
      case AlgebraTab.quadratic:
        return _quadraticFields();
      case AlgebraTab.linear2:
        return _linear2Fields();
      case AlgebraTab.equation:
        return _equationFields();
    }
  }

  Widget _singleField(String label, String key, String placeholder) {
    final active = _activeField == key;
    return GestureDetector(
      onTap: () => setState(() => _activeField = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.08) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _color.withOpacity(0.6) : AppTheme.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? _color : AppTheme.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 4),
          Text(_fields[key]!.isEmpty ? placeholder : _fields[key]!,
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 16,
                color: _fields[key]!.isEmpty
                    ? AppTheme.textMuted
                    : AppTheme.textPrimary,
              )),
        ]),
      ),
    );
  }

  Widget _quadraticFields() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withOpacity(0.2)),
        ),
        child: const Text('ax² + bx + c = 0',
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _miniField('a', 'a', '係数a')),
        const SizedBox(width: 8),
        Expanded(child: _miniField('b', 'b', '係数b')),
        const SizedBox(width: 8),
        Expanded(child: _miniField('c', 'c', '定数c')),
      ]),
    ]);
  }

  Widget _linear2Fields() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('a₁x + b₁y = c₁\na₂x + b₂y = c₂',
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _miniField('a₁', 'a1', 'a₁')),
        const SizedBox(width: 6),
        Expanded(child: _miniField('b₁', 'b1', 'b₁')),
        const SizedBox(width: 6),
        Expanded(child: _miniField('c₁', 'c1', 'c₁')),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: _miniField('a₂', 'a2', 'a₂')),
        const SizedBox(width: 6),
        Expanded(child: _miniField('b₂', 'b2', 'b₂')),
        const SizedBox(width: 6),
        Expanded(child: _miniField('c₂', 'c2', 'c₂')),
      ]),
    ]);
  }

  Widget _equationFields() {
    return Row(children: [
      Expanded(child: _miniField('左辺 f(x)', 'lhs', 'x^2-4')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('=',
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 20,
              color: _color,
            )),
      ),
      Expanded(child: _miniField('右辺 g(x)', 'rhs', '0')),
    ]);
  }

  Widget _miniField(String label, String key, String placeholder) {
    final active = _activeField == key;
    return GestureDetector(
      onTap: () => setState(() => _activeField = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.08) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _color.withOpacity(0.6) : AppTheme.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Space Grotesk',
                  color: active ? _color : AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(_fields[key]!.isEmpty ? placeholder : _fields[key]!,
              style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'IBM Plex Mono',
                  color: _fields[key]!.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
                : _color.withOpacity(0.3),
          ),
        ),
        child: _loading
            ? Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_color))))
            : SelectableText(_result,
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 16,
                  color: _isError ? AppTheme.accentRed : AppTheme.textPrimary,
                )),
      ),
    );
  }
}

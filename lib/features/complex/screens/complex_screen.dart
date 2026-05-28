// lib/features/complex/screens/complex_screen.dart
// 複素数: 四則演算・絶対値・偏角・極形式・複素数式評価

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';

enum ComplexTab { arithmetic, polar, eval }

class ComplexScreen extends StatefulWidget {
  const ComplexScreen({super.key});
  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  ComplexTab _mode = ComplexTab.arithmetic;

  // z1 = re1 + im1*i, z2 = re2 + im2*i
  final _f = <String, String>{
    're1': '',
    'im1': '',
    're2': '',
    'im2': '',
    'r': '',
    'theta': '',
    'expr': '',
  };
  String _activeField = 're1';
  String _operation = 'add'; // add/sub/mul/div/abs/arg/conj/pow/sqrt/toPolar
  String _result = '';
  bool _isError = false;
  String _polarUnit = 'rad';

  final _color = AppModes.colorOf(CalcMode.complex);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {
          _mode = ComplexTab.values[_tab.index];
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
      setState(() => _f[_activeField] = (_f[_activeField]! + v));
  void _bs() => setState(() {
        final c = _f[_activeField]!;
        if (c.isNotEmpty) _f[_activeField] = c.substring(0, c.length - 1);
      });

  double _d(String key) => double.tryParse(_f[key]!) ?? 0;

  Future<void> _calculate() async {
    final engine = MathEngineService();
    MathResult res;

    if (_mode == ComplexTab.eval) {
      res = await engine.complexEval(_f['expr']!);
    } else if (_mode == ComplexTab.polar) {
      if (_operation == 'fromPolar') {
        res = await engine.complexFromPolar(_d('r'), _d('theta'),
            unit: _polarUnit);
        if (res.success) {
          try {
            final j = jsonDecode(res.result) as Map<String, dynamic>;
            res = MathResult(
                success: true, result: '直交形式: ${j['re']} + ${j['im']}i');
          } catch (_) {}
        }
      } else {
        res = await engine.complexToPolar(_d('re1'), _d('im1'));
        if (res.success) {
          try {
            final j = jsonDecode(res.result) as Map<String, dynamic>;
            res = MathResult(
                success: true,
                result:
                    'r = ${j['r']}\nθ = ${j['theta_rad']} rad = ${j['theta_deg']}°\n${j['polar']}');
          } catch (_) {}
        }
      }
    } else {
      switch (_operation) {
        case 'add':
          res = await engine.complexAdd(
              _d('re1'), _d('im1'), _d('re2'), _d('im2'));
          break;
        case 'sub':
          res = await engine.complexSub(
              _d('re1'), _d('im1'), _d('re2'), _d('im2'));
          break;
        case 'mul':
          res = await engine.complexMul(
              _d('re1'), _d('im1'), _d('re2'), _d('im2'));
          break;
        case 'div':
          res = await engine.complexDiv(
              _d('re1'), _d('im1'), _d('re2'), _d('im2'));
          break;
        case 'abs':
          res = await engine.complexAbs(_d('re1'), _d('im1'));
          break;
        case 'arg':
          res = await engine.complexArg(_d('re1'), _d('im1'));
          break;
        case 'conj':
          res = await engine.complexConj(_d('re1'), _d('im1'));
          break;
        case 'pow':
          res = await engine.complexPow(_d('re1'), _d('im1'), _d('re2'));
          break;
        case 'sqrt':
          res = await engine.complexSqrt(_d('re1'), _d('im1'));
          break;
        default:
          res = MathResult.error('Unknown operation');
      }
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
          child: _buildPanel()),
      if (_result.isNotEmpty) _buildResult(),
      Expanded(child: _buildKeyboard()),
    ]);
  }

  Widget _buildTabs() {
    const labels = ['演算', '極形式', '式評価'];
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
          color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(10)),
      child: Row(
          children: List.generate(3, (i) {
        final active = _tab.index == i;
        return Expanded(
            child: GestureDetector(
          onTap: () => _tab.animateTo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: active ? _color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  active ? Border.all(color: _color.withOpacity(0.5)) : null,
            ),
            child: Center(
                child: Text(labels[i],
                    style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? _color : AppTheme.textMuted))),
          ),
        ));
      })),
    );
  }

  Widget _buildPanel() {
    switch (_mode) {
      case ComplexTab.arithmetic:
        return _arithmeticPanel();
      case ComplexTab.polar:
        return _polarPanel();
      case ComplexTab.eval:
        return _evalPanel();
    }
  }

  Widget _arithmeticPanel() {
    final needs2 = ['add', 'sub', 'mul', 'div', 'pow'].contains(_operation);
    return Column(children: [
      // 演算選択
      Wrap(spacing: 6, children: [
        for (final op in [
          'add',
          'sub',
          'mul',
          'div',
          'abs',
          'arg',
          'conj',
          'pow',
          'sqrt'
        ])
          _opChip(op, _opLabel(op)),
      ]),
      const SizedBox(height: 8),
      // z1
      Row(children: [
        Expanded(child: _field('z₁ 実部', 're1')),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('+', style: TextStyle(color: _color, fontSize: 16))),
        Expanded(child: _field('z₁ 虚部', 'im1')),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('i',
                style: TextStyle(
                    color: _color, fontSize: 16, fontWeight: FontWeight.bold))),
      ]),
      if (needs2) ...[
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: _field(_operation == 'pow' ? '指数 n' : 'z₂ 実部',
                  _operation == 'pow' ? 're2' : 're2')),
          if (_operation != 'pow') ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child:
                    Text('+', style: TextStyle(color: _color, fontSize: 16))),
            Expanded(child: _field('z₂ 虚部', 'im2')),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('i',
                    style: TextStyle(
                        color: _color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
          ],
        ]),
      ],
    ]);
  }

  Widget _polarPanel() {
    return Column(children: [
      Row(children: [
        _toggleOp('直交→極', 'toPolar'),
        const SizedBox(width: 8),
        _toggleOp('極→直交', 'fromPolar'),
        const Spacer(),
        _unitToggle(),
      ]),
      const SizedBox(height: 8),
      if (_operation != 'fromPolar')
        Row(children: [
          Expanded(child: _field('実部 a', 're1')),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('+', style: TextStyle(color: _color, fontSize: 16))),
          Expanded(child: _field('虚部 b', 'im1')),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('i', style: TextStyle(color: _color, fontSize: 16))),
        ])
      else
        Row(children: [
          Expanded(child: _field('絶対値 r', 'r')),
          const SizedBox(width: 8),
          Expanded(child: _field('偏角 θ', 'theta')),
        ]),
    ]);
  }

  Widget _evalPanel() {
    return _field('複素数式（例: (1+2i)^3, sqrt(-1)）', 'expr');
  }

  Widget _field(String label, String key) {
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
              width: active ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active ? _color : AppTheme.textMuted,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_f[key]!.isEmpty ? '0' : _f[key]!,
              style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 15,
                  color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _opChip(String op, String label) {
    final active = _operation == op;
    return GestureDetector(
      onTap: () => setState(() {
        _operation = op;
        _result = '';
      }),
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
                fontFamily: 'IBM Plex Mono',
                fontSize: 12,
                color: active ? _color : AppTheme.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _toggleOp(String label, String op) {
    final active = _operation == op;
    return GestureDetector(
      onTap: () => setState(() => _operation = op),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? _color.withOpacity(0.5) : AppTheme.borderColor,
                width: active ? 1.5 : 1)),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                color: active ? _color : AppTheme.textMuted)),
      ),
    );
  }

  Widget _unitToggle() {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: ['rad', 'deg'].map((u) {
          final active = _polarUnit == u;
          return GestureDetector(
            onTap: () => setState(() => _polarUnit = u),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color:
                      active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: active
                          ? _color.withOpacity(0.4)
                          : AppTheme.borderColor)),
              child: Text(u,
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? _color : AppTheme.textMuted,
                      fontFamily: 'IBM Plex Mono')),
            ),
          );
        }).toList());
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
                fontSize: 16,
                color: _isError ? AppTheme.accentRed : AppTheme.textPrimary)),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _kr([
          _k('AC', () {
            setState(() {
              _f.updateAll((_, __) => '');
              _result = '';
            });
          }, r: true),
          _k('⌫', _bs, o: true),
          _k('.', () => _ap('.')),
          _k('-', () => _ap('-'), o: true)
        ]),
        _kr([
          _k('7', () => _ap('7')),
          _k('8', () => _ap('8')),
          _k('9', () => _ap('9')),
          _k('÷', () => _ap('/'), o: true)
        ]),
        _kr([
          _k('4', () => _ap('4')),
          _k('5', () => _ap('5')),
          _k('6', () => _ap('6')),
          _k('×', () => _ap('*'), o: true)
        ]),
        _kr([
          _k('1', () => _ap('1')),
          _k('2', () => _ap('2')),
          _k('3', () => _ap('3')),
          _k('+', () => _ap('+'), o: true)
        ]),
        _kr([
          _k('0', () => _ap('0'), f: 2),
          _k('計算', _calculate, a: true, f: 2)
        ]),
      ]),
    );
  }

  Widget _kr(List<Widget> ch) => Padding(
      padding: const EdgeInsets.only(bottom: 8), child: Row(children: ch));

  Widget _k(String lbl, VoidCallback fn,
      {bool r = false, bool o = false, bool a = false, int f = 1}) {
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
    } else {
      bg = AppTheme.btnNumber;
      fg = AppTheme.textPrimary;
    }
    return Expanded(
        flex: f,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
                onTap: fn,
                child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.4))),
                    child: Center(
                        child: Text(lbl,
                            style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: fg)))))));
  }

  String _opLabel(String op) {
    const m = {
      'add': '+',
      'sub': '−',
      'mul': '×',
      'div': '÷',
      'abs': '|z|',
      'arg': 'arg',
      'conj': 'z̄',
      'pow': 'zⁿ',
      'sqrt': '√z'
    };
    return m[op] ?? op;
  }
}

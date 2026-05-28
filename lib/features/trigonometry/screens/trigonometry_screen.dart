// lib/features/trigonometry/screens/trigonometry_screen.dart
// 三角関数: sin/cos/tan・逆三角関数・弧度法⇔度数法・特殊角一覧

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';

class TrigonometryScreen extends StatefulWidget {
  const TrigonometryScreen({super.key});
  @override
  State<TrigonometryScreen> createState() => _TrigonometryScreenState();
}

class _TrigonometryScreenState extends State<TrigonometryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _unit = 'deg'; // 'deg' | 'rad'
  String _input = '';
  String _input2 = ''; // atan2 の y
  String _result = '';
  bool _isError = false;
  List<Map<String, dynamic>> _specialRows = [];
  bool _showSpecial = false;

  final _color = AppModes.colorOf(CalcMode.trigonometry);

  final _fns = [
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'atan2',
    'deg↔rad'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _fns.length, vsync: this);
    _tab.addListener(() => setState(() {
          _input = '';
          _input2 = '';
          _result = '';
        }));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _append(String v) => setState(() => _input += v);
  void _backspace() => setState(() {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      });

  Future<void> _calculate() async {
    final engine = MathEngineService();
    final fn = _fns[_tab.index];
    MathResult res;
    switch (fn) {
      case 'sin':
        res = await engine.trigSin(_input, unit: _unit);
        break;
      case 'cos':
        res = await engine.trigCos(_input, unit: _unit);
        break;
      case 'tan':
        res = await engine.trigTan(_input, unit: _unit);
        break;
      case 'asin':
        res = await engine.trigAsin(_input, unit: _unit);
        break;
      case 'acos':
        res = await engine.trigAcos(_input, unit: _unit);
        break;
      case 'atan':
        res = await engine.trigAtan(_input, unit: _unit);
        break;
      case 'atan2':
        res = await engine.trigAtan2(_input2, _input, unit: _unit);
        break;
      case 'deg↔rad':
        if (_unit == 'deg') {
          res = await engine.degToRad(_input);
        } else {
          res = await engine.radToDeg(_input);
        }
        break;
      default:
        res = MathResult.error('Unknown');
    }
    setState(() {
      _result = res.result;
      _isError = !res.success;
    });
  }

  Future<void> _loadSpecialValues(String fn) async {
    if (!['sin', 'cos', 'tan'].contains(fn)) return;
    final engine = MathEngineService();
    final res = await engine.trigSpecialValues(fn);
    if (res.success) {
      final raw = jsonDecode(res.result) as List;
      setState(() {
        _specialRows = raw.map((e) => e as Map<String, dynamic>).toList();
        _showSpecial = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 関数タブ
      _buildFnTabs(),
      // ラジアン/度数 切り替え
      _buildUnitToggle(),
      // 入力エリア
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _buildInput(),
      ),
      // 結果
      if (_result.isNotEmpty) _buildResult(),
      // キーボード
      Expanded(child: _buildKeyboard()),
    ]);
  }

  Widget _buildFnTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fns.length,
        itemBuilder: (ctx, i) {
          final active = _tab.index == i;
          return GestureDetector(
            onTap: () {
              _tab.animateTo(i);
              setState(() {
                _showSpecial = false;
              });
            },
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
              child: Text(_fns[i],
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? _color : AppTheme.textMuted,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(children: [
        const Text('角度単位:',
            style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                color: AppTheme.textSecondary)),
        const SizedBox(width: 10),
        _unitBtn('度 (°)', 'deg'),
        const SizedBox(width: 8),
        _unitBtn('ラジアン (rad)', 'rad'),
        const Spacer(),
        if (['sin', 'cos', 'tan'].contains(_fns[_tab.index]))
          GestureDetector(
            onTap: () => _loadSpecialValues(_fns[_tab.index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _color.withOpacity(0.3)),
              ),
              child: Text('特殊角一覧',
                  style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      color: _color)),
            ),
          ),
      ]),
    );
  }

  Widget _unitBtn(String label, String value) {
    final active = _unit == value;
    return GestureDetector(
      onTap: () => setState(() => _unit = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _color.withOpacity(0.5) : AppTheme.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 12,
              color: active ? _color : AppTheme.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildInput() {
    final fn = _fns[_tab.index];
    if (fn == 'atan2') {
      return Row(children: [
        Expanded(child: _inputBox('y', _input2, onTap: () {}, isSecond: true)),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(',',
                style: TextStyle(fontSize: 20, color: AppTheme.textSecondary))),
        Expanded(child: _inputBox('x', _input, onTap: () {})),
      ]);
    }
    final hint = fn == 'deg↔rad'
        ? (_unit == 'deg' ? '角度（度）を入力' : 'ラジアンを入力')
        : (_unit == 'deg' ? '角度（度）を入力' : 'ラジアン値を入力');
    return _inputBox(fn == 'deg↔rad' ? '値' : '引数', _input,
        hint: hint, onTap: () {});
  }

  Widget _inputBox(
    String label,
    String value, {
    String? hint,
    VoidCallback? onTap,
    bool isSecond = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: _color,
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? (hint ?? '入力してください') : value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 18,
              color: value.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
            )),
      ]),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(children: [
        Container(
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
                    : _color.withOpacity(0.3)),
          ),
          child: Text(_result,
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _isError ? AppTheme.accentRed : AppTheme.textPrimary,
              )),
        ),
        if (_showSpecial) ...[
          const SizedBox(height: 8),
          _specialTable(),
        ],
      ]),
    );
  }

  Widget _specialTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
                child: Text('角度(°)',
                    style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: _color,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text('ラジアン',
                    style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: _color,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text('値',
                    style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: _color,
                        fontWeight: FontWeight.w600))),
          ]),
        ),
        ..._specialRows
            .take(8)
            .map((row) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppTheme.divider, width: 1))),
                  child: Row(children: [
                    Expanded(
                        child: Text('${row['deg']}°',
                            style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 12,
                                color: AppTheme.textSecondary))),
                    Expanded(
                        child: Text('${row['rad_approx']}',
                            style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 11,
                                color: AppTheme.textMuted))),
                    Expanded(
                        child: Text('${row['val']}',
                            style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600))),
                  ]),
                ))
            .toList(),
      ]),
    );
  }

  Widget _buildKeyboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        _krow([
          _k('AC', () {
            setState(() {
              _input = '';
              _input2 = '';
              _result = '';
              _showSpecial = false;
            });
          }, isRed: true),
          _k('⌫', _backspace, isOrange: true),
          _k('π', () => _append('pi'), isBlue: true),
          _k('e', () => _append('e'), isBlue: true),
        ]),
        _krow([
          _k('7', () => _append('7')),
          _k('8', () => _append('8')),
          _k('9', () => _append('9')),
          _k('/', () => _append('/'), isOrange: true),
        ]),
        _krow([
          _k('4', () => _append('4')),
          _k('5', () => _append('5')),
          _k('6', () => _append('6')),
          _k('*', () => _append('*'), isOrange: true),
        ]),
        _krow([
          _k('1', () => _append('1')),
          _k('2', () => _append('2')),
          _k('3', () => _append('3')),
          _k('-', () => _append('-'), isOrange: true),
        ]),
        _krow([
          _k('0', () => _append('0')),
          _k('.', () => _append('.')),
          _k('-', () => _append('-')),
          _k(_fns[_tab.index], _calculate, isAction: true),
        ]),
      ]),
    );
  }

  Widget _krow(List<Widget> ch) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
            children: ch
                .map((w) => Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: w)))
                .toList()),
      );

  Widget _k(String label, VoidCallback onTap,
      {bool isRed = false,
      bool isOrange = false,
      bool isBlue = false,
      bool isAction = false}) {
    Color bg, fg;
    if (isAction) {
      bg = _color.withOpacity(0.85);
      fg = AppTheme.textPrimary;
    } else if (isRed) {
      bg = AppTheme.btnClear;
      fg = const Color(0xFFFFCDD2);
    } else if (isOrange) {
      bg = AppTheme.btnOperator;
      fg = AppTheme.accentCyan;
    } else if (isBlue) {
      bg = AppTheme.btnSpecial;
      fg = const Color(0xFFE9D5FF);
    } else {
      bg = AppTheme.btnNumber;
      fg = AppTheme.textPrimary;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg))),
      ),
    );
  }
}

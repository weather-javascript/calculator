// lib/features/number_theory/screens/number_theory_screen.dart
// 整数の性質: 素因数分解・GCD・LCM・素数判定・n進法・ユークリッド互除法

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';

enum NumThTab { factor, gcdlcm, baseConvert, primeCheck, euclid }

class NumberTheoryScreen extends StatefulWidget {
  const NumberTheoryScreen({super.key});
  @override State<NumberTheoryScreen> createState() => _NumberTheoryScreenState();
}

class _NumberTheoryScreenState extends State<NumberTheoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  NumThTab _mode = NumThTab.factor;

  final _f = <String, String>{
    'n': '', 'a': '', 'b': '', 'value': '', 'sieveLimit': '',
  };
  int _fromBase = 10, _toBase = 2;
  String _result = '';
  List<dynamic> _primeList = [];
  bool _isError = false;
  bool _loading = false;

  final _color = AppModes.colorOf(CalcMode.numberTheory);

  static const _tabLabels = ['素因数分解', 'GCD/LCM', 'n進法', '素数判定', '互除法'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: NumThTab.values.length, vsync: this);
    _tab.addListener(() => setState(() {
      _mode = NumThTab.values[_tab.index];
      _f.updateAll((_, __) => '');
      _result = '';
      _primeList = [];
    }));
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  void _ap(String key, String v) => setState(() => _f[key] = _f[key]! + v);
  void _bs(String key) => setState(() {
    if (_f[key]!.isNotEmpty) {
      _f[key] = _f[key]!.substring(0, _f[key]!.length - 1);
    }
  });

  Future<void> _calculate() async {
    final engine = MathEngineService();
    setState(() { _loading = true; _result = ''; _primeList = []; });
    MathResult res;

    switch (_mode) {
      case NumThTab.factor:
        final n = int.tryParse(_f['n']!) ?? 0;
        res = await engine.primeFactorize(n);
        break;
      case NumThTab.gcdlcm:
        final a = int.tryParse(_f['a']!) ?? 0;
        final b = int.tryParse(_f['b']!) ?? 0;
        final gcdRes = await engine.gcd(a, b);
        final lcmRes = await engine.lcm(a, b);
        res = MathResult(
          success: gcdRes.success && lcmRes.success,
          result: 'GCD(${_f['a']}, ${_f['b']}) = ${gcdRes.result}\n'
                  'LCM(${_f['a']}, ${_f['b']}) = ${lcmRes.result}',
        );
        break;
      case NumThTab.baseConvert:
        res = await engine.baseConvert(_f['value']!, _fromBase, _toBase);
        if (res.success) {
          res = MathResult(success: true,
            result: '${_f['value']!} ($_fromBase進) = ${res.result} ($_toBase進)');
        }
        break;
      case NumThTab.primeCheck:
        final n = int.tryParse(_f['n']!) ?? 0;
        final isPrime = await engine.isPrime(n);
        // エラトステネスの篩
        final limit = n.clamp(2, 200);
        final sieveRes = await engine.sieve(limit);
        if (sieveRes.success) {
          try { _primeList = jsonDecode(sieveRes.result) as List; } catch (_) {}
        }
        res = MathResult(
          success: isPrime.success,
          result: '$n は${isPrime.result == 'true' ? '素数 ✓' : '素数ではない ✗'}',
        );
        break;
      case NumThTab.euclid:
        final a = int.tryParse(_f['a']!) ?? 0;
        final b = int.tryParse(_f['b']!) ?? 0;
        res = await engine.euclidSteps(a, b);
        if (res.success) {
          try {
            final j = jsonDecode(res.result) as Map<String, dynamic>;
            final steps = (j['steps'] as List).join('\n');
            res = MathResult(success: true,
              result: '$steps\n\n→ GCD(${_f['a']}, ${_f['b']}) = ${j['gcd']}');
          } catch (_) {}
        }
        break;
    }

    setState(() { _loading = false; _result = res.result; _isError = !res.success; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabs(),
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12,8,12,0), child: _buildPanel()),
        if (_result.isNotEmpty) _buildResult(),
        if (_primeList.isNotEmpty) _buildPrimeGrid(),
        const SizedBox(height: 8),
      ]))),
      // 数字キーボード
      _buildKeyboard(),
    ]);
  }

  Widget _buildTabs() {
    return Container(
      height: 38, margin: const EdgeInsets.fromLTRB(12,6,12,0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabLabels.length,
        itemBuilder: (_, i) {
          final active = _tab.index == i;
          return GestureDetector(
            onTap: () => _tab.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _color.withOpacity(0.6) : AppTheme.borderColor,
                  width: active ? 1.5 : 1)),
              child: Text(_tabLabels[i], style: TextStyle(
                fontFamily: 'Space Grotesk', fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? _color : AppTheme.textMuted)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanel() {
    switch (_mode) {
      case NumThTab.factor:
      case NumThTab.primeCheck:
        return _singleNInput();
      case NumThTab.gcdlcm:
      case NumThTab.euclid:
        return _dualInput();
      case NumThTab.baseConvert:
        return _baseConvertPanel();
    }
  }

  Widget _singleNInput() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
        child: Text(
          _mode == NumThTab.factor
            ? '整数 n を素因数分解します\n例: 360 = 2³ × 3² × 5'
            : '整数 n が素数かどうか判定します',
          style: const TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 12,
            color: AppTheme.textSecondary),
          textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      _inputBox('整数 n', 'n', '例: 360'),
    ]);
  }

  Widget _dualInput() {
    return Row(children: [
      Expanded(child: _inputBox('整数 a', 'a', '例: 48')),
      const SizedBox(width: 12),
      Expanded(child: _inputBox('整数 b', 'b', '例: 18')),
    ]);
  }

  Widget _baseConvertPanel() {
    final bases = [2, 8, 10, 16];
    final baseLabels = {2: '2進', 8: '8進', 10: '10進', 16: '16進'};
    return Column(children: [
      _inputBox('変換する値', 'value', '例: 255'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('変換元', style: TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 11, color: _color)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: bases.map((b) => GestureDetector(
              onTap: () => setState(() => _fromBase = b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _fromBase == b ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _fromBase == b ? _color.withOpacity(0.5) : AppTheme.borderColor,
                    width: _fromBase == b ? 1.5 : 1)),
                child: Text(baseLabels[b]!, style: TextStyle(
                  fontFamily: 'IBM Plex Mono', fontSize: 12,
                  color: _fromBase == b ? _color : AppTheme.textMuted)),
              ),
            )).toList()),
          ],
        )),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('変換先', style: TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 11, color: _color)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: bases.map((b) => GestureDetector(
              onTap: () => setState(() => _toBase = b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _toBase == b ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _toBase == b ? _color.withOpacity(0.5) : AppTheme.borderColor,
                    width: _toBase == b ? 1.5 : 1)),
                child: Text(baseLabels[b]!, style: TextStyle(
                  fontFamily: 'IBM Plex Mono', fontSize: 12,
                  color: _toBase == b ? _color : AppTheme.textMuted)),
              ),
            )).toList()),
          ],
        )),
      ]),
    ]);
  }

  Widget _inputBox(String label, String key, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.4), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 10, color: _color,
          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(_f[key]!.isEmpty ? hint : _f[key]!, style: TextStyle(
          fontFamily: 'IBM Plex Mono', fontSize: 18,
          color: _f[key]!.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary)),
      ]),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12,8,12,0),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isError ? AppTheme.accentRed.withOpacity(0.08) : _color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isError ? AppTheme.accentRed.withOpacity(0.3) : _color.withOpacity(0.3))),
        child: SelectableText(_result, style: TextStyle(
          fontFamily: 'IBM Plex Mono', fontSize: 15, height: 1.6,
          color: _isError ? AppTheme.accentRed : AppTheme.textPrimary)),
      ),
    );
  }

  Widget _buildPrimeGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12,8,12,0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('200以下の素数一覧', style: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 11, color: _color,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: _primeList.take(46).map((p) {
          final n = int.tryParse(_f['n']!) ?? 0;
          final isTarget = p == n;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTarget ? _color.withOpacity(0.3) : _color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isTarget ? _color : _color.withOpacity(0.2),
                width: isTarget ? 1.5 : 1)),
            child: Text('$p', style: TextStyle(
              fontFamily: 'IBM Plex Mono', fontSize: 12,
              color: isTarget ? _color : AppTheme.textSecondary,
              fontWeight: isTarget ? FontWeight.w700 : FontWeight.normal)),
          );
        }).toList()),
      ]),
    );
  }

  // 入力フィールドの優先順位
  String get _primaryKey {
    switch (_mode) {
      case NumThTab.factor: return 'n';
      case NumThTab.primeCheck: return 'n';
      case NumThTab.gcdlcm: return 'a';
      case NumThTab.euclid: return 'a';
      case NumThTab.baseConvert: return 'value';
    }
  }

  Widget _buildKeyboard() {
    final key1 = _primaryKey;
    final key2 = (_mode == NumThTab.gcdlcm || _mode == NumThTab.euclid) ? 'b' : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12,0,12,12),
      child: Column(children: [
        if (key2 != null) _kr([
          _k('→a', () => setState(() {}), b: true),
          _k('→b', () => setState(() {}), b: true),
          _k('AC', () => setState(() { _f.updateAll((_,__)=>''); _result=''; _primeList=[]; }), r: true),
          _k('⌫', () => _bs(key1), o: true),
        ]) else _kr([
          _k('AC', () => setState(() { _f.updateAll((_,__)=>''); _result=''; _primeList=[]; }), r: true),
          _k('⌫', () => _bs(key1), o: true),
          _k('', () {}, transparent: true),
          _k('', () {}, transparent: true),
        ]),
        _kr([_k('7',()=>_ap(key1,'7')), _k('8',()=>_ap(key1,'8')),
          _k('9',()=>_ap(key1,'9')), _k('',(){}, transparent: true)]),
        _kr([_k('4',()=>_ap(key1,'4')), _k('5',()=>_ap(key1,'5')),
          _k('6',()=>_ap(key1,'6')), _k('',(){}, transparent: true)]),
        _kr([_k('1',()=>_ap(key1,'1')), _k('2',()=>_ap(key1,'2')),
          _k('3',()=>_ap(key1,'3')), _k('',(){}, transparent: true)]),
        _kr([_k('0',()=>_ap(key1,'0'), flex: 2),
          _k('00',()=>_ap(key1,'00')), _k('計算', _calculate, a: true)]),
      ]),
    );
  }

  Widget _kr(List<Widget> ch) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: ch));

  Widget _k(String lbl, VoidCallback fn, {
    bool r=false,bool o=false,bool b=false,bool a=false,
    bool transparent=false, int flex=1,
  }) {
    if (transparent) {
      return Expanded(flex: flex, child: const SizedBox.shrink());
    }
    Color bg, fg;
    if (a)      { bg = _color;              fg = Colors.white; }
    else if (r) { bg = AppTheme.btnClear;   fg = const Color(0xFFFFCDD2); }
    else if (o) { bg = AppTheme.btnOperator;fg = AppTheme.accentCyan; }
    else if (b) { bg = AppTheme.btnSpecial; fg = const Color(0xFFE9D5FF); }
    else        { bg = AppTheme.btnNumber;  fg = AppTheme.textPrimary; }
    return Expanded(flex: flex, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: fn,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.4))),
          child: Center(child: _loading && a
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(lbl, style: TextStyle(
                fontFamily: 'IBM Plex Mono', fontSize: 16,
                fontWeight: FontWeight.w600, color: fg))),
        ),
      ),
    ));
  }
}

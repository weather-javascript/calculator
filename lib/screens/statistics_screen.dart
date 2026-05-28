// lib/screens/statistics_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/engine/math_engine_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _ctrl = TextEditingController();
  Map<String, String>? _stats;
  bool _loading = false;
  final _color = const Color(0xFF14B8A6);

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _calc() async {
    final data = _ctrl.text.trim();
    if (data.isEmpty) return;
    setState(() { _loading = true; _stats = null; });
    final res = await MathEngineService().statistics(data);
    if (!res.success || res.result.startsWith('Error')) {
      setState(() { _loading = false; _stats = {'error': res.result}; });
      return;
    }
    try {
      final j = jsonDecode(res.result) as Map<String, dynamic>;
      setState(() { _loading = false; _stats = j.map((k, v) => MapEntry(k, v.toString())); });
    } catch (e) {
      setState(() { _loading = false; _stats = {'error': '$e'}; });
    }
  }

  void _ap(String v) {
    final t = _ctrl.text + v;
    _ctrl.text = t;
    _ctrl.selection = TextSelection.collapsed(offset: t.length);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(children: [
      // 入力
      Padding(
        padding: const EdgeInsets.fromLTRB(12,12,12,0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('データ入力（カンマ区切り）', style: TextStyle(
            fontFamily: 'Space Grotesk', fontSize: 11,
            fontWeight: FontWeight.w600, color: _color, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _color.withOpacity(0.4), width: 1.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontFamily: 'IBM Plex Mono',
                fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '例: 10, 20, 30, 40, 50',
                hintStyle: const TextStyle(fontFamily: 'IBM Plex Mono',
                  fontSize: 13, color: AppTheme.textMuted),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero),
              maxLines: 3,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            )),
          const SizedBox(height: 8),
          Row(children: [
            _qBtn('クリア', () { _ctrl.clear(); setState(() => _stats = null); }),
            const SizedBox(width: 8),
            _qBtn('サンプル', () {
              _ctrl.text = '12, 15, 18, 22, 25, 28, 30, 33, 35, 40';
            }),
            const Spacer(),
            GestureDetector(
              onTap: _calc,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _color, borderRadius: BorderRadius.circular(10)),
                child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('計算', style: TextStyle(
                      fontFamily: 'Space Grotesk', fontSize: 15,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              )),
          ]),
        ])),
      if (_stats != null) ...[
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _results()),
      ],
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _numPad()),
      const SizedBox(height: 12),
    ]));
  }

  Widget _results() {
    if (_stats!.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3))),
        child: Text(_stats!['error']!, style: const TextStyle(
          fontFamily: 'IBM Plex Mono', color: AppTheme.accentRed)));
    }
    final items = [
      ('データ数 n', _stats!['n']!), ('合計 Σ', _stats!['sum']!),
      ('平均 x̄', _stats!['mean']!), ('中央値 Me', _stats!['median']!),
      ('最頻値 Mo', _stats!['mode']!), ('分散 σ²', _stats!['variance']!),
      ('標準偏差 σ', _stats!['stdDev']!), ('最小値', _stats!['min']!),
      ('最大値', _stats!['max']!), ('範囲', _stats!['range']!),
      ('第1四分位 Q₁', _stats!['q1']!), ('第3四分位 Q₃', _stats!['q3']!),
      ('四分位範囲 IQR', _stats!['iqr']!),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2))),
      child: Column(children: items.asMap().entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: e.key < items.length - 1
          ? const BoxDecoration(border: Border(
              bottom: BorderSide(color: AppTheme.divider)))
          : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e.value.$1, style: const TextStyle(
            fontFamily: 'Space Grotesk', fontSize: 12, color: AppTheme.textSecondary)),
          Text(e.value.$2, style: TextStyle(
            fontFamily: 'IBM Plex Mono', fontSize: 14,
            fontWeight: FontWeight.w600, color: _color)),
        ]),
      )).toList()),
    );
  }

  Widget _qBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor)),
      child: Text(label, style: const TextStyle(
        fontFamily: 'Space Grotesk', fontSize: 12, color: AppTheme.textSecondary))));

  Widget _numPad() => Column(children: [
    _r(['7','8','9']), const SizedBox(height: 6),
    _r(['4','5','6']), const SizedBox(height: 6),
    _r(['1','2','3']), const SizedBox(height: 6),
    Row(children: [
      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
        child: cb.CalcButton(label: '0', style: cb.ButtonStyle.number,
          onTap: () => _ap('0'), height: 52))),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
        child: cb.CalcButton(label: '.', style: cb.ButtonStyle.number,
          onTap: () => _ap('.'), height: 52))),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
        child: cb.CalcButton(label: ',', style: cb.ButtonStyle.operator,
          onTap: () => _ap(', '), height: 52))),
    ]),
  ]);

  Widget _r(List<String> digits) => Row(children: digits.map((d) =>
    Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
      child: cb.CalcButton(label: d, style: cb.ButtonStyle.number,
        onTap: () => _ap(d), height: 52)))).toList());
}

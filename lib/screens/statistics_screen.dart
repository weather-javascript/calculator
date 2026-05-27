// lib/screens/statistics_screen.dart
// 統計: 平均、分散、標準偏差、中央値、最頻値、四分位数など

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../services/math_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_button.dart' as cb;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, String>? _statsResult;
  final TextEditingController _dataController = TextEditingController();
  bool _isCalculating = false;

  final accentColor = const Color(0xFF14B8A6);

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final data = _dataController.text.trim();
    if (data.isEmpty) return;

    setState(() {
      _isCalculating = true;
      _statsResult = null;
    });

    final engine = MathEngineService();
    final result = await engine.statistics(data);

    if (!result.success || result.result.startsWith('Error')) {
      setState(() {
        _isCalculating = false;
        _statsResult = {'error': result.result};
      });
      return;
    }

    try {
      final decoded = jsonDecode(result.result) as Map<String, dynamic>;
      setState(() {
        _isCalculating = false;
        _statsResult = decoded.map((k, v) => MapEntry(k, v.toString()));
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _statsResult = {'error': '解析エラー: $e'};
      });
    }
  }

  void _appendToData(String value) {
    final cur = _dataController.text;
    final sel = _dataController.selection;
    final newText = cur.length > 0 ? cur + value : value;
    _dataController.text = newText;
    _dataController.selection = TextSelection.collapsed(offset: newText.length);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Data input area
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'データ入力（カンマ区切り）',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: _dataController,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '例: 2, 4, 6, 8, 10',
                      hintStyle: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 3,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
                const SizedBox(height: 8),
                // Quick actions
                Row(
                  children: [
                    _quickBtn('クリア', () {
                      _dataController.clear();
                      setState(() => _statsResult = null);
                    }),
                    const SizedBox(width: 8),
                    _quickBtn('サンプルデータ', () {
                      _dataController.text =
                          '12, 15, 18, 22, 25, 28, 30, 33, 35, 40';
                    }),
                    const Spacer(),
                    // Calculate button
                    GestureDetector(
                      onTap: _calculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isCalculating
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppTheme.background),
                                ),
                              )
                            : const Text(
                                '計算',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.background,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          if (_statsResult != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildResults(),
            ),
          ],

          // Numeric keyboard for quick input
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _numPad(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_statsResult!.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
        ),
        child: Text(
          _statsResult!['error']!,
          style: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            color: AppTheme.accentRed,
          ),
        ),
      );
    }

    final items = [
      ('データ数 n', _statsResult!['n'] ?? '-'),
      ('合計 Σ', _statsResult!['sum'] ?? '-'),
      ('平均 x̄', _statsResult!['mean'] ?? '-'),
      ('中央値 Me', _statsResult!['median'] ?? '-'),
      ('最頻値 Mo', _statsResult!['mode'] ?? '-'),
      ('分散 σ²', _statsResult!['variance'] ?? '-'),
      ('標準偏差 σ', _statsResult!['stdDev'] ?? '-'),
      ('最小値', _statsResult!['min'] ?? '-'),
      ('最大値', _statsResult!['max'] ?? '-'),
      ('範囲', _statsResult!['range'] ?? '-'),
      ('第1四分位 Q1', _statsResult!['q1'] ?? '-'),
      ('第3四分位 Q3', _statsResult!['q3'] ?? '-'),
      ('四分位範囲 IQR', _statsResult!['iqr'] ?? '-'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppTheme.divider,
                        width: 1,
                      ),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.value.$1,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  e.value.$2,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _numPad() {
    return Column(
      children: [
        _row(['7', '8', '9']),
        const SizedBox(height: 6),
        _row(['4', '5', '6']),
        const SizedBox(height: 6),
        _row(['1', '2', '3']),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: cb.CalcButton(
                  label: '0',
                  style: cb.ButtonStyle.number,
                  onTap: () => _appendToData('0'),
                  height: 52,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: cb.CalcButton(
                  label: '.',
                  style: cb.ButtonStyle.number,
                  onTap: () => _appendToData('.'),
                  height: 52,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: cb.CalcButton(
                  label: ',',
                  style: cb.ButtonStyle.operator,
                  onTap: () => _appendToData(', '),
                  height: 52,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: digits
          .map((d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: cb.CalcButton(
                    label: d,
                    style: cb.ButtonStyle.number,
                    onTap: () => _appendToData(d),
                    height: 52,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_state.dart';
import '../core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(builder: (_, state, __) {
      final history = state.history;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16,12,16,8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('計算履歴', style: TextStyle(
                fontFamily: 'Space Grotesk', fontSize: 16,
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              if (history.isNotEmpty)
                GestureDetector(
                  onTap: state.clearHistory,
                  child: const Text('クリア', style: TextStyle(
                    fontFamily: 'Space Grotesk', fontSize: 13,
                    color: AppTheme.accentRed))),
            ])),
        if (history.isEmpty)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('∅', style: TextStyle(
                fontSize: 48, color: AppTheme.textMuted.withOpacity(0.5))),
              const SizedBox(height: 12),
              const Text('履歴なし', style: TextStyle(
                fontFamily: 'Space Grotesk', fontSize: 14,
                color: AppTheme.textMuted)),
            ])))
        else
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final entry = history[i];
              return GestureDetector(
                onTap: () {
                  state.useHistoryResult(entry);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor.withOpacity(0.6))),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.expression, style: const TextStyle(
                          fontFamily: 'IBM Plex Mono', fontSize: 12,
                          color: AppTheme.textSecondary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('= ${entry.result}', style: const TextStyle(
                          fontFamily: 'IBM Plex Mono', fontSize: 16,
                          fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      ])),
                    const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.textMuted),
                  ]),
                ),
              );
            },
          )),
      ]);
    });
  }
}

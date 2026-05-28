// lib/main.dart  (v2 — 全14モード対応)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Core
import 'core/engine/math_engine_service.dart';
import 'core/router/app_modes.dart';
import 'core/theme/app_theme.dart';

// Phase 1 screens (再利用)
import 'screens/basic_screen.dart';
import 'screens/calculus_screen.dart';
import 'screens/combinatorics_screen.dart';
import 'screens/sequences_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/history_screen.dart';
import 'models/calculator_state.dart';

// Phase 2 screens (新規)
import 'features/algebra/screens/algebra_screen.dart';
import 'features/trigonometry/screens/trigonometry_screen.dart';
import 'features/complex/screens/complex_screen.dart';
import 'features/limits/screens/limits_screen.dart';
import 'features/linear_algebra/screens/linear_algebra_screen.dart';
import 'features/number_theory/screens/number_theory_screen.dart';
import 'features/graph/screens/graph_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => CalculatorState()),
    ChangeNotifierProvider(create: (_) => MathEngineService()),
  ], child: const AdvancedCalculatorApp()));
}

class AdvancedCalculatorApp extends StatelessWidget {
  const AdvancedCalculatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '高度な電卓',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: const CalculatorHome(),
  );
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});
  @override State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  CalcMode _mode = CalcMode.basic;
  bool _engineReady = false;

  bool get _isBasic => const [
    CalcMode.basic, CalcMode.applied, CalcMode.functions,
    CalcMode.combinatorics, CalcMode.calculus,
    CalcMode.sequences, CalcMode.statistics,
  ].contains(_mode);

  @override
  Widget build(BuildContext context) {
    final info = AppModes.get(_mode);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(child: Column(children: [
        // Hidden CAS WebView
        SizedBox(width: 1, height: 1,
          child: InAppWebView(
            initialFile: 'assets/mathjs_engine.html',
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
            ),
            onWebViewCreated: (ctrl) {
              MathEngineService().setController(ctrl);
              ctrl.addJavaScriptHandler(
                handlerName: 'onEngineReady',
                callback: (_) {
                  MathEngineService().onEngineReady();
                  setState(() => _engineReady = true);
                },
              );
            },
          ),
        ),
        _appBar(info),
        if (_isBasic)
          Consumer<CalculatorState>(builder: (_, s, __) => _Display(s, info)),
        _modeStrip(),
        Expanded(child: _screen()),
      ])),
    );
  }

  Widget _appBar(ModeInfo info) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(
          color: info.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: info.color.withOpacity(0.4))),
        child: Icon(Icons.calculate, color: info.color, size: 18)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('高度な電卓', style: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 16,
          fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9))),
        Text(info.curriculumTag, style: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 10,
          color: info.color, fontWeight: FontWeight.w600)),
      ]),
      const Spacer(),
      _engineBadge(),
      if (_isBasic) ...[
        const SizedBox(width: 8),
        GestureDetector(onTap: _showHistory,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E3A5F))),
            child: const Icon(Icons.history, color: Color(0xFF94A3B8), size: 17))),
      ],
    ]),
  );

  Widget _engineBadge() {
    final c = _engineReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(width: 5),
        Text(_engineReady ? 'CAS Ready' : '初期化中',
          style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 9, color: c)),
      ]),
    );
  }

  Widget _modeStrip() => SizedBox(
    height: 88,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: AppModes.groups.map((g) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 3),
            child: Text(g.label, style: const TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 9,
              color: Color(0xFF475569), letterSpacing: 0.5))),
          Row(children: g.modes.map((m) {
            final inf = AppModes.get(m);
            final active = _mode == m;
            return GestureDetector(
              onTap: () => setState(() => _mode = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? inf.color.withOpacity(0.18) : const Color(0xFF1A2235),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? inf.color.withOpacity(0.6) : const Color(0xFF1E3A5F),
                    width: active ? 1.5 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(inf.icon, size: 12,
                    color: active ? inf.color : const Color(0xFF475569)),
                  const SizedBox(width: 5),
                  Text(inf.shortLabel, style: TextStyle(
                    fontFamily: 'IBM Plex Mono', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? inf.color : const Color(0xFF475569))),
                ]),
              ),
            );
          }).toList()),
        ]),
      )).toList(),
    ),
  );

  Widget _screen() {
    switch (_mode) {
      case CalcMode.basic:
      case CalcMode.applied:
      case CalcMode.functions:    return const BasicScreen();
      case CalcMode.calculus:     return const CalculusScreen();
      case CalcMode.combinatorics:return const CombinatoricsScreen();
      case CalcMode.sequences:    return const SequencesScreen();
      case CalcMode.statistics:   return const StatisticsScreen();
      case CalcMode.algebra:      return const AlgebraScreen();
      case CalcMode.trigonometry: return const TrigonometryScreen();
      case CalcMode.complex:      return const ComplexScreen();
      case CalcMode.limits:       return const LimitsScreen();
      case CalcMode.linearAlgebra:return const LinearAlgebraScreen();
      case CalcMode.numberTheory: return const NumberTheoryScreen();
      case CalcMode.graph:        return const GraphScreen();
    }
  }

  void _showHistory() => showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<CalculatorState>(),
      child: const HistoryScreen()),
  );
}

class _Display extends StatelessWidget {
  final CalculatorState s;
  final ModeInfo info;
  const _Display(this.s, this.info);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18,10,18,14),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      border: Border(bottom: BorderSide(
        color: info.color.withOpacity(0.3), width: 1.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: info.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: info.color.withOpacity(0.3))),
          child: Text(info.label, style: TextStyle(
            fontFamily: 'Space Grotesk', fontSize: 10,
            fontWeight: FontWeight.w600, color: info.color))),
        if (s.isCalculating) SizedBox(width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(info.color))),
      ]),
      const SizedBox(height: 6),
      Text(s.displayExpression.isEmpty ? ' ' : s.displayExpression,
        style: const TextStyle(fontFamily: 'IBM Plex Mono',
          fontSize: 15, color: Color(0xFF94A3B8)),
        textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          key: ValueKey(s.displayResult),
          s.displayResult.isEmpty ? '0' : s.displayResult,
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: s.displayResult.length > 14 ? 24 : s.displayResult.length > 10 ? 32 : 42,
            fontWeight: FontWeight.w300,
            color: s.hasError ? const Color(0xFFEF4444) : const Color(0xFFF1F5F9)),
          textAlign: TextAlign.right),
      ),
    ]),
  );
}

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'models/calculator_state.dart';
import 'services/math_engine_service.dart';
import 'theme/app_theme.dart';
import 'widgets/calc_display.dart';
import 'screens/basic_screen.dart';
import 'screens/calculus_screen.dart';
import 'screens/combinatorics_screen.dart';
import 'screens/sequences_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => CalculatorState(),
      child: const AdvancedCalculatorApp(),
    ),
  );
}

class AdvancedCalculatorApp extends StatelessWidget {
  const AdvancedCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '高度な電卓',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CalculatorHome(),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Home Screen
// ──────────────────────────────────────────────────────

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  // Hidden WebView for math.js engine
  InAppWebViewController? _webController;
  bool _engineReady = false;

  // Mode navigation data
  static const List<_ModeInfo> _modes = [
    _ModeInfo(
      mode: CalculatorMode.basic,
      label: '四則演算',
      icon: Icons.calculate_outlined,
      colorKey: 'basic',
    ),
    _ModeInfo(
      mode: CalculatorMode.applied,
      label: '応用計算',
      icon: Icons.functions,
      colorKey: 'applied',
    ),
    _ModeInfo(
      mode: CalculatorMode.combinatorics,
      label: '場合の数',
      icon: Icons.grid_view,
      colorKey: 'combinatorics',
    ),
    _ModeInfo(
      mode: CalculatorMode.calculus,
      label: '解析学',
      icon: Icons.show_chart,
      colorKey: 'calculus',
    ),
    _ModeInfo(
      mode: CalculatorMode.functions,
      label: '関数',
      icon: Icons.timeline,
      colorKey: 'functions',
    ),
    _ModeInfo(
      mode: CalculatorMode.sequences,
      label: '数列',
      icon: Icons.format_list_numbered,
      colorKey: 'sequences',
    ),
    _ModeInfo(
      mode: CalculatorMode.statistics,
      label: '統計',
      icon: Icons.bar_chart,
      colorKey: 'statistics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorState>(
      builder: (context, state, _) {
        final currentMode = state.mode;
        final modeInfo = _modes.firstWhere((m) => m.mode == currentMode);
        final modeColor = AppTheme.modeColors[modeInfo.colorKey]!;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Hidden WebView (math.js engine) ──
                SizedBox(
                  width: 1,
                  height: 1,
                  child: InAppWebView(
                    initialFile: 'assets/mathjs_engine.html',
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                    ),
                    onWebViewCreated: (controller) {
                      _webController = controller;
                      MathEngineService().setController(controller);
                      controller.addJavaScriptHandler(
                        handlerName: 'onEngineReady',
                        callback: (_) {
                          setState(() => _engineReady = true);
                          MathEngineService().onEngineReady();
                        },
                      );
                    },
                  ),
                ),

                // ── App bar ──
                _buildAppBar(context, state, modeColor),

                // ── Display ──
                CalcDisplay(
                  expression: state.displayExpression,
                  result: state.displayResult,
                  hasError: state.hasError,
                  isCalculating: state.isCalculating,
                  modeName: modeInfo.label,
                  modeColor: modeColor,
                ),

                // ── Mode selector strip ──
                _buildModeStrip(state),

                // ── Calculator body ──
                Expanded(
                  child: _buildScreen(state.mode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, CalculatorState state, Color modeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Logo / title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: modeColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.calculate, color: modeColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '高度な電卓',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Engine status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _engineReady
                  ? AppTheme.accentGreen.withOpacity(0.1)
                  : AppTheme.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _engineReady
                        ? AppTheme.accentGreen
                        : AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _engineReady ? 'CAS 準備完了' : '初期化中...',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 10,
                    color: _engineReady
                        ? AppTheme.accentGreen
                        : AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // History button
          GestureDetector(
            onTap: () => _showHistory(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.history,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeStrip(CalculatorState state) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final m = _modes[index];
          final isActive = state.mode == m.mode;
          final color = AppTheme.modeColors[m.colorKey]!;

          return GestureDetector(
            onTap: () => state.setMode(m.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.15) : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color.withOpacity(0.6) : AppTheme.borderColor,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m.icon,
                    size: 14,
                    color: isActive ? color : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    m.label,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? color : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreen(CalculatorMode mode) {
    switch (mode) {
      case CalculatorMode.basic:
      case CalculatorMode.applied:
      case CalculatorMode.functions:
        return const BasicScreen();
      case CalculatorMode.calculus:
        return const CalculusScreen();
      case CalculatorMode.combinatorics:
        return const CombinatoricsScreen();
      case CalculatorMode.sequences:
        return const SequencesScreen();
      case CalculatorMode.statistics:
        return const StatisticsScreen();
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CalculatorState>(),
        child: const HistoryScreen(),
      ),
    );
  }
}

class _ModeInfo {
  final CalculatorMode mode;
  final String label;
  final IconData icon;
  final String colorKey;

  const _ModeInfo({
    required this.mode,
    required this.label,
    required this.icon,
    required this.colorKey,
  });
}

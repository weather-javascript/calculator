// lib/features/graph/screens/graph_screen.dart
// グラフ描画: y=f(x) の2Dビジュアライゼーション（Canvasレンダリング）

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});
  @override State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final List<_PlotEntry> _plots = [
    _PlotEntry(expr: 'sin(x)', color: const Color(0xFF00E5FF)),
  ];
  double _xMin = -10, _xMax = 10;
  List<List<_Point?>> _plotData = [];
  bool _loading = false;
  String _error = '';

  final _color = AppModes.colorOf(CalcMode.graph);
  final _xMinCtrl = TextEditingController(text: '-10');
  final _xMaxCtrl = TextEditingController(text: '10');

  static const _palette = [
    Color(0xFF00E5FF), Color(0xFFEC4899), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _plot());
  }

  @override
  void dispose() {
    _xMinCtrl.dispose(); _xMaxCtrl.dispose(); super.dispose();
  }

  Future<void> _plot() async {
    final engine = MathEngineService();
    if (!engine.isReady) {
      setState(() => _error = 'エンジン初期化中...');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final exprs = _plots.map((p) => MathEngineService.preprocess(p.expr)).toList();
    final res = await engine.plotMultiple(exprs, _xMin, _xMax, points: 300);

    if (!res.success) {
      setState(() { _loading = false; _error = res.result; });
      return;
    }

    try {
      final raw = jsonDecode(res.result) as List;
      setState(() {
        _loading = false;
        _plotData = raw.map((series) {
          final pts = (series['points'] as List);
          return pts.map<_Point?>((p) {
            if (p == null) { return null; }
            return _Point(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            );
          }).toList();
        }).toList();
      });
    } catch (e) {
      setState(() { _loading = false; _error = '描画エラー: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 関数入力エリア
      _buildFunctionList(),
      // x範囲
      _buildRangeRow(),
      // グラフキャンバス
      Expanded(child: _buildCanvas()),
    ]);
  }

  Widget _buildFunctionList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12,8,12,0),
      child: Column(children: [
        ..._plots.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            // 色インジケーター
            Container(width: 4, height: 42,
              decoration: BoxDecoration(
                color: e.value.color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            // 式入力
            Expanded(child: TextField(
              controller: TextEditingController(text: e.value.expr)
                ..selection = TextSelection.collapsed(offset: e.value.expr.length),
              decoration: InputDecoration(
                filled: true, fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: e.value.color.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: e.value.color.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: e.value.color, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: 'y = f(x)',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixText: 'y = ',
                prefixStyle: TextStyle(
                  fontFamily: 'IBM Plex Mono', fontSize: 14, color: e.value.color),
              ),
              style: const TextStyle(fontFamily: 'IBM Plex Mono',
                fontSize: 14, color: AppTheme.textPrimary),
              onChanged: (v) => _plots[e.key].expr = v,
              onSubmitted: (_) => _plot(),
            )),
            // 削除ボタン
            if (_plots.length > 1) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() { _plots.removeAt(e.key); _plotData = []; }),
                child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18)),
            ],
          ]),
        )),
        // ボタン行
        Row(children: [
          GestureDetector(
            onTap: () {
              if (_plots.length < 6) {
                setState(() => _plots.add(_PlotEntry(
                  expr: '',
                  color: _palette[_plots.length % _palette.length],
                )));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _color.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 14, color: _color),
                const SizedBox(width: 4),
                Text('関数を追加', style: TextStyle(
                  fontFamily: 'Space Grotesk', fontSize: 12, color: _color)),
              ]),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _plot,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _color, borderRadius: BorderRadius.circular(8)),
              child: _loading
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('描画', style: TextStyle(
                    fontFamily: 'Space Grotesk', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRangeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12,6,12,0),
      child: Row(children: [
        const Text('x:', style: TextStyle(
          fontFamily: 'IBM Plex Mono', fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 6),
        SizedBox(width: 56, child: TextField(
          controller: _xMinCtrl,
          decoration: _rangeDecor(),
          style: const TextStyle(fontFamily: 'IBM Plex Mono',
            fontSize: 12, color: AppTheme.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) => _xMin = double.tryParse(v) ?? _xMin,
        )),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('〜', style: TextStyle(color: AppTheme.textSecondary))),
        SizedBox(width: 56, child: TextField(
          controller: _xMaxCtrl,
          decoration: _rangeDecor(),
          style: const TextStyle(fontFamily: 'IBM Plex Mono',
            fontSize: 12, color: AppTheme.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) => _xMax = double.tryParse(v) ?? _xMax,
        )),
        const Spacer(),
        // リセットボタン
        GestureDetector(
          onTap: () { setState(() { _xMin=-10; _xMax=10; _scale=1; _panOffset=Offset.zero; _xMinCtrl.text='-10'; _xMaxCtrl.text='10'; }); _plot(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor)),
            child: const Text('リセット', style: TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ),
      ]),
    );
  }

  InputDecoration _rangeDecor() => InputDecoration(
    filled: true, fillColor: AppTheme.surfaceCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppTheme.borderColor)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  );

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(

          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF080D18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _color.withOpacity(0.2)),
            ),
            child: _loading
              ? Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_color)))
              : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(
                    fontFamily: 'IBM Plex Mono', color: AppTheme.accentRed)))
                : _plotData.isEmpty
                  ? Center(child: Text('関数を入力して「描画」を押してください',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk', color: AppTheme.textMuted)))
                  : CustomPaint(
                      painter: _GraphPainter(
                        plots: _plotData,
                        colors: _plots.map((p) => p.color).toList(),
                        xMin: _xMin, xMax: _xMax,
                      ),
                      child: const SizedBox.expand(),
                    ),
          ),
        ),
      ),
    );
  }
}

// ── データクラス ─────────────────────────────────────────────
class _PlotEntry {
  String expr;
  Color color;
  _PlotEntry({required this.expr, required this.color});
}

class _Point {
  final double x, y;
  const _Point(this.x, this.y);
}

// ── グラフ描画エンジン ────────────────────────────────────────
class _GraphPainter extends CustomPainter {
  final List<List<_Point?>> plots;
  final List<Color> colors;
  final double xMin, xMax;

  const _GraphPainter({
    required this.plots, required this.colors,
    required this.xMin, required this.xMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plots.isEmpty) { return; }

    // データからyの範囲を計算
    double yMin = double.infinity, yMax = double.negativeInfinity;
    for (final series in plots) {
      for (final p in series) {
        if (p != null && p.y.isFinite) {
          if (p.y < yMin) yMin = p.y;
          if (p.y > yMax) yMax = p.y;
        }
      }
    }
    if (yMin == double.infinity) { yMin = -10; yMax = 10; }
    final yPad = (yMax - yMin) * 0.1 + 1;
    yMin -= yPad; yMax += yPad;

    // 座標変換
    toScreen(double x, double y) => Offset(
      (x - xMin) / (xMax - xMin) * size.width,
      (1 - (y - yMin) / (yMax - yMin)) * size.height,
    );

    // グリッド描画
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.6)
      ..strokeWidth = 0.5;
    const axisLabelStyle = TextStyle(
      fontFamily: 'IBM Plex Mono', fontSize: 9, color: Color(0xFF475569));

    // x軸グリッド
    final xStep = _niceStep((xMax - xMin) / 8);
    for (double x = (xMin / xStep).ceil() * xStep; x <= xMax; x += xStep) {
      final sx = toScreen(x, 0).dx;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), gridPaint);
      _drawText(canvas, x == 0 ? '' : _fmt(x),
        Offset(sx + 2, size.height - 14), axisLabelStyle);
    }

    // y軸グリッド
    final yStep = _niceStep((yMax - yMin) / 6);
    for (double y = (yMin / yStep).ceil() * yStep; y <= yMax; y += yStep) {
      final sy = toScreen(0, y).dy;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), gridPaint);
      _drawText(canvas, y == 0 ? '' : _fmt(y), Offset(4, sy - 12), axisLabelStyle);
    }

    // 軸（太め）
    final axisPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5;
    // x=0
    if (xMin <= 0 && 0 <= xMax) {
      final sx = toScreen(0, 0).dx;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), axisPaint);
    }
    // y=0
    if (yMin <= 0 && 0 <= yMax) {
      final sy = toScreen(0, 0).dy;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), axisPaint);
    }

    // 関数グラフ描画
    for (int s = 0; s < plots.length; s++) {
      final series = plots[s];
      final paint = Paint()
        ..color = s < colors.length ? colors[s] : Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool started = false;

      for (int i = 0; i < series.length; i++) {
        final p = series[i];
        if (p == null || !p.y.isFinite || p.y < yMin * 3 || p.y > yMax * 3) {
          started = false;
          continue;
        }
        final sp = toScreen(p.x, p.y);
        if (!started) { path.moveTo(sp.dx, sp.dy); started = true; }
        else path.lineTo(sp.dx, sp.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  double _niceStep(double rough) {
    final magnitude = (rough == 0) ? 1.0 : pow10(rough.abs().log10().floorVal());
    final r = rough / magnitude;
    final nice = r < 1.5 ? 1.0 : r < 3 ? 2.0 : r < 7 ? 5.0 : 10.0;
    return nice * magnitude;
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) { return v.toInt().toString(); }
    return v.toStringAsFixed(1);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.plots != plots || old.xMin != xMin || old.xMax != xMax;
}

extension _DoubleGraphExt on double {
  double log10() => (this > 0) ? (this / 2.302585092994046) : 0.0;
  int floorVal() => this < 0 ? -((-this).ceil()) : truncate();
}

double pow10(int n) {
  if (n >= 0) {
    double r = 1.0;
    for (int i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  } else {
    double r = 1.0;
    for (int i = 0; i < -n; i++) {
      r /= 10;
    }
    return r;
  }
}

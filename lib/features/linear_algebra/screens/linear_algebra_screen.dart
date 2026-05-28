// lib/features/linear_algebra/screens/linear_algebra_screen.dart
// ベクトル・行列: 内積・外積・行列演算・行列式・固有値・連立方程式

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/engine/math_engine_service.dart';
import '../../../core/router/app_modes.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/matrix_input_widget.dart';
import '../widgets/vector_input_widget.dart';

enum LinAlgTab { vector, matrix, solve }

class LinearAlgebraScreen extends StatefulWidget {
  const LinearAlgebraScreen({super.key});
  @override State<LinearAlgebraScreen> createState() => _LinearAlgebraScreenState();
}

class _LinearAlgebraScreenState extends State<LinearAlgebraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  LinAlgTab _mode = LinAlgTab.vector;

  // ベクトル入力
  final List<String> _vec1 = ['', '', ''];
  final List<String> _vec2 = ['', '', ''];
  String _vecOp = 'dot'; // dot/cross/add/sub/norm/angle/scale
  String _scalar = '1';

  // 行列入力（最大4x4）
  int _matRows = 2;
  List<List<String>> _matA = [['',''],['','']];
  List<List<String>> _matB = [['',''],['','']];
  String _matOp = 'mul'; // add/sub/mul/inv/det/transpose/eigen

  // 連立方程式 Ax=b
  int _solveN = 2;
  List<List<String>> _solveA = [['',''],['','']];
  List<String> _solveB = ['',''];

  String _result = '';
  bool _isError = false;
  bool _loading = false;

  final _color = AppModes.colorOf(CalcMode.linearAlgebra);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {
      _mode = LinAlgTab.values[_tab.index];
      _result = '';
    }));
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  // ── 計算実行 ──────────────────────────────────────────
  Future<void> _calculate() async {
    final engine = MathEngineService();
    setState(() { _loading = true; _result = ''; });
    MathResult res;

    if (_mode == LinAlgTab.vector) {
      final a = _vec1.map((s) => double.tryParse(s) ?? 0).toList();
      final b = _vec2.map((s) => double.tryParse(s) ?? 0).toList();
      switch (_vecOp) {
        case 'dot':   res = await engine.dot(a, b); break;
        case 'cross': res = await engine.cross(a, b); break;
        case 'add':   res = await engine.vecAdd(a, b); break;
        case 'sub':   res = await engine.vecSub(a, b); break;
        case 'norm':  res = await engine.vecNorm(a); break;
        case 'angle':
          res = await engine.vecAngle(a, b);
          if (res.success) {
            try {
              final j = jsonDecode(res.result) as Map<String, dynamic>;
              res = MathResult(success: true,
                result: 'cos θ = ${j['cos']}\nθ = ${j['rad']} rad = ${j['deg']}°');
            } catch (_) {}
          }
          break;
        case 'scale':
          res = await engine.vecScale(a, double.tryParse(_scalar) ?? 1);
          break;
        default: res = MathResult.error('Unknown op');
      }
      // ベクトル結果をきれいに表示
      if (res.success && res.result.startsWith('[')) {
        try {
          final list = jsonDecode(res.result) as List;
          res = MathResult(success: true, result: '(${list.join(', ')})');
        } catch (_) {}
      }
    } else if (_mode == LinAlgTab.matrix) {
      final A = _matA.map((r) => r.map((s) => double.tryParse(s) ?? 0).toList()).toList();
      final B = _matB.map((r) => r.map((s) => double.tryParse(s) ?? 0).toList()).toList();
      switch (_matOp) {
        case 'add':       res = await engine.matAdd(A, B); break;
        case 'sub':       res = await engine.matSub(A, B); break;
        case 'mul':       res = await engine.matMul(A, B); break;
        case 'inv':       res = await engine.matInv(A); break;
        case 'det':       res = await engine.det(A); break;
        case 'transpose': res = await engine.transpose(A); break;
        case 'eigen':     res = await engine.eigenvalues(A); break;
        default: res = MathResult.error('Unknown op');
      }
      // 行列結果を整形
      if (res.success && res.result.startsWith('[[')) {
        try {
          final matrix = jsonDecode(res.result) as List;
          final rows = matrix.map((r) {
            final row = (r as List).map((v) => v.toString()).join('\t');
            return '│ $row │';
          }).join('\n');
          res = MathResult(success: true, result: rows);
        } catch (_) {}
      } else if (res.success && res.result.startsWith('[') && !res.result.startsWith('[[')) {
        try {
          final list = jsonDecode(res.result) as List;
          res = MathResult(success: true, result: '固有値: ${list.join(', ')}');
        } catch (_) {}
      }
    } else {
      // 連立方程式
      final A = _solveA.map((r) => r.map((s) => double.tryParse(s) ?? 0).toList()).toList();
      final b = _solveB.map((s) => double.tryParse(s) ?? 0).toList();
      res = await engine.solveLinearSystem(A, b);
      if (res.success) {
        try {
          final list = jsonDecode(res.result) as List;
          final vars = ['x','y','z','w'];
          final lines = list.asMap().entries
              .map((e) => '${vars[e.key]} = ${e.value}').join('\n');
          res = MathResult(success: true, result: lines);
        } catch (_) {}
      }
    }

    setState(() { _loading = false; _result = res.result; _isError = !res.success; });
  }

  // ── UI ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabs(),
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12,8,12,0),
          child: _buildPanel()),
        if (_result.isNotEmpty) _buildResult(),
        const SizedBox(height: 12),
        // 計算ボタン
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _calcButton(),
        ),
        const SizedBox(height: 16),
      ]))),
    ]);
  }

  Widget _buildTabs() {
    const labels = ['ベクトル', '行列', '連立方程式'];
    return Container(
      height: 38, margin: const EdgeInsets.fromLTRB(12,6,12,0),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(10)),
      child: Row(children: List.generate(3, (i) {
        final active = _tab.index == i;
        return Expanded(child: GestureDetector(
          onTap: () => _tab.animateTo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: active ? _color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: active ? Border.all(color: _color.withOpacity(0.5)) : null,
            ),
            child: Center(child: Text(labels[i], style: TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? _color : AppTheme.textMuted))),
          ),
        ));
      })),
    );
  }

  Widget _buildPanel() {
    switch (_mode) {
      case LinAlgTab.vector:  return _vectorPanel();
      case LinAlgTab.matrix:  return _matrixPanel();
      case LinAlgTab.solve:   return _solvePanel();
    }
  }

  // ── ベクトルパネル ───────────────────────────────────
  Widget _vectorPanel() {
    final needs2 = !['norm'].contains(_vecOp);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 演算選択
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final op in ['dot','cross','add','sub','norm','angle','scale'])
          _opChip(op, _vecOpLabel(op), _vecOp,
            (v) => setState(() { _vecOp = v; _result = ''; })),
      ]),
      const SizedBox(height: 10),
      VectorInputWidget(
        label: 'ベクトル a',
        values: _vec1,
        color: _color,
        onChanged: (i, v) => setState(() => _vec1[i] = v),
      ),
      if (needs2) ...[
        const SizedBox(height: 8),
        if (_vecOp == 'scale')
          _scalarInput()
        else
          VectorInputWidget(
            label: 'ベクトル b',
            values: _vec2,
            color: _color,
            onChanged: (i, v) => setState(() => _vec2[i] = v),
          ),
      ],
    ]);
  }

  Widget _scalarInput() {
    return Row(children: [
      const Text('スカラー k: ', style: TextStyle(
        fontFamily: 'Space Grotesk', fontSize: 13, color: AppTheme.textSecondary)),
      SizedBox(
        width: 80,
        child: TextField(
          decoration: InputDecoration(
            filled: true, fillColor: AppTheme.surfaceCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _color.withOpacity(0.4))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: const TextStyle(fontFamily: 'IBM Plex Mono',
            fontSize: 14, color: AppTheme.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) => _scalar = v,
        ),
      ),
    ]);
  }

  // ── 行列パネル ──────────────────────────────────────
  Widget _matrixPanel() {
    final needsB = ['add','sub','mul'].contains(_matOp);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 演算選択
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final op in ['add','sub','mul','inv','det','transpose','eigen'])
          _opChip(op, _matOpLabel(op), _matOp,
            (v) => setState(() { _matOp = v; _result = ''; })),
      ]),
      const SizedBox(height: 8),
      // サイズ選択
      _matSizeSelector(),
      const SizedBox(height: 8),
      MatrixInputWidget(
        label: '行列 A',
        matrix: _matA,
        color: _color,
        onChanged: (r, c, v) => setState(() => _matA[r][c] = v),
      ),
      if (needsB) ...[
        const SizedBox(height: 8),
        MatrixInputWidget(
          label: '行列 B',
          matrix: _matB,
          color: _color,
          onChanged: (r, c, v) => setState(() => _matB[r][c] = v),
        ),
      ],
    ]);
  }

  Widget _matSizeSelector() {
    return Row(children: [
      const Text('サイズ: ', style: TextStyle(
        fontFamily: 'Space Grotesk', fontSize: 12, color: AppTheme.textSecondary)),
      for (final n in [2, 3, 4]) ...[
        GestureDetector(
          onTap: () => setState(() {
            _matRows = n;
            _matA = List.generate(n, (_) => List.filled(n, ''));
            _matB = List.generate(n, (_) => List.filled(n, ''));
            _result = '';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _matRows == n ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _matRows == n ? _color.withOpacity(0.5) : AppTheme.borderColor,
                width: _matRows == n ? 1.5 : 1),
            ),
            child: Text('${n}×$n', style: TextStyle(
              fontFamily: 'IBM Plex Mono', fontSize: 12,
              color: _matRows == n ? _color : AppTheme.textMuted,
              fontWeight: _matRows == n ? FontWeight.w600 : FontWeight.normal)),
          ),
        ),
      ],
    ]);
  }

  // ── 連立方程式パネル ────────────────────────────────
  Widget _solvePanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('変数の数: ', style: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 12, color: AppTheme.textSecondary)),
        for (final n in [2, 3, 4]) GestureDetector(
          onTap: () => setState(() {
            _solveN = n;
            _solveA = List.generate(n, (_) => List.filled(n, ''));
            _solveB = List.filled(n, '');
            _result = '';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _solveN == n ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _solveN == n ? _color.withOpacity(0.5) : AppTheme.borderColor,
                width: _solveN == n ? 1.5 : 1),
            ),
            child: Text('$n元', style: TextStyle(
              fontFamily: 'IBM Plex Mono', fontSize: 12,
              color: _solveN == n ? _color : AppTheme.textMuted)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      // 係数行列 A と 定数ベクトル b を横に並べて入力
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: MatrixInputWidget(
          label: '係数行列 A',
          matrix: _solveA,
          color: _color,
          onChanged: (r, c, v) => setState(() => _solveA[r][c] = v),
        )),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('定数 b', style: TextStyle(
            fontFamily: 'Space Grotesk', fontSize: 11,
            color: _color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (int r = 0; r < _solveN; r++)
            Container(
              width: 60,
              margin: const EdgeInsets.only(bottom: 4),
              child: TextField(
                decoration: InputDecoration(
                  filled: true, fillColor: AppTheme.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: _color.withOpacity(0.3))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                style: const TextStyle(fontFamily: 'IBM Plex Mono',
                  fontSize: 14, color: AppTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                onChanged: (v) => _solveB[r] = v,
              ),
            ),
        ]),
      ]),
    ]);
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
          fontFamily: 'IBM Plex Mono', fontSize: 15,
          color: _isError ? AppTheme.accentRed : AppTheme.textPrimary,
          height: 1.6)),
      ),
    );
  }

  Widget _calcButton() {
    return GestureDetector(
      onTap: _calculate,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: _color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Center(child: _loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white))
          : const Text('計　算', style: TextStyle(
              fontFamily: 'Space Grotesk', fontSize: 18,
              fontWeight: FontWeight.w700, color: Colors.white,
              letterSpacing: 4))),
      ),
    );
  }

  Widget _opChip(String op, String label, String current, void Function(String) onTap) {
    final active = current == op;
    return GestureDetector(
      onTap: () => onTap(op),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _color.withOpacity(0.5) : AppTheme.borderColor,
            width: active ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(
          fontFamily: 'IBM Plex Mono', fontSize: 12,
          color: active ? _color : AppTheme.textMuted,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  String _vecOpLabel(String op) {
    const m = {'dot':'a·b 内積','cross':'a×b 外積','add':'a+b',
      'sub':'a−b','norm':'|a| 大きさ','angle':'θ 角度','scale':'ka'};
    return m[op] ?? op;
  }

  String _matOpLabel(String op) {
    const m = {'add':'A+B','sub':'A−B','mul':'AB 積','inv':'A⁻¹',
      'det':'det(A)','transpose':'Aᵀ','eigen':'固有値'};
    return m[op] ?? op;
  }
}

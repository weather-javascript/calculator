// lib/core/engine/math_engine_service.dart
// Flutter ↔ math.js WebView ブリッジ（全モジュール対応版）

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MathResult {
  final bool success;
  final String result;
  const MathResult({required this.success, required this.result});
  factory MathResult.fromJson(Map<String, dynamic> j) =>
      MathResult(success: j['success'] as bool, result: j['result'].toString());
  factory MathResult.error(String msg) => MathResult(success: false, result: msg);
  Map<String, dynamic>? get json {
    try { return jsonDecode(result) as Map<String, dynamic>; } catch (_) { return null; }
  }
  List<dynamic>? get jsonList {
    try { return jsonDecode(result) as List<dynamic>; } catch (_) { return null; }
  }
}

class MathEngineService extends ChangeNotifier {
  static final MathEngineService _i = MathEngineService._();
  factory MathEngineService() => _i;
  MathEngineService._();

  InAppWebViewController? _ctrl;
  bool _ready = false;
  bool get isReady => _ready;

  void setController(InAppWebViewController c) { _ctrl = c; }

  void onEngineReady() {
    _ready = true;
    notifyListeners();
  }

  Future<MathResult> _call(Map<String, dynamic> req) async {
    if (_ctrl == null || !_ready) return MathResult.error('エンジン初期化中...');
    try {
      final js = 'calculate(${jsonEncode(jsonEncode(req))})';
      final raw = await _ctrl!.evaluateJavascript(source: js);
      if (raw == null) return MathResult.error('結果なし');
      return MathResult.fromJson(jsonDecode(raw.toString()) as Map<String, dynamic>);
    } catch (e) {
      return MathResult.error('実行エラー: $e');
    }
  }

  // ─── 基本 ───────────────────────────────────────────────
  Future<MathResult> evaluate(String expr) =>
      _call({'type': 'evaluate', 'expr': expr});

  Future<MathResult> differentiate(String expr, {String v = 'x'}) =>
      _call({'type': 'differentiate', 'expr': expr, 'variable': v});

  Future<MathResult> integrateNumerical(String expr, double lo, double hi,
          {String v = 'x', int steps = 10000}) =>
      _call({'type': 'integrate', 'expr': expr, 'variable': v,
             'lower': lo, 'upper': hi, 'steps': steps});

  Future<MathResult> factorial(int n) => _call({'type': 'factorial', 'n': n});
  Future<MathResult> permutation(int n, int r) =>
      _call({'type': 'permutation', 'n': n, 'r': r});
  Future<MathResult> combination(int n, int r) =>
      _call({'type': 'combination', 'n': n, 'r': r});

  Future<MathResult> sigma(String expr, int start, int end, {String v = 'k'}) =>
      _call({'type': 'sigma', 'expr': expr, 'variable': v, 'start': start, 'end': end});

  Future<MathResult> product(String expr, int start, int end, {String v = 'k'}) =>
      _call({'type': 'product', 'expr': expr, 'variable': v, 'start': start, 'end': end});

  Future<MathResult> statistics(String csv) =>
      _call({'type': 'statistics', 'data': csv});

  // ─── 代数 ───────────────────────────────────────────────
  Future<MathResult> expand(String expr) =>
      _call({'type': 'expand', 'expr': expr});

  Future<MathResult> factor(String expr) =>
      _call({'type': 'factor', 'expr': expr});

  Future<MathResult> solveEquation(String lhs, {String rhs = '0', String v = 'x'}) =>
      _call({'type': 'solveEquation', 'lhs': lhs, 'rhs': rhs, 'variable': v});

  Future<MathResult> quadratic(double a, double b, double c) =>
      _call({'type': 'quadratic', 'a': a, 'b': b, 'c': c});

  Future<MathResult> solveLinear2(
    double a1, double b1, double c1,
    double a2, double b2, double c2,
  ) => _call({'type': 'solveLinear2',
              'a1': a1, 'b1': b1, 'c1': c1,
              'a2': a2, 'b2': b2, 'c2': c2});

  // ─── 三角関数 ─────────────────────────────────────────
  Future<MathResult> trigSin(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_sin', 'x': x, 'unit': unit});
  Future<MathResult> trigCos(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_cos', 'x': x, 'unit': unit});
  Future<MathResult> trigTan(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_tan', 'x': x, 'unit': unit});
  Future<MathResult> trigAsin(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_asin', 'x': x, 'unit': unit});
  Future<MathResult> trigAcos(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_acos', 'x': x, 'unit': unit});
  Future<MathResult> trigAtan(String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_atan', 'x': x, 'unit': unit});
  Future<MathResult> trigAtan2(String y, String x, {String unit = 'rad'}) =>
      _call({'type': 'trig_atan2', 'y': y, 'x': x, 'unit': unit});
  Future<MathResult> degToRad(String d) =>
      _call({'type': 'degToRad', 'value': d});
  Future<MathResult> radToDeg(String r) =>
      _call({'type': 'radToDeg', 'value': r});
  Future<MathResult> trigSpecialValues(String fn) =>
      _call({'type': 'trig_special', 'fn': fn});

  // ─── 複素数 ──────────────────────────────────────────
  Future<MathResult> complexAdd(double r1, double i1, double r2, double i2) =>
      _call({'type': 'complex_add', 'r1': r1, 'i1': i1, 'r2': r2, 'i2': i2});
  Future<MathResult> complexSub(double r1, double i1, double r2, double i2) =>
      _call({'type': 'complex_sub', 'r1': r1, 'i1': i1, 'r2': r2, 'i2': i2});
  Future<MathResult> complexMul(double r1, double i1, double r2, double i2) =>
      _call({'type': 'complex_mul', 'r1': r1, 'i1': i1, 'r2': r2, 'i2': i2});
  Future<MathResult> complexDiv(double r1, double i1, double r2, double i2) =>
      _call({'type': 'complex_div', 'r1': r1, 'i1': i1, 'r2': r2, 'i2': i2});
  Future<MathResult> complexAbs(double re, double im) =>
      _call({'type': 'complex_abs', 're': re, 'im': im});
  Future<MathResult> complexArg(double re, double im) =>
      _call({'type': 'complex_arg', 're': re, 'im': im});
  Future<MathResult> complexConj(double re, double im) =>
      _call({'type': 'complex_conj', 're': re, 'im': im});
  Future<MathResult> complexPow(double re, double im, double n) =>
      _call({'type': 'complex_pow', 're': re, 'im': im, 'n': n});
  Future<MathResult> complexSqrt(double re, double im) =>
      _call({'type': 'complex_sqrt', 're': re, 'im': im});
  Future<MathResult> complexToPolar(double re, double im) =>
      _call({'type': 'complex_toPolar', 're': re, 'im': im});
  Future<MathResult> complexFromPolar(double r, double theta, {String unit = 'rad'}) =>
      _call({'type': 'complex_fromPolar', 'r': r, 'theta': theta, 'unit': unit});
  Future<MathResult> complexEval(String expr) =>
      _call({'type': 'complex_eval', 'expr': expr});

  // ─── 極限 ────────────────────────────────────────────
  Future<MathResult> limit(String expr, String point,
          {String v = 'x', String direction = 'both'}) =>
      _call({'type': 'limit', 'expr': expr, 'variable': v,
             'point': point, 'direction': direction});

  Future<MathResult> lhopital(String num, String den, String point,
          {String v = 'x'}) =>
      _call({'type': 'lhopital', 'numerator': num,
             'denominator': den, 'variable': v, 'point': point});

  // ─── 線形代数 ────────────────────────────────────────
  Future<MathResult> vecAdd(List<double> a, List<double> b) =>
      _call({'type': 'vec_add', 'a': a, 'b': b});
  Future<MathResult> vecSub(List<double> a, List<double> b) =>
      _call({'type': 'vec_sub', 'a': a, 'b': b});
  Future<MathResult> vecScale(List<double> a, double s) =>
      _call({'type': 'vec_scale', 'a': a, 'scalar': s});
  Future<MathResult> dot(List<double> a, List<double> b) =>
      _call({'type': 'dot', 'a': a, 'b': b});
  Future<MathResult> cross(List<double> a, List<double> b) =>
      _call({'type': 'cross', 'a': a, 'b': b});
  Future<MathResult> vecNorm(List<double> a) =>
      _call({'type': 'vec_norm', 'a': a});
  Future<MathResult> vecAngle(List<double> a, List<double> b) =>
      _call({'type': 'vec_angle', 'a': a, 'b': b});
  Future<MathResult> matAdd(List<List<double>> A, List<List<double>> B) =>
      _call({'type': 'mat_add', 'A': A, 'B': B});
  Future<MathResult> matSub(List<List<double>> A, List<List<double>> B) =>
      _call({'type': 'mat_sub', 'A': A, 'B': B});
  Future<MathResult> matMul(List<List<double>> A, List<List<double>> B) =>
      _call({'type': 'mat_mul', 'A': A, 'B': B});
  Future<MathResult> matInv(List<List<double>> A) =>
      _call({'type': 'mat_inv', 'A': A});
  Future<MathResult> det(List<List<double>> A) =>
      _call({'type': 'det', 'A': A});
  Future<MathResult> transpose(List<List<double>> A) =>
      _call({'type': 'transpose', 'A': A});
  Future<MathResult> eigenvalues(List<List<double>> A) =>
      _call({'type': 'eigenvalues', 'A': A});
  Future<MathResult> solveLinearSystem(
    List<List<double>> A, List<double> b,
  ) => _call({'type': 'solve_linear', 'A': A, 'b': b.map((v) => [v]).toList()});

  // ─── 整数論 ──────────────────────────────────────────
  Future<MathResult> primeFactorize(int n) =>
      _call({'type': 'prime_factorize', 'n': n});
  Future<MathResult> gcd(int a, int b) =>
      _call({'type': 'gcd', 'a': a, 'b': b});
  Future<MathResult> lcm(int a, int b) =>
      _call({'type': 'lcm', 'a': a, 'b': b});
  Future<MathResult> isPrime(int n) =>
      _call({'type': 'is_prime', 'n': n});
  Future<MathResult> baseConvert(String value, int fromBase, int toBase) =>
      _call({'type': 'base_convert', 'value': value,
             'fromBase': fromBase, 'toBase': toBase});
  Future<MathResult> sieve(int limit) =>
      _call({'type': 'sieve', 'limit': limit});
  Future<MathResult> euclidSteps(int a, int b) =>
      _call({'type': 'euclid_steps', 'a': a, 'b': b});

  // ─── グラフ ──────────────────────────────────────────
  Future<MathResult> plotPoints(String expr, double xMin, double xMax,
          {int points = 200}) =>
      _call({'type': 'plot_points', 'expr': expr,
             'xMin': xMin, 'xMax': xMax, 'points': points});

  Future<MathResult> plotMultiple(List<String> exprs, double xMin, double xMax,
          {int points = 200}) =>
      _call({'type': 'plot_multiple', 'exprs': exprs,
             'xMin': xMin, 'xMax': xMax, 'points': points});

  // ─── ユーティリティ ──────────────────────────────────
  static String preprocess(String input) => input
      .replaceAll('×', '*').replaceAll('÷', '/')
      .replaceAll('−', '-').replaceAll('√(', 'sqrt(')
      .replaceAll('π', 'pi').replaceAll('log(', 'log10(')
      .replaceAll('ln(', 'log(');

  static String formatNum(String result) {
    if (!result.contains('.') || result.contains('e')) return result;
    final parts = result.split('.');
    if (parts.length != 2) return result;
    final dec = parts[1].replaceAll(RegExp(r'0+$'), '');
    return dec.isEmpty ? parts[0] : '${parts[0]}.$dec';
  }
}

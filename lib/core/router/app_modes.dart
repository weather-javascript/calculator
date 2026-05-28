// lib/core/router/app_modes.dart
// 全14機能モードの定義（シングルソース・オブ・トゥルース）

import 'package:flutter/material.dart';

enum CalcMode {
  // Phase 1 (既存)
  basic,
  applied,
  functions,
  combinatorics,
  calculus,
  sequences,
  statistics,
  // Phase 2 (新規)
  algebra,
  trigonometry,
  complex,
  limits,
  linearAlgebra,
  numberTheory,
  graph,
}

class ModeGroup {
  final String label;
  final List<CalcMode> modes;
  const ModeGroup({required this.label, required this.modes});
}

class ModeInfo {
  final CalcMode mode;
  final String label;
  final String shortLabel;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String curriculumTag; // 数I/数II/数III etc.

  const ModeInfo({
    required this.mode,
    required this.label,
    required this.shortLabel,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.curriculumTag,
  });
}

class AppModes {
  static const List<ModeGroup> groups = [
    ModeGroup(label: '基本計算', modes: [
      CalcMode.basic,
      CalcMode.applied,
      CalcMode.functions,
    ]),
    ModeGroup(label: '数 I・A', modes: [
      CalcMode.algebra,
      CalcMode.combinatorics,
      CalcMode.numberTheory,
      CalcMode.statistics,
    ]),
    ModeGroup(label: '数 II・B', modes: [
      CalcMode.trigonometry,
      CalcMode.complex,
      CalcMode.sequences,
      CalcMode.linearAlgebra,
    ]),
    ModeGroup(label: '数 III・C', modes: [
      CalcMode.calculus,
      CalcMode.limits,
      CalcMode.graph,
    ]),
  ];

  static const Map<CalcMode, ModeInfo> info = {
    CalcMode.basic: ModeInfo(
      mode: CalcMode.basic,
      label: '四則演算',
      shortLabel: '±×÷',
      subtitle: '基本的な四則演算',
      icon: Icons.calculate_outlined,
      color: Color(0xFF3B82F6),
      curriculumTag: '基本',
    ),
    CalcMode.applied: ModeInfo(
      mode: CalcMode.applied,
      label: '応用計算',
      shortLabel: '√%!',
      subtitle: '平方根・パーセント・階乗',
      icon: Icons.functions,
      color: Color(0xFF00E5FF),
      curriculumTag: '基本',
    ),
    CalcMode.functions: ModeInfo(
      mode: CalcMode.functions,
      label: '関数',
      shortLabel: 'f(x)',
      subtitle: '指数・対数・三角',
      icon: Icons.timeline,
      color: Color(0xFFF59E0B),
      curriculumTag: '数II',
    ),
    CalcMode.algebra: ModeInfo(
      mode: CalcMode.algebra,
      label: '代数・方程式',
      shortLabel: 'ax²',
      subtitle: '展開・因数分解・方程式',
      icon: Icons.data_object,
      color: Color(0xFF6366F1),
      curriculumTag: '数I',
    ),
    CalcMode.combinatorics: ModeInfo(
      mode: CalcMode.combinatorics,
      label: '場合の数',
      shortLabel: 'nPr',
      subtitle: '順列・組合せ・確率',
      icon: Icons.grid_view,
      color: Color(0xFF8B5CF6),
      curriculumTag: '数A',
    ),
    CalcMode.numberTheory: ModeInfo(
      mode: CalcMode.numberTheory,
      label: '整数の性質',
      shortLabel: 'GCD',
      subtitle: '素因数分解・GCD・進数変換',
      icon: Icons.tag,
      color: Color(0xFFEA580C),
      curriculumTag: '数A',
    ),
    CalcMode.statistics: ModeInfo(
      mode: CalcMode.statistics,
      label: '統計',
      shortLabel: 'σ²',
      subtitle: '平均・分散・標準偏差',
      icon: Icons.bar_chart,
      color: Color(0xFF14B8A6),
      curriculumTag: '数I',
    ),
    CalcMode.trigonometry: ModeInfo(
      mode: CalcMode.trigonometry,
      label: '三角関数',
      shortLabel: 'sin',
      subtitle: 'sin/cos/tan・逆三角・弧度法',
      icon: Icons.waves,
      color: Color(0xFF22C55E),
      curriculumTag: '数II',
    ),
    CalcMode.complex: ModeInfo(
      mode: CalcMode.complex,
      label: '複素数',
      shortLabel: 'a+bi',
      subtitle: '複素数演算・極形式',
      icon: Icons.circle_outlined,
      color: Color(0xFFEC4899),
      curriculumTag: '数II',
    ),
    CalcMode.sequences: ModeInfo(
      mode: CalcMode.sequences,
      label: '数列',
      shortLabel: 'Σ',
      subtitle: 'シグマ・漸化式・一般項',
      icon: Icons.format_list_numbered,
      color: Color(0xFFD946EF),
      curriculumTag: '数B',
    ),
    CalcMode.linearAlgebra: ModeInfo(
      mode: CalcMode.linearAlgebra,
      label: 'ベクトル・行列',
      shortLabel: 'Av',
      subtitle: '内積・外積・行列・行列式',
      icon: Icons.grid_on,
      color: Color(0xFF0EA5E9),
      curriculumTag: '数C',
    ),
    CalcMode.calculus: ModeInfo(
      mode: CalcMode.calculus,
      label: '微分・積分',
      shortLabel: '∫',
      subtitle: '記号微分・数値積分',
      icon: Icons.show_chart,
      color: Color(0xFF10B981),
      curriculumTag: '数III',
    ),
    CalcMode.limits: ModeInfo(
      mode: CalcMode.limits,
      label: '極限',
      shortLabel: 'lim',
      subtitle: '関数の極限・ロピタル',
      icon: Icons.arrow_forward_outlined,
      color: Color(0xFFF97316),
      curriculumTag: '数III',
    ),
    CalcMode.graph: ModeInfo(
      mode: CalcMode.graph,
      label: 'グラフ描画',
      shortLabel: '📈',
      subtitle: 'y=f(x) の可視化',
      icon: Icons.area_chart,
      color: Color(0xFFEAB308),
      curriculumTag: '全般',
    ),
  };

  static ModeInfo get(CalcMode m) => info[m]!;
  static Color colorOf(CalcMode m) => info[m]!.color;
}

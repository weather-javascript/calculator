// lib/features/linear_algebra/widgets/matrix_input_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MatrixInputWidget extends StatelessWidget {
  final String label;
  final List<List<String>> matrix;
  final Color color;
  final void Function(int row, int col, String value) onChanged;

  const MatrixInputWidget({
    super.key,
    required this.label,
    required this.matrix,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rows = matrix.length;
    final cols = matrix.isEmpty ? 0 : matrix[0].length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.8)),
        const SizedBox(width: 8),
        Text('$rows×$cols',
            style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 10,
                color: color.withOpacity(0.7))),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: List.generate(
              rows,
              (r) => Padding(
                    padding: EdgeInsets.only(bottom: r < rows - 1 ? 6 : 0),
                    child: Row(
                      children: List.generate(
                          cols,
                          (c) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: c < cols - 1 ? 6 : 0),
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: TextEditingController(
                                          text: matrix[r][c])
                                        ..selection = TextSelection.collapsed(
                                            offset: matrix[r][c].length),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.surfaceCard,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: BorderSide(
                                                color:
                                                    color.withOpacity(0.25))),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: BorderSide(
                                                color:
                                                    color.withOpacity(0.25))),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: BorderSide(
                                                color: color, width: 1.5)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 0),
                                        hintText: '0',
                                        hintStyle: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12),
                                      ),
                                      style: const TextStyle(
                                          fontFamily: 'IBM Plex Mono',
                                          fontSize: 13,
                                          color: AppTheme.textPrimary),
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              signed: true, decimal: true),
                                      onChanged: (v) => onChanged(r, c, v),
                                    ),
                                  ),
                                ),
                              )),
                    ),
                  )),
        ),
      ),
    ]);
  }
}

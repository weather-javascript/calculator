// lib/features/linear_algebra/widgets/vector_input_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VectorInputWidget extends StatelessWidget {
  final String label;
  final List<String> values; // 3 elements
  final Color color;
  final void Function(int index, String value) onChanged;

  const VectorInputWidget({
    super.key,
    required this.label,
    required this.values,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final comps = ['x', 'y', 'z'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        fontFamily: 'Space Grotesk', fontSize: 11,
        fontWeight: FontWeight.w600, color: color, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      Row(children: List.generate(values.length, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < values.length - 1 ? 8 : 0),
          child: Column(children: [
            Text(comps[i], style: TextStyle(
              fontFamily: 'IBM Plex Mono', fontSize: 11, color: color)),
            const SizedBox(height: 3),
            TextField(
              controller: TextEditingController(text: values[i])
                ..selection = TextSelection.collapsed(offset: values[i].length),
              decoration: InputDecoration(
                filled: true,
                fillColor: color.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                hintText: '0',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              style: const TextStyle(fontFamily: 'IBM Plex Mono',
                fontSize: 14, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
              onChanged: (v) => onChanged(i, v),
            ),
          ]),
        ),
      ))),
    ]);
  }
}

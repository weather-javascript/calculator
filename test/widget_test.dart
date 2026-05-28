// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_calculator/models/calculator_state.dart';
import 'package:advanced_calculator/core/engine/math_engine_service.dart';
import 'package:advanced_calculator/core/router/app_modes.dart';

void main() {
  group('CalculatorState', () {
    late CalculatorState s;
    setUp(() => s = CalculatorState());

    test('初期値', () {
      expect(s.displayExpression, '');
      expect(s.mode, CalcMode.basic);
      expect(s.hasError, false);
    });
    test('数字入力', () {
      s.inputDigit('1'); s.inputDigit('2');
      expect(s.currentExpression, '12');
    });
    test('クリア', () {
      s.inputDigit('9'); s.clearAll();
      expect(s.currentExpression, '');
    });
    test('バックスペース', () {
      s.inputDigit('1'); s.inputDigit('2'); s.backspace();
      expect(s.currentExpression, '1');
    });
    test('履歴', () {
      s.setResult('1+1', '2');
      expect(s.history.length, 1);
    });
    test('マルチフィールド', () {
      s.setActiveField('field3');
      s.appendToActive('99');
      expect(s.field3, '99');
    });
  });

  group('MathEngineService.preprocess', () {
    test('×→*', () => expect(MathEngineService.preprocess('3×4'), '3*4'));
    test('÷→/', () => expect(MathEngineService.preprocess('8÷2'), '8/2'));
    test('−→-', () => expect(MathEngineService.preprocess('5−3'), '5-3'));
    test('√→sqrt', () => expect(MathEngineService.preprocess('√(9)'), 'sqrt(9)'));
    test('π→pi', () => expect(MathEngineService.preprocess('2π'), '2pi'));
    test('log→log10', () => expect(MathEngineService.preprocess('log(100)'), 'log10(100)'));
    test('ln→log', () => expect(MathEngineService.preprocess('ln(e)'), 'log(e)'));
  });

  group('MathEngineService.formatNum', () {
    test('末尾ゼロ除去', () => expect(MathEngineService.formatNum('3.500'), '3.5'));
    test('整数化', () => expect(MathEngineService.formatNum('4.000'), '4'));
    test('科学記数そのまま', () => expect(MathEngineService.formatNum('1.2e10'), '1.2e10'));
  });

  group('AppModes', () {
    test('全14モード定義', () {
      expect(CalcMode.values.length, 14);
      for (final m in CalcMode.values) {
        expect(AppModes.info.containsKey(m), true);
      }
    });
    test('get()正常', () {
      expect(AppModes.get(CalcMode.calculus).shortLabel, '∫');
      expect(AppModes.get(CalcMode.algebra).curriculumTag, '数I');
    });
    test('グループ網羅', () {
      final all = AppModes.groups.expand((g) => g.modes).toList();
      for (final m in CalcMode.values) {
        expect(all.contains(m), true, reason: '$m がグループ未登録');
      }
    });
  });
}

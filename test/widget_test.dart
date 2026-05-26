// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_calculator/models/calculator_state.dart';
import 'package:advanced_calculator/services/math_engine_service.dart';

void main() {
  group('CalculatorState Tests', () {
    late CalculatorState state;

    setUp(() {
      state = CalculatorState();
    });

    test('初期状態のテスト', () {
      expect(state.displayExpression, '');
      expect(state.displayResult, '');
      expect(state.hasError, false);
      expect(state.mode, CalculatorMode.basic);
    });

    test('数字入力のテスト', () {
      state.inputDigit('1');
      state.inputDigit('2');
      state.inputDigit('3');
      expect(state.currentExpression, '123');
    });

    test('演算子入力のテスト', () {
      state.inputDigit('5');
      state.inputOperator('+');
      state.inputDigit('3');
      expect(state.currentExpression, '5+3');
    });

    test('AC クリアのテスト', () {
      state.inputDigit('9');
      state.inputOperator('*');
      state.clearAll();
      expect(state.currentExpression, '');
    });

    test('バックスペースのテスト', () {
      state.inputDigit('1');
      state.inputDigit('2');
      state.backspace();
      expect(state.currentExpression, '1');
    });

    test('モード変更のテスト', () {
      state.setMode(CalculatorMode.calculus);
      expect(state.mode, CalculatorMode.calculus);
    });

    test('履歴に追加されるテスト', () {
      state.setResult('2+3', '5');
      expect(state.history.length, 1);
      expect(state.history.first.expression, '2+3');
      expect(state.history.first.result, '5');
    });
  });

  group('MathEngineService 前処理テスト', () {
    test('乗算記号の変換', () {
      expect(MathEngineService.preprocessExpression('3×4'), '3*4');
    });

    test('除算記号の変換', () {
      expect(MathEngineService.preprocessExpression('8÷2'), '8/2');
    });

    test('√ の変換', () {
      expect(MathEngineService.preprocessExpression('√(9)'), 'sqrt(9)');
    });

    test('π の変換', () {
      expect(MathEngineService.preprocessExpression('2π'), '2pi');
    });

    test('log の変換', () {
      expect(MathEngineService.preprocessExpression('log(100)'), 'log10(100)');
    });

    test('ln の変換', () {
      expect(MathEngineService.preprocessExpression('ln(e)'), 'log(e)');
    });

    test('結果フォーマット - 末尾ゼロ除去', () {
      expect(MathEngineService.formatResult('3.50000'), '3.5');
    });

    test('結果フォーマット - 整数', () {
      expect(MathEngineService.formatResult('4.0000'), '4');
    });
  });
}

// lib/models/calculator_state.dart

import 'package:flutter/foundation.dart';
import '../core/router/app_modes.dart';

class HistoryEntry {
  final String expression;
  final String result;
  final CalcMode mode;
  final DateTime timestamp;
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.mode,
    required this.timestamp,
  });
}

class CalculatorState extends ChangeNotifier {
  String _displayExpression = '';
  String _displayResult = '';
  bool _hasError = false;
  bool _isCalculating = false;
  String _inputBuffer = '';
  bool _justCalculated = false;
  CalcMode _mode = CalcMode.basic;
  final List<HistoryEntry> _history = [];

  // Multi-field support for calculus/combinatorics/sequences screens
  String _field1 = '';
  String _field2 = '';
  String _field3 = '';
  String _field4 = '';
  String _activeField = 'field1';

  String get displayExpression => _displayExpression;
  String get displayResult => _displayResult;
  bool get hasError => _hasError;
  bool get isCalculating => _isCalculating;
  CalcMode get mode => _mode;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  String get field1 => _field1;
  String get field2 => _field2;
  String get field3 => _field3;
  String get field4 => _field4;
  String get activeField => _activeField;

  void setMode(CalcMode mode) {
    _mode = mode;
    clearAll();
    notifyListeners();
  }

  void setActiveField(String field) {
    _activeField = field;
    notifyListeners();
  }

  void appendToActive(String value) {
    switch (_activeField) {
      case 'field1':
        _field1 += value;
        break;
      case 'field2':
        _field2 += value;
        break;
      case 'field3':
        _field3 += value;
        break;
      case 'field4':
        _field4 += value;
        break;
      default:
        _inputBuffer += value;
    }
    _syncDisplay();
    notifyListeners();
  }

  void inputDigit(String digit) {
    if (_justCalculated && !_isOp(digit)) {
      clearAll();
      _justCalculated = false;
    }
    _inputBuffer += digit;
    _displayExpression = _inputBuffer;
    notifyListeners();
  }

  void inputOperator(String op) {
    _justCalculated = false;
    _inputBuffer += op;
    _displayExpression = _inputBuffer;
    notifyListeners();
  }

  void inputFunction(String func) {
    _inputBuffer += func;
    _displayExpression = _inputBuffer;
    notifyListeners();
  }

  void inputDecimal() {
    final lastNum = _inputBuffer.split(RegExp(r'[+\-*/]')).last;
    if (!lastNum.contains('.')) {
      if (lastNum.isEmpty) _inputBuffer += '0';
      _inputBuffer += '.';
      _displayExpression = _inputBuffer;
      notifyListeners();
    }
  }

  void backspace() {
    if (_activeField != 'field1' && _activeField != '') {
      switch (_activeField) {
        case 'field2':
          if (_field2.isNotEmpty) {
            _field2 = _field2.substring(0, _field2.length - 1);
          }
          break;
        case 'field3':
          if (_field3.isNotEmpty) {
            _field3 = _field3.substring(0, _field3.length - 1);
          }
          break;
        case 'field4':
          if (_field4.isNotEmpty) {
            _field4 = _field4.substring(0, _field4.length - 1);
          }
          break;
        default:
          if (_field1.isNotEmpty) {
            _field1 = _field1.substring(0, _field1.length - 1);
          }
      }
    } else {
      if (_inputBuffer.isNotEmpty) {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
        _displayExpression = _inputBuffer;
      }
    }
    notifyListeners();
  }

  void clearAll() {
    _inputBuffer = '';
    _displayExpression = '';
    _displayResult = '';
    _hasError = false;
    _justCalculated = false;
    _field1 = _field2 = _field3 = _field4 = '';
    _activeField = 'field1';
    notifyListeners();
  }

  void clearEntry() {
    switch (_activeField) {
      case 'field2':
        _field2 = '';
        break;
      case 'field3':
        _field3 = '';
        break;
      case 'field4':
        _field4 = '';
        break;
      default:
        _field1 = '';
        _inputBuffer = '';
    }
    _displayExpression = _inputBuffer;
    notifyListeners();
  }

  void setResult(String expression, String result, {bool isError = false}) {
    _displayExpression = expression;
    _displayResult = result;
    _hasError = isError;
    _isCalculating = false;
    _justCalculated = true;
    if (!isError) {
      _addHistory(expression, result);
      _inputBuffer = result;
    }
    notifyListeners();
  }

  void setCalculating(bool v) {
    _isCalculating = v;
    notifyListeners();
  }

  void useHistoryResult(HistoryEntry entry) {
    _inputBuffer = entry.result;
    _displayExpression = entry.expression;
    _displayResult = entry.result;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  String get currentExpression => _inputBuffer.isEmpty ? _field1 : _inputBuffer;

  void _syncDisplay() {
    if (_activeField == 'field1') _displayExpression = _field1;
  }

  void _addHistory(String expression, String result) {
    _history.insert(
        0,
        HistoryEntry(
            expression: expression,
            result: result,
            mode: _mode,
            timestamp: DateTime.now()));
    if (_history.length > 100) _history.removeRange(100, _history.length);
  }

  bool _isOp(String s) => ['+', '-', '*', '/', '×', '÷'].contains(s);
}

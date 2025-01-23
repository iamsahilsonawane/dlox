import 'package:dlox/interpreter/errors/runtime_error.dart';

import 'dlox.dart';

class Environment { 
  final _values = <String, Object?>{};

  Object? get(Token token) {
    if (_values.containsKey(token.lexeme)) {
      return _values[token.lexeme];
    }

    throw RuntimeError(token, "Undefined variable ${token.lexeme}.");
  }

  void define(String name, Object? value) {
    _values[name] = value;
  }
}

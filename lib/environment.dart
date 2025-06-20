import 'dlox.dart';
import 'package:dlox/interpreter/errors/runtime_error.dart';

class UninitialisedVar {}

class Environment {
  final Environment? enclosing;

  Environment(this.enclosing);
  Environment.root() : enclosing = null;

  final _values = <String, Object?>{};

  Object? get(Token token) {
    if (_values.containsKey(token.lexeme)) {
      if (_values[token.lexeme] is UninitialisedVar) {
        throw RuntimeError(
            token, "Tried to access uninitialised variable '${token.lexeme}'.");
      }
      return _values[token.lexeme];
    }

    if (enclosing != null) {
      return enclosing!.get(token);
    }

    throw RuntimeError(token, "Undefined variable '${token.lexeme}'.");
  }

  Object? getAt(Token token, int distance) {
    return ancestor(distance).get(token);
  }

  Environment ancestor(int distance) {
    Environment targetEnv = this;
    for (var i = 0; i < distance; i++) {
      targetEnv = enclosing!;
    }
    return targetEnv;
  }

  void define(String name, Object? value) {
    _values[name] = value;
  }

  void assignAt(int distance, Token name, Object? value) {
    ancestor(distance).assign(name, value);
  }

  void assign(Token name, Object? value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    if (enclosing != null) {
      return enclosing!.assign(name, value);
    }

    throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
  }
}

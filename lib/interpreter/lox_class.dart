
import 'package:dlox/interpreter/errors/runtime_error.dart';
import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/interpreter/lox_callable.dart';
import 'package:dlox/interpreter/lox_function.dart';

import '../scanner/token.dart';

class LoxClass implements LoxCallable {
  final String name;
  final Map<String, LoxFunction> methods;

  LoxClass(this.name, this.methods);

  LoxFunction? getMethod(String name) {
    return methods[name];
  }

  @override
  String toString() {
    return name;
  }

  @override
  int arity() {
    return 0;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    LoxInstance instance = LoxInstance(this);
    return instance;
  }
}


class LoxInstance {
  final LoxClass klass;
  final Map<String, Object> fields = {};
  
  LoxInstance(this.klass);

  Object get(Token name) {
    if (fields.containsKey(name.lexeme)) {
      return fields[name.lexeme]!;
    } 

    final method = klass.getMethod(name.lexeme) ;
    if (method != null) {
      return method;
    }

    throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
  }

  void set(Token name, Object value) {
    fields[name.lexeme] = value;
  }

  @override
  String toString() {
    return "${klass.name} instance"; 
  }
}


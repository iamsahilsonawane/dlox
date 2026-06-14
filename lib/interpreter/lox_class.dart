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
    final constructor = getMethod("init");
    if (constructor != null) {
      return constructor.arity();
    }
    return 0;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    LoxInstance instance = LoxInstance(this);
    final constructor = getMethod("init");
    if (constructor != null) {
      constructor.bind(instance).call(interpreter, arguments);
    }
    return instance;
  }
}

class LoxMetaclass extends LoxInstance implements LoxCallable {
  final LoxClass targetKlass;

  LoxMetaclass(LoxClass metaclass, this.targetKlass) : super(metaclass); //we're creating a LoxInstance for the metaclass, so actions on the metaclass happens

  @override
  int arity() => targetKlass.arity();

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    return targetKlass.call(interpreter, arguments);
  }

  @override
  String toString() {
    return targetKlass.toString();
  }
}

class LoxInstance {
  final LoxClass? klass;
  final Map<String, Object> fields = {};

  LoxInstance(this.klass);

  Object get(Token name) {
    if (fields.containsKey(name.lexeme)) {
      return fields[name.lexeme]!;
    }

    final method = klass?.getMethod(name.lexeme);
    if (method != null) {
      return method.bind(this);
    }

    throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
  }

  void set(Token name, Object value) {
    fields[name.lexeme] = value;
  }

  @override
  String toString() {
    return "${klass?.name ?? "baseMetaClass"} instance";
  }
}

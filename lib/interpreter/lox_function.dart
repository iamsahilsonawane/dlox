import 'package:dlox/ast/stmt.g.dart';
import 'package:dlox/environment.dart';
import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/interpreter/lox_callable.dart';

class LoxFunction implements LoxCallable {
  final LFunction declaration;
  final Environment closure;
  LoxFunction(this.declaration, this.closure);

  @override
  int arity() {
    return declaration.params.length;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    final environment = Environment(closure);

    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(declaration.body, environment);
    } on ReturnException catch (returnValue) {
      return returnValue.value;
    }

    return null;
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }
}

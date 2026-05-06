import 'package:dlox/ast/stmt.g.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/environment.dart';
import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/interpreter/lox_callable.dart';
import 'package:dlox/interpreter/lox_class.dart';

class LoxFunction extends LoxLamda {
  final LFunction declaration;

  LoxFunction(this.declaration, Environment? closure)
      : super(declaration.lambda, closure);

  LoxFunction bind(LoxInstance instance) {
    Environment env = Environment(closure);
    env.define(instance);
    return LoxFunction(declaration, env);
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }
}

class LoxLamda implements LoxCallable {
  final Lambda lambda;
  final Environment? closure;

  LoxLamda(this.lambda, this.closure);

  @override
  int arity() {
    return lambda.params.length;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    final environment = Environment(closure);

    for (int i = 0; i < lambda.params.length; i++) {
      environment.define(arguments[i]);
    }

    try {
      interpreter.executeBlock(lambda.body, environment);
    } on ReturnException catch (returnValue) {
      return returnValue.value;
    }

    return null;
  }

  @override
  String toString() {
    return "<lambda fn>";
  }
}

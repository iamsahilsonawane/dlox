import 'package:dlox/ast/stmt.g.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/environment.dart';
import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/interpreter/lox_callable.dart';
import 'package:dlox/interpreter/lox_class.dart';

class LoxFunction extends LoxLamda {
  final LFunction declaration;
  final bool isInitializer;

  LoxFunction(this.declaration, Environment? closure,
      {this.isInitializer = false})
      : super(declaration.lambda, closure);

  LoxFunction bind(LoxInstance instance) {
    Environment env = Environment(closure);
    env.define(instance);
    return LoxFunction(declaration, env, isInitializer: isInitializer);
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    final result = super.call(interpreter, arguments);
    if (isInitializer) {
      return closure?.getAt(0,
          0); //'this' is the first definition in the class environment, therefore 0
    }
    return result;
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }

  bool get isGetter {
    return lambda.params == null;
  }
}

class LoxLamda implements LoxCallable {
  final Lambda lambda;
  final Environment? closure;

  LoxLamda(this.lambda, this.closure);

  @override
  int arity() {
    return lambda.params?.length ?? 0;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    final environment = Environment(closure);

    if (lambda.params != null) {
      for (int i = 0; i < lambda.params!.length; i++) {
        environment.define(arguments[i]);
      }
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

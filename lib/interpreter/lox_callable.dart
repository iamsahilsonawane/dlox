import 'package:dlox/interpreter/interpreter.dart';

abstract class LoxCallable {
  Object? call(Interpreter interpreter, List<Object> arguments);
  int arity();
}

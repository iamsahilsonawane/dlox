import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/interpreter/lox_callable.dart';

class ClockFF implements LoxCallable {
  @override
  int arity() {
    return 0;
  }

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
    String toString() {
      return "<native fn>";
    }
  }

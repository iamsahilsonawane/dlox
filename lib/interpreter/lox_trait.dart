import 'package:dlox/interpreter/lox_function.dart';
import 'package:dlox/scanner/token.dart';

class LoxTrait {
  final Token name;
  final Map<String, LoxFunction> methods;

  LoxTrait(this.name, this.methods);

  @override
  String toString() {
    return name.lexeme;
  }
}

import 'package:dlox/ast/expr.g.dart';

// Reverse Polish Notation (RPN)
// https://en.wikipedia.org/wiki/Reverse_Polish_notation
class AstPrinterRPNNotation implements Visitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  visitBinaryExpr(Binary expr) {
    return "${expr.left.accept(this)} ${expr.right.accept(this)} ${expr.operator.lexeme}";
  }

  @override
  visitGroupingExpr(Grouping expr) {
    return expr.expression.accept(this);
  }

  @override
  visitLiteralExpr(Literal expr) {
    if (expr.value == Null || expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  visitUnaryExpr(Unary expr) {
    return "${expr.right.accept(this)} ${expr.operator.lexeme}";
  }
}

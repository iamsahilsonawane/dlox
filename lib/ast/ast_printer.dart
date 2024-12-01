import 'package:dlox/ast/expr.g.dart';

class AstPrinter implements Visitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  visitBinaryExpr(Binary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  visitGroupingExpr(Grouping expr) {
    return _parenthesize("group", [expr.expression]);
  }

  @override
  visitLiteralExpr(Literal expr) {
    if (expr.value == Null || expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  visitUnaryExpr(Unary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.right]);
  }

  String _parenthesize(String name, List<Expr> exprs) {
    StringBuffer builder = StringBuffer();

    builder
      ..write("(")
      ..write(name);

    for (Expr expr in exprs) {
      builder
        ..write(" ")
        ..write(expr.accept(this));
    }
    builder.write(")");

    return builder.toString();
  }
}

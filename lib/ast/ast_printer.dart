import 'package:dlox/ast/expr.g.dart';
import 'package:dlox/ast/stmt.g.dart' as pkg_stmt;

class AstPrinter with Visitor<String> {
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

  @override
  String visitConditionalExpr(Conditional expr) {
    return "( if ${expr.expr.accept(this)} ${(_parenthesize('', [
          expr.thenBranch,
          expr.elseBranch
        ]))}";
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

  @override
  String visitVariableExpr(Variable expr) {
    throw UnimplementedError();
  }

  @override
  String visitAssignExpr(Assign expr) {
    // TODO: implement visitAssignExpr
    throw UnimplementedError();
  }

  @override
  String visitLogicalExpr(Logical expr) {
    // TODO: implement visitLogicalExpr
    throw UnimplementedError();
  }

  @override
  String visitCallExpr(Call expr) {
    // TODO: implement visitCallExpr
    throw UnimplementedError();
  }

  @override
  String visitLambdaExpr(Lambda expr) {
    // TODO: implement visitLambdaExpr
    throw UnimplementedError();
  }
}

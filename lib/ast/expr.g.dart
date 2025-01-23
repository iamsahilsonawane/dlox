import "package:dlox/dlox.dart";

abstract class Expr {
  R accept<R>(Visitor<R> visitor);
}

mixin Visitor<R> {
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
  R visitConditionalExpr(Conditional expr);
  R visitVariableExpr(Variable expr);
}

class Binary extends Expr {
  Binary({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }

  final Expr left;
  final Token operator;
  final Expr right;
}

class Grouping extends Expr {
  Grouping({
    required this.expression,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }

  final Expr expression;
}

class Literal extends Expr {
  Literal({
    required this.value,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }

  final Object? value;
}

class Unary extends Expr {
  Unary({
    required this.operator,
    required this.right,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }

  final Token operator;
  final Expr right;
}

class Conditional extends Expr {
  Conditional({
    required this.expr,
    required this.thenBranch,
    required this.elseBranch,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitConditionalExpr(this);
  }

  final Expr expr;
  final Expr thenBranch;
  final Expr elseBranch;
}

class Variable extends Expr {
  Variable({
    required this.name,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }

  final Token name;
}


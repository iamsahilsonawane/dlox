import "package:dlox/dlox.dart";

import "stmt.g.dart";

abstract class Expr {
  R accept<R>(Visitor<R> visitor);
}

mixin Visitor<R> {
  R visitAssignExpr(Assign expr);
  R visitBinaryExpr(Binary expr);
  R visitLogicalExpr(Logical expr);
  R visitCallExpr(Call expr);
  R visitGetExpr(Get expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
  R visitLSetExpr(LSet expr);
  R visitLambdaExpr(Lambda expr);
  R visitConditionalExpr(Conditional expr);
  R visitVariableExpr(Variable expr);
}

class Assign extends Expr {
  Assign({
    required this.name,
    required this.value,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }

  final Token name;
  final Expr value;
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

class Logical extends Expr {
  Logical({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLogicalExpr(this);
  }

  final Expr left;
  final Token operator;
  final Expr right;
}

class Call extends Expr {
  Call({
    required this.callee,
    required this.paren,
    required this.arguments,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitCallExpr(this);
  }

  final Expr callee;
  final Token paren;
  final List<Expr> arguments;
}

class Get extends Expr {
  Get({
    required this.object,
    required this.name,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitGetExpr(this);
  }

  final Expr object;
  final Token name;
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

class LSet extends Expr {
  LSet({
    required this.object,
    required this.name,
    required this.value,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLSetExpr(this);
  }

  final Expr object;
  final Token name;
  final Expr value;
}

class Lambda extends Expr {
  Lambda({
    required this.params,
    required this.body,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLambdaExpr(this);
  }

  final List<Token> params;
  final List<Stmt> body;
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


import "package:dlox/dlox.dart";

abstract class Stmt {
  R accept<R>(Visitor<R> visitor);
}

mixin Visitor<R> {
  R visitBlockStmt(Block stmt);
  R visitIfStmt(If stmt);
  R visitBreakStmt(Break stmt);
  R visitExpressionStmt(Expression stmt);
  R visitLFunctionStmt(LFunction stmt);
  R visitReturnStmt(Return stmt);
  R visitPrintStmt(Print stmt);
  R visitWhileStmt(While stmt);
  R visitVarStmt(Var stmt);
}

class Block extends Stmt {
  Block({
    required this.statements,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBlockStmt(this);
  }

  final List<Stmt> statements;
}

class If extends Stmt {
  If({
    required this.conditional,
    required this.thenBranch,
    required this.elseBranch,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitIfStmt(this);
  }

  final Expr conditional;
  final Stmt thenBranch;
  final Stmt? elseBranch;
}

class Break extends Stmt {
  Break();

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBreakStmt(this);
  }
}

class Expression extends Stmt {
  Expression({
    required this.expression,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }

  final Expr expression;
}

class LFunction extends Stmt {
  LFunction({
    required this.name,
    required this.params,
    required this.body,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLFunctionStmt(this);
  }

  final Token name;
  final List<Token> params;
  final List<Stmt> body;
}

class Return extends Stmt {
  Return({
    required this.token,
    required this.value,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitReturnStmt(this);
  }

  final Token token;
  final Expr? value;
}

class Print extends Stmt {
  Print({
    required this.expression,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }

  final Expr expression;
}

class While extends Stmt {
  While({
    required this.condition,
    required this.body,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitWhileStmt(this);
  }

  final Expr condition;
  final Stmt body;
}

class Var extends Stmt {
  Var({
    required this.name,
    required this.initializer,
  });

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitVarStmt(this);
  }

  final Token name;
  final Expr? initializer;
}


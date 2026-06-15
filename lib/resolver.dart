import 'package:dlox/ast/expr.g.dart' as pkg_expr;
import 'package:dlox/ast/stmt.g.dart' as pkg_stmt;
import 'package:dlox/ast/stmt.g.dart';
import 'package:dlox/data_structures/stack.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/interpreter/interpreter.dart';

enum FunctionType { none, function, method, initializer }

enum ClassType { none, klass, subclass, trait }

class VariableUsage {
  final int slot;
  final Token variable;
  VariableUsageType type;
  final bool synthetic;

  VariableUsage(this.slot, this.type, this.variable, {this.synthetic = false});
}

enum VariableUsageType { defined, declared, used }

class Resolver with pkg_expr.Visitor<Object?>, pkg_stmt.Visitor<void> {
  final Interpreter interpreter;
  final scopes = Stack<Map<String, VariableUsage>>();
  FunctionType currentFunctionType = FunctionType.none;
  ClassType currentClass = ClassType.none;
  Resolver(this.interpreter);

  void resolve(List<pkg_stmt.Stmt> statements) {
    _resolveStatements(statements);
  }

  @override
  Object? visitAssignExpr(pkg_expr.Assign expr) {
    _resolveExpr(expr.value);
    _resolveLocal(expr, expr.name, false);

    return null;
  }

  @override
  Object? visitBinaryExpr(pkg_expr.Binary expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
    return null;
  }

  @override
  void visitBlockStmt(pkg_stmt.Block stmt) {
    _beginScope();
    _resolveStatements(stmt.statements);
    _endScope();
  }

  void _beginScope() {
    scopes.push(<String, VariableUsage>{});
  }

  void _endScope() {
    final scope = scopes.pop();
    for (final entry in scope.entries) {
      if (entry.value.synthetic) continue;
      if (entry.value.type != VariableUsageType.used) {
        DLox.errorAt(entry.value.variable,
            "Variable '${entry.key}' declared but was never used");
      }
    }
  }

  void _resolveStatements(List<Stmt> statements) {
    for (Stmt statement in statements) {
      _resolveStmt(statement);
    }
  }

  void _resolveStmt(Stmt stmt) {
    stmt.accept(this);
  }

  void _resolveExpr(Expr expr) {
    expr.accept(this);
  }

  void _declare(Token name) {
    if (scopes.isEmpty) return;
    final scope = scopes.peek;
    if (scope[name.lexeme] != null) {
      DLox.errorAt(name, "Already a variable with the same name in the scope.");
    }
    scope[name.lexeme] =
        VariableUsage(scope.length, VariableUsageType.declared, name);
  }

  void _define(Token name) {
    if (scopes.isEmpty) return;
    scopes.peek[name.lexeme]!.type = VariableUsageType.defined;
  }

  @override
  void visitBreakStmt(pkg_stmt.Break stmt) {
    return;
  }

  @override
  Object? visitCallExpr(pkg_expr.Call expr) {
    _resolveExpr(expr.callee);
    for (final arg in expr.arguments) {
      _resolveExpr(arg);
    }
    return null;
  }

  @override
  Object? visitConditionalExpr(pkg_expr.Conditional expr) {
    _resolveExpr(expr.expr);
    _resolveExpr(expr.thenBranch);
    _resolveExpr(expr.elseBranch);
    return null;
  }

  @override
  void visitExpressionStmt(pkg_stmt.Expression stmt) {
    _resolveExpr(stmt.expression);
  }

  @override
  Object? visitGroupingExpr(pkg_expr.Grouping expr) {
    _resolveExpr(expr.expression);
    return null;
  }

  @override
  void visitIfStmt(pkg_stmt.If stmt) {
    _resolveExpr(stmt.conditional);
    _resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) {
      _resolveStmt(stmt.elseBranch!);
    }
  }

  @override
  void visitLFunctionStmt(pkg_stmt.LFunction stmt) {
    _declare(stmt.name);
    _define(stmt.name);
    _resolveFunction(stmt.lambda, FunctionType.function);
  }

  void _resolveFunction(Lambda lambda, FunctionType type) {
    final enclosingFunctionType = currentFunctionType;
    currentFunctionType = type;

    _beginScope();
    if (lambda.params != null) {
      for (Token param in lambda.params!) {
        _declare(param);
        _define(param);
      }
    }

    _resolveStatements(lambda.body);
    _endScope();

    currentFunctionType = enclosingFunctionType;
  }

  @override
  Object? visitLambdaExpr(pkg_expr.Lambda expr) {
    _resolveFunction(expr, FunctionType.function);
    return null;
  }

  @override
  Object? visitLiteralExpr(pkg_expr.Literal expr) {
    return null;
  }

  @override
  Object? visitLogicalExpr(pkg_expr.Logical expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
    return null;
  }

  @override
  void visitPrintStmt(pkg_stmt.Print stmt) {
    _resolveExpr(stmt.expression);
  }

  @override
  void visitReturnStmt(pkg_stmt.Return stmt) {
    if (currentFunctionType == FunctionType.none) {
      DLox.errorAt(stmt.token, "Can't return from top-level code.");
    }
    if (stmt.value != null) {
      if (currentFunctionType == FunctionType.initializer) {
        DLox.errorAt(stmt.token, "Can't return a value from initializer");
      }
      _resolveExpr(stmt.value!);
    }
  }

  @override
  Object? visitUnaryExpr(pkg_expr.Unary expr) {
    _resolveExpr(expr.right);
    return null;
  }

  @override
  void visitVarStmt(pkg_stmt.Var stmt) {
    _declare(stmt.name);
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer!);
    }
    _define(stmt.name);
  }

  @override
  Object? visitVariableExpr(pkg_expr.Variable expr) {
    if (scopes.isNotEmpty &&
        scopes.peek[expr.name.lexeme]?.type == VariableUsageType.declared) {
      DLox.errorAt(
          expr.name, "Can't read local variable in its own initializer.");
    }

    _resolveLocal(expr, expr.name, true);
    return null;
  }

  void _resolveLocal(Expr expr, Token name, bool isUsed) {
    for (int i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name.lexeme)) {
        interpreter.resolve(
            expr, scopes.length - 1 - i, scopes[i][name.lexeme]!.slot);
        if (isUsed) {
          scopes[i][name.lexeme]!.type = VariableUsageType.used;
        }
        return;
      }
    }
  }

  @override
  void visitWhileStmt(pkg_stmt.While stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.body);
  }

  @override
  void visitClassStmt(pkg_stmt.Class stmt) {
    final enclosingClassType = currentClass;
    currentClass = ClassType.klass;

    _declare(stmt.name);
    _define(stmt.name);

    if (stmt.superclass != null &&
        stmt.name.lexeme == stmt.superclass!.name.lexeme) {
      DLox.errorAt(stmt.superclass!.name, "A class cannot inherit from itself");
    }

    if (stmt.superclass != null) {
      currentClass = ClassType.subclass;
      _resolveExpr(stmt.superclass!);
    }

    if (stmt.superclass != null) {
      _beginScope();
      scopes.peek['super'] = VariableUsage(
        scopes.peek.length,
        VariableUsageType.declared,
        stmt.superclass!.name,
        synthetic: true,
      );
    }

    for (final trait in stmt.traits) {
      _resolveExpr(trait);
    }

    _beginScope();
    scopes.peek["this"] = VariableUsage(
      scopes.peek.length,
      VariableUsageType.declared,
      stmt.name,
      synthetic: true,
    );

    for (final method in stmt.methods) {
      FunctionType declaration = FunctionType.method;
      if (method.name.lexeme == "init") {
        declaration = FunctionType.initializer;
      }
      _resolveFunction(method.lambda, declaration);
    }

    for (final method in stmt.staticMethods) {
      _resolveFunction(method.lambda, FunctionType.function);
    }

    _endScope();

    if (stmt.superclass != null) {
      _endScope();
    }

    currentClass = enclosingClassType;
  }

  @override
  Object? visitGetExpr(pkg_expr.Get expr) {
    _resolveExpr(expr.object);
    return null;
  }

  @override
  Object? visitLSetExpr(pkg_expr.LSet expr) {
    _resolveExpr(expr.object);
    _resolveExpr(expr.value);
    return null;
  }

  @override
  Object? visitThisExpr(pkg_expr.This expr) {
    if (currentClass != ClassType.klass &&
        currentClass != ClassType.subclass &&
        currentClass != ClassType.trait &&
        currentFunctionType != FunctionType.none) {
      DLox.errorAt(expr.keyword,
          "'this' keyword can only be used inside a class method");
    }
    _resolveLocal(expr, expr.keyword, true);
    return null;
  }

  @override
  Object? visitSuperExpr(pkg_expr.Super expr) {
    if (currentClass == ClassType.none) {
      DLox.errorAt(expr.keyword, "Can't use 'super' outside of a class.");
    } else if (currentClass != ClassType.subclass) {
      DLox.errorAt(
          expr.keyword, "Can't use 'super' in a class with no superclass.");
    } else if (currentClass == ClassType.trait) {
      DLox.errorAt(expr.keyword, "Can't use 'super' in a trait");
    }

    _resolveLocal(expr, expr.keyword, false);
    return null;
  }

  @override
  void visitTraitStmt(pkg_stmt.Trait stmt) {
    final enclosingClassType = currentClass;
    currentClass = ClassType.trait;

    _declare(stmt.name);
    _define(stmt.name);

    for (final trait in stmt.traits) {
      _resolveExpr(trait);
    }

    _beginScope();
    scopes.peek["this"] = VariableUsage(
      scopes.peek.length,
      VariableUsageType.declared,
      stmt.name,
      synthetic: true,
    );

    for (final method in stmt.methods) {
      FunctionType declaration = FunctionType.method;
      _resolveFunction(method.lambda, declaration);
    }

    _endScope();

    currentClass = enclosingClassType;
  }

  @override
  Object? visitJListExpr(pkg_expr.JList expr) {
    return null;
  }

  @override
  Object? visitListAccessExpr(pkg_expr.ListAccess expr) {
    _resolveExpr(expr.list);
    _resolveExpr(expr.index);
    return null;
  }

  @override
  Object? visitListSetExpr(pkg_expr.ListSet expr) {
    _resolveExpr(expr.list);
    _resolveExpr(expr.index);
    return null;
  }
}

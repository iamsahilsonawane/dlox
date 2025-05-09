import 'package:dlox/ast/expr.g.dart' as pkg_expr;
import 'package:dlox/ast/stmt.g.dart' as pkg_stmt;
import 'package:dlox/dlox.dart';
import 'package:dlox/environment.dart';
import 'package:dlox/interpreter/errors/runtime_error.dart';
import 'package:dlox/interpreter/foreign_functions/clock.dart';
import 'package:dlox/interpreter/lox_function.dart';
import 'package:dlox/scanner/token_type.dart';

import 'lox_callable.dart';

class BreakException extends RuntimeError {
  BreakException() : super.empty();
}

class ReturnException extends RuntimeError {
  ReturnException(this.value) : super.empty();
  final Object? value;
}

// Post-order traversal of expressions (syntax tree) to evalute value
class Interpreter with pkg_expr.Visitor<Object?>, pkg_stmt.Visitor<void> {
  final Environment global = Environment.root();
  late Environment _environment = global;

  void interpret(List<pkg_stmt.Stmt> statements) {
    _environment.define("clock", ClockFF());
    try {
      for (final statement in statements) {
        _execute(statement);
      }
    } on RuntimeError catch (e) {
      DLox.runtimeError(e);
    }
  }

  String _stringify(Object? object) {
    if (object == null) return "nil";
    if (object is num) {
      String text = object.toString();
      if (text.endsWith(".0")) {
        text = text.substring(0, text.length - 2);
      }
      return text;
    }

    return object.toString();
  }

  void _execute(pkg_stmt.Stmt statement) {
    statement.accept(this);
  }

  Object? _evaluate(Expr expr) {
    return expr.accept(this);
  }

  bool _isTruthy(Object? object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool _isEqual(Object? a, Object? b) {
    return a == b;
  }

  @override
  Object? visitCallExpr(pkg_expr.Call expr) {
    Object? callee = _evaluate(expr.callee);
    if (callee is! LoxCallable) {
      throw RuntimeError(expr.paren, "Can only call methods or classes.");
    }

    List<Object> arguments = [];
    for (Expr arg in expr.arguments) {
      arguments.add(_evaluate(arg)!);
    }

    LoxCallable function = callee;

    if (arguments.length != function.arity()) {
      throw RuntimeError(expr.paren,
          "Expected ${function.arity()} arguments but got ${arguments.length}.");
    }
    return function.call(this, arguments);
  }

  @override
  void visitBreakStmt(pkg_stmt.Break stmt) {
    throw BreakException();
  }

  @override
  void visitWhileStmt(pkg_stmt.While stmt) {
    try {
      while (_isTruthy(_evaluate(stmt.condition))) {
        _execute(stmt.body);
      }
    } on BreakException catch (_) {}
  }

  @override
  Object? visitLogicalExpr(pkg_expr.Logical expr) {
    Object? left = _evaluate(expr.left);

    if (expr.operator.type == TokenType.OR) {
      if (_isTruthy(left)) return left;
    } else {
      if (!_isTruthy(left)) return left;
    }

    return _evaluate(expr.right);
  }

  @override
  void visitIfStmt(pkg_stmt.If stmt) {
    final result = _evaluate(stmt.conditional);
    if (_isTruthy(result)) {
      _execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      _execute(stmt.elseBranch!);
    }
  }

  @override
  Object? visitBlockStmt(pkg_stmt.Block stmt) {
    executeBlock(stmt.statements, Environment(_environment));
    return null;
  }

  void executeBlock(List<pkg_stmt.Stmt> statements, Environment environment) {
    final previous = _environment;

    try {
      _environment = environment;
      for (final statement in statements) {
        _execute(statement);
      }
    } finally {
      _environment = previous;
    }
  }

  @override
  Object? visitAssignExpr(pkg_expr.Assign expr) {
    Object? value = expr.value.accept(this);
    _environment.assign(expr.name, value);
    return value;
  }

  @override
  void visitExpressionStmt(pkg_stmt.Expression stmt) {
    final result = _evaluate(stmt.expression);
    if (DLox.isREPL) {
      print(_stringify(result));
    }
  }

  @override
  void visitPrintStmt(pkg_stmt.Print stmt) {
    final result = _evaluate(stmt.expression);
    print(_stringify(result));
  }

  @override
  void visitVarStmt(pkg_stmt.Var stmt) {
    Object? value = UninitialisedVar();
    if (stmt.initializer != null) {
      final result = stmt.initializer!.accept(this);
      value = result;
    }
    _environment.define(stmt.name.lexeme, value);
  }

  @override
  Object? visitVariableExpr(pkg_expr.Variable expr) {
    return _environment.get(expr.name);
  }

  @override
  Object? visitBinaryExpr(Binary expr) {
    Object? left = _evaluate(expr.left);
    Object? right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.PLUS:
        if (left is num && right is double) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        if ((left is String && right is double) ||
            (left is double && right is String)) {
          return "${_stringify(left)}${_stringify(right)}";
        }
        throw RuntimeError(
            expr.operator, "Operands must be two numbers or two strings.");
      case TokenType.MINUS:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) - (right as num);
      case TokenType.STAR:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) * (right as num);
      case TokenType.SLASH:
        _checkNumberOperands(expr.operator, left, right);
        if (right == 0) {
          throw RuntimeError(expr.operator, "Division by zero is not allowed");
        }
        return (left as num) / (right as num);
      case TokenType.GREATER:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) > (right as num);
      case TokenType.GREATER_EQUAL:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) >= (right as num);
      case TokenType.LESS:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) < (right as num);
      case TokenType.LESS_EQUAL:
        _checkNumberOperands(expr.operator, left, right);
        return (left as num) <= (right as num);
      case TokenType.BANG_EQUAL:
        return !_isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        return _isEqual(left, right);
      default:
    }

    //unreachable
    return null;
  }

  @override
  Object? visitConditionalExpr(Conditional expr) {
    if (expr.expr.accept(this) as bool) {
      return expr.thenBranch.accept(this);
    } else {
      return expr.elseBranch.accept(this);
    }
  }

  @override
  Object? visitGroupingExpr(Grouping expr) {
    return _evaluate(expr.expression);
  }

  @override
  Object? visitLiteralExpr(Literal expr) {
    return expr.value;
  }

  @override
  Object? visitUnaryExpr(Unary expr) {
    Object? right = _evaluate(expr.right);
    switch (expr.operator.type) {
      case TokenType.BANG:
        return !_isTruthy(right);
      case TokenType.MINUS:
        _checkNumberOperand(expr.operator, right);
        return -(right as num).toDouble(); //we only have double type in dlox
      default:
    }
    //unreachable
    return Null;
  }

  void _checkNumberOperand(Token operator, Object? operand) {
    if (operand is num) return;
    throw RuntimeError(operator, "Operand must be number");
  }

  void _checkNumberOperands(Token operator, Object? left, Object? right) {
    if (left is num && right is num) return;
    throw RuntimeError(operator, "Operands must be numbers");
  }

  @override
  void visitLFunctionStmt(pkg_stmt.LFunction stmt) {
    LoxCallable function = LoxFunction(stmt, _environment);
    _environment.define(stmt.name.lexeme, function);
  }

  @override
  void visitReturnStmt(pkg_stmt.Return stmt) {
    Object? value;
    if (stmt.value != null) {
      value = _evaluate(stmt.value!);
    }

    throw ReturnException(value);
  }
}

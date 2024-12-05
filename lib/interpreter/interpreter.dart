import 'package:dlox/ast/expr.g.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/interpreter/errors/runtime_error.dart';
import 'package:dlox/scanner/token_type.dart';

// Post-order traversal of expressions (syntax tree) to evalute value
class Interpreter extends Visitor<Object?> {
  void interpret(Expr expression) {
    try {
      Object? value = _evaluate(expression);
      print(_stringify(value));
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
    // TODO: implement visitConditionalExpr
    throw UnimplementedError();
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
}

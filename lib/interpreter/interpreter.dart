import 'package:dlox/ast/expr.g.dart' as pkg_expr;
import 'package:dlox/ast/stmt.g.dart' as pkg_stmt;
import 'package:dlox/dlox.dart';
import 'package:dlox/environment.dart';
import 'package:dlox/interpreter/errors/runtime_error.dart';
import 'package:dlox/interpreter/foreign_functions/clock.dart';
import 'package:dlox/interpreter/lox_class.dart';
import 'package:dlox/interpreter/lox_function.dart';
import 'package:dlox/interpreter/lox_trait.dart';
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
  Environment? _environment;
  final Map<Expr, int> _locals = {};
  final Map<String, Object?> globals = {};
  final Map<Expr, int> slots = {};

  void interpret(List<pkg_stmt.Stmt> statements) {
    globals["clock"] = ClockFF();
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

  void resolve(Expr expr, int depth, int slot) {
    _locals[expr] = depth;
    slots[expr] = slot;
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
    Object? value = _evaluate(expr.value);

    final distance = _locals[expr];
    if (distance != null) {
      _environment!.assignAt(distance, slots[expr]!, value);
    } else if (globals.containsKey(expr.name.lexeme)) {
      globals[expr.name.lexeme] = value;
    } else {
      throw RuntimeError(
          expr.name, "Undefined variable '${expr.name.lexeme}'.");
    }

    return value;
  }

  Object? lookupVariable(Token name, Expr expr) {
    final distance = _locals[expr];
    if (distance != null) {
      return _environment!.getAt(distance, slots[expr]!);
    } else if (globals.containsKey(name.lexeme)) {
      return globals[name.lexeme];
    } else {
      throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
    }
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
    define(stmt.name, value);
  }

  void define(Token name, Object? value) {
    if (_environment != null) {
      _environment!.define(value);
    } else {
      globals[name.lexeme] = value;
    }
  }

  @override
  Object? visitVariableExpr(pkg_expr.Variable expr) {
    return lookupVariable(expr.name, expr);
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
    define(stmt.name, function);
  }

  @override
  void visitReturnStmt(pkg_stmt.Return stmt) {
    Object? value;
    if (stmt.value != null) {
      value = _evaluate(stmt.value!);
    }

    throw ReturnException(value);
  }

  @override
  Object? visitLambdaExpr(pkg_expr.Lambda expr) {
    return LoxLamda(
        pkg_expr.Lambda(body: expr.body, params: expr.params), _environment);
  }

  @override
  void visitClassStmt(pkg_stmt.Class stmt) {
    LoxClass? superclass;
    if (stmt.superclass != null) {
      final result = _evaluate(stmt.superclass!);
      if (result is! LoxClass) {
        throw RuntimeError(stmt.superclass!.name, "Superclass must be a class");
      }
      superclass = result;
    }

    if (stmt.superclass != null) {
      _environment = Environment(_environment);
      _environment!.define(superclass);
    }

    final Map<String, LoxFunction> methods = applyTraits(stmt.traits);
    final Map<String, LoxFunction> staticMethods = {};

    for (final method in stmt.methods) {
      methods[method.name.lexeme] = LoxFunction(method, _environment,
          isInitializer: method.name.lexeme == "init");
    }

    for (final method in stmt.staticMethods) {
      staticMethods[method.name.lexeme] = LoxFunction(method, _environment);
    }

    LoxClass metaclass =
        LoxClass("${stmt.name.lexeme} metaclass", staticMethods, null, null);
    LoxClass klass = LoxClass(stmt.name.lexeme, methods, superclass, metaclass);

    if (superclass != null) {
      _environment = _environment!.enclosing;
    }

    define(stmt.name, klass);
  }

  @override
  Object? visitGetExpr(pkg_expr.Get expr) {
    Object? object = _evaluate(expr.object);
    if (object is LoxInstance) {
      final result = object.get(expr.name);
      if (result is LoxFunction && result.isGetter) {
        return result.call(this, []);
      }
      return result;
    } else if (object is LoxList) {
      final callable = object.getCallable(expr.name.lexeme);
      if (callable == null) {
        throw RuntimeError(
            expr.name, "There's no method '${expr.name.lexeme}' on list");
      }
      return callable;
    }

    throw RuntimeError(expr.name, "Only instances have properties");
  }

  @override
  Object? visitLSetExpr(pkg_expr.LSet expr) {
    final caller = _evaluate(expr.object);
    if (caller is! LoxInstance) {
      throw RuntimeError(expr.name, "Only instances have properties");
    }

    final value = _evaluate(expr.value);
    caller.set(expr.name, value!);
    return value;
  }

  @override
  Object? visitThisExpr(pkg_expr.This expr) {
    return lookupVariable(expr.keyword, expr);
  }

  @override
  Object? visitSuperExpr(pkg_expr.Super expr) {
    final LoxClass superclass = lookupVariable(expr.keyword, expr) as LoxClass;
    final int? distance = _locals[expr];
    final LoxInstance object = _environment!.getAt(distance! - 1, 0)
        as LoxInstance; //this is the first one in the slot always
    final LoxFunction? method = superclass.getMethod(expr.method.lexeme);
    if (method == null) {
      throw RuntimeError(
          expr.method, "Undefined property '${expr.method.lexeme}'.");
    }
    return method.bind(object);
  }

  @override
  void visitTraitStmt(pkg_stmt.Trait stmt) {
    final Map<String, LoxFunction> methods = applyTraits(stmt.traits);
    for (final method in stmt.methods) {
      if (methods.containsKey(method.name.lexeme)) {
        throw RuntimeError(method.name,
            "A previous trait declares a method named '${method.name.lexeme}'.");
      }
      methods[method.name.lexeme] = LoxFunction(method, _environment);
    }

    LoxTrait trait = LoxTrait(stmt.name, methods);
    define(stmt.name, trait);
  }

  Map<String, LoxFunction> applyTraits(List<Expr> traits) {
    Map<String, LoxFunction> methods = {};

    for (Expr traitExpr in traits) {
      Object? traitObject = _evaluate(traitExpr);
      if (traitObject is! LoxTrait) {
        Token name = (traitExpr as pkg_expr.Variable).name;
        throw RuntimeError(name, "'${name.lexeme}' is not a trait.");
      }

      LoxTrait trait = traitObject;
      for (String name in trait.methods.keys) {
        if (methods.containsKey(name)) {
          throw RuntimeError(
              trait.name, "A previous trait declares a method named '$name'.");
        }
        methods[name] = trait.methods[name]!;
      }
    }

    return methods;
  }

  @override
  Object? visitJListExpr(pkg_expr.JList expr) {
    return LoxList(
      startToken: expr.startBracket,
      list: expr.list.map((e) => _evaluate(e)).toList(),
    );
  }

  @override
  Object? visitListAccessExpr(pkg_expr.ListAccess expr) {
    final list = _evaluate(expr.list);
    if (list is! LoxList) {
      throw RuntimeError(expr.bracket,
          "Cannot call list access operator on a non-list object");
    }
    try {
      final index = _evaluate(expr.index);
      if (index is! num) {
        throw RuntimeError(expr.bracket, "Non-null value passed to index");
      }
      return list.list[index.toInt()];
    } on RangeError catch (_) {
      throw RuntimeError(expr.bracket,
          "Array index out of range. Tried to access ${expr.index} for a list of length ${list.list.length}");
    }
  }

  @override
  Object? visitListSetExpr(pkg_expr.ListSet expr) {
    final list = _evaluate(expr.list);
    if (list is! LoxList) {
      throw RuntimeError(expr.bracket,
          "Cannot call list access operator on a non-list object");
    }
    try {
      final index = _evaluate(expr.index);
      if (index is! num) {
        throw RuntimeError(expr.bracket, "Non-null value passed to index");
      }
      return list.list[index.toInt()] = _evaluate(expr.value);
    } on RangeError catch (_) {
      throw RuntimeError(expr.bracket,
          "Array index out of range. Tried to access ${expr.index} for a list of length ${list.list.length}");
    }
  }
}

class LoxList {
  final List<dynamic> list;
  final Token startToken;

  LoxList({required this.startToken, required this.list}) {
    registerMethods();
  }

  Map<String, LoxCallable> methods = {};

  void registerMethods() {
    methods["set"] = _LoxListSet(this);
    methods["len"] = _LoxListLen(this);
    methods["push"] = _LoxListPush(this);
    methods["pop"] = _LoxListPop(this);
  }

  LoxCallable? getCallable(String name) {
    return methods[name];
  }

  @override
  String toString() {
    return "[${list.map((e) => e.toString()).join(", ")}]";
  }
}

class _LoxListSet extends LoxCallable {
  final LoxList loxList;

  _LoxListSet(this.loxList);

  @override
  int arity() {
    return 2;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    final startToken = loxList.startToken;
    final list = loxList.list;

    if (arguments[0] is! double) {
      //dlox only has double values for num
      //TODO(sahil): is this the right place to do this? can't we do this in resolver?
      throw RuntimeError(
          startToken, "Expected integer for index (as first parameter)");
    }

    final index = (arguments[0] as double).toInt();
    final value = arguments[1];

    try {
      list[index] = value;
    } on RangeError catch (_) {
      throw RuntimeError(startToken,
          "Array index out of range. Tried to access ${arguments[0]} for a list of length ${list.length}");
    }
    return null;
  }
}

class _LoxListLen extends LoxCallable {
  final LoxList loxList;

  _LoxListLen(this.loxList);

  @override
  int arity() {
    return 0;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    return loxList.list.length;
  }
}

class _LoxListPush extends LoxCallable {
  final LoxList loxList;

  _LoxListPush(this.loxList);

  @override
  int arity() {
    return 1;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    loxList.list.add(arguments[0]);
    return null;
  }
}


class _LoxListPop extends LoxCallable {
  final LoxList loxList;

  _LoxListPop(this.loxList);

  @override
  int arity() {
    return 0;
  }

  @override
  Object? call(Interpreter interpreter, List<Object> arguments) {
    return loxList.list.removeLast();
  }
}

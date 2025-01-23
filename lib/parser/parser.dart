import 'package:dlox/ast/expr.g.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/parser/parse_error.dart';
import 'package:dlox/scanner/token_type.dart';

import '../ast/stmt.g.dart';

class Parser {
  final List<Token> tokens;
  int current = 0;

  Parser({required this.tokens});

  List<Stmt> parse() {
    final statements = <Stmt>[];
    while (!isAtEnd()) {
      final stmt = declaration();
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    return statements;
  }

  Stmt? declaration() {
    try {
      if (match([TokenType.VAR])) {
        return variableDeclaration();
      }
      return statement();
    } catch (e) {
      synchronize();
      return null;
    }
  }

  Stmt variableDeclaration() {
    final name = consume(TokenType.IDENTIFIER, "Expected an identifier");
    Expr? expr;
    if (match([TokenType.EQUAL])) {
      expr = expression();
    }
    consume(TokenType.SEMICOLON, "Expected a ; after a variable declaration");
    return Var(name: name, initializer: expr);
  }

  Stmt statement() {
    if (match([TokenType.PRINT])) {
      return printStatement();
    }

    return expressionStatement();
  }

  Stmt printStatement() {
    Expr expr = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after value");
    return Print(expression: expr);
  }

  Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after the expression");
    return Expression(expression: expr);
  }

  Expr expression() {
    return comma();
  }

  //TODO: this can be an issue for function arguments, right now there's no implementation for function argument. Keeping for later
  //https://github.com/munificent/craftinginterpreters/blob/master/note/answers/chapter06_parsing.md
  Expr comma() {
    Expr expr = conditional();
    while (match([TokenType.COMMA])) {
      Token operator = previous();
      Expr right = comparison();
      expr = Binary(left: expr, operator: operator, right: right);
    }
    return expr;
  }

  Expr conditional() {
    Expr expr = comparison();
    if (match([TokenType.QUESTION])) {
      Expr thenBranch = expression();
      consume(TokenType.COLON,
          "Expect : after then branch of conditional expression.");
      Expr elseBranch = expression();
      return Conditional(
          expr: expr, thenBranch: thenBranch, elseBranch: elseBranch);
    }
    return expr;
  }

  Expr equality() {
    Expr expr = comparison();

    while (match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = previous();
      Expr right = comparison();
      expr = Binary(left: expr, operator: operator, right: right);
    }
    return expr;
  }

  Expr comparison() {
    Expr expr = term();

    while (match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      Token operator = previous();
      Expr right = term();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr term() {
    Expr expr = factor();

    while (match([
      TokenType.MINUS,
      TokenType.PLUS,
    ])) {
      Token operator = previous();
      Expr right = factor();
      expr = Binary(left: expr, operator: operator, right: right);
    }
    return expr;
  }

  Expr factor() {
    Expr expr = unary();

    while (match([
      TokenType.STAR,
      TokenType.SLASH,
    ])) {
      Token operator = previous();
      Expr right = unary();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr unary() {
    while (match([
      TokenType.BANG,
      TokenType.MINUS,
    ])) {
      Token operator = previous();
      Expr right = unary();
      return Unary(operator: operator, right: right);
    }

    return primary();
  }

  Expr primary() {
    if (match([TokenType.FALSE])) return Literal(value: false);
    if (match([TokenType.TRUE])) return Literal(value: true);
    if (match([TokenType.NIL])) return Literal(value: null);

    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(value: previous().literal);
    }

    if (match([TokenType.LEFT_PAREN])) {
      Expr expr = expression();

      consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expression: expr);
    }

    if (match([TokenType.IDENTIFIER])) {
      return Variable(name: previous());
    }

    // Error productions.
    if (match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      error(previous(), "Missing left-hand operand.");
      return equality();
    }

    if (match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      error(previous(), "Missing left-hand operand.");
      return comparison();
    }

    if (match([TokenType.PLUS])) {
      error(previous(), "Missing left-hand operand.");
      return term();
    }

    if (match([TokenType.SLASH, TokenType.STAR])) {
      error(previous(), "Missing left-hand operand.");
      return factor();
    }

    throw error(peek(), "Expect expression.");
  }

  ParseError error(Token token, String message) {
    DLox.errorAt(token, message);
    return ParseError();
  }

  void synchronize() {
    advance();

    while (!isAtEnd()) {
      if (previous().type == TokenType.SEMICOLON) return;

      switch (peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default:
      }

      advance();
    }
  }

  bool match(List<TokenType> types) {
    for (TokenType type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }

    return false;
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();

    throw error(peek(), message);
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) current++;
    return previous();
  }

  bool isAtEnd() {
    return peek().type == TokenType.EOF;
  }

  Token peek() {
    return tokens[current];
  }

  Token previous() {
    return tokens[current - 1];
  }
}

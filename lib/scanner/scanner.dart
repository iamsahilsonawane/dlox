import 'package:dlox/dlox.dart';
import 'package:dlox/scanner/token.dart';
import 'package:dlox/scanner/token_type.dart';

class Scanner {
  final String source;
  final List<Token> tokens = [];

  int start = 0;
  int current = 0;
  int line = 1;

  Scanner(this.source);

  List<Token> scanTokens() {
    while (!isAtEnd()) {
      start = current;
      scanToken();
    }

    tokens.add(Token(TokenType.EOF, "", Null, line));
    return tokens;
  }

  void scanToken() {
    String c = advance();
    switch (c) {
      case "(":
        addTokenNoLiteral(TokenType.LEFT_PAREN);
        break;
      case ')':
        addTokenNoLiteral(TokenType.RIGHT_PAREN);
        break;
      case '{':
        addTokenNoLiteral(TokenType.LEFT_BRACE);
        break;
      case '}':
        addTokenNoLiteral(TokenType.RIGHT_BRACE);
        break;
      case ',':
        addTokenNoLiteral(TokenType.COMMA);
        break;
      case '.':
        addTokenNoLiteral(TokenType.DOT);
        break;
      case '-':
        addTokenNoLiteral(TokenType.MINUS);
        break;
      case '+':
        addTokenNoLiteral(TokenType.PLUS);
        break;
      case ';':
        addTokenNoLiteral(TokenType.SEMICOLON);
        break;
      case '*':
        addTokenNoLiteral(TokenType.STAR);
        break;
      case '/':
        if (match("/")) {
          while (peek() != "\n" && peek() != null && !isAtEnd()) {
            advance();
          }
        } else {
          addTokenNoLiteral(TokenType.SLASH);
        }
        break;
      case '!':
        addTokenNoLiteral(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        addTokenNoLiteral(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '<':
        addTokenNoLiteral(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '>':
        addTokenNoLiteral(
            match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;

      case '"':
        string();
        break;

      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;

      case '\n':
        line++;
        break;
      default:
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          identifier();
        } else {
          DLox.error(line, "Unexpected character.");
        }
        break;
    }
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }

    final value = source.substring(start, current);
    final type = _keywords[value] ?? TokenType.IDENTIFIER;
    addTokenNoLiteral(type);
  }

  bool isAlpha(String c) {
    int charCode = c.codeUnitAt(0);
    //a-z, A-Z, _
    return c.isNotEmpty &&
        ((charCode >= 65 && charCode <= 90) ||
            (charCode >= 97 && charCode <= 122) ||
            c == "_");
  }

  bool isAlphaNumeric(String? c) {
    if (c == null) return false;
    return isAlpha(c) || isDigit(c);
  }

  void string() {
    while (peek() != '"' && peek() != null && !isAtEnd()) {
      if (peek() == "\n") line++;
      advance();
    }
    if (isAtEnd()) {
      DLox.error(line, "Unterminated string");
    }

    //it's " baby
    advance();

    String value = source.substring(start + 1, current - 1);
    addToken(TokenType.STRING, value);
  }

  void number() {
    while (isDigit(peek())) {
      advance();
    }

    if (peek() == '.' && isDigit(peekNext())) {
      // Consume the "."
      advance();

      while (isDigit(peek())) {
        advance();
      }
    }

    addToken(TokenType.NUMBER, double.parse(source.substring(start, current)));
  }

  bool match(String expected) {
    if (isAtEnd()) return false;
    if (source[current] != expected) return false;

    current++;
    return true;
  }

  bool isDigit(String? c) {
    if (c == null) return false;
    int charCode = c.codeUnitAt(0);
    return charCode >= 48 && charCode <= 57;
  }

  //lookahead by 1 char
  String? peek() {
    if (isAtEnd()) return null;
    return source[current];
  }

  //lookahead by 2 char
  String? peekNext() {
    if (1 + current >= source.length) return null;
    return source[current + 1];
  }

  String advance() {
    return source[current++];
  }

  void addTokenNoLiteral(TokenType tokenType) {
    addToken(tokenType, Null);
  }

  void addToken(TokenType tokenType, Object literal) {
    String text = source.substring(start, current);
    tokens.add(Token(tokenType, text, literal, line));
  }

  bool isAtEnd() {
    return current >= source.length;
  }

  static const Map<String, TokenType> _keywords = {
    "and": TokenType.AND,
    "class": TokenType.CLASS,
    "else": TokenType.ELSE,
    "false": TokenType.FALSE,
    "for": TokenType.FOR,
    "fun": TokenType.FUN,
    "if": TokenType.IF,
    "nil": TokenType.NIL,
    "or": TokenType.OR,
    "print": TokenType.PRINT,
    "return": TokenType.RETURN,
    "super": TokenType.SUPER,
    "this": TokenType.THIS,
    "true": TokenType.TRUE,
    "var": TokenType.VAR,
    "while": TokenType.WHILE,
  };
}

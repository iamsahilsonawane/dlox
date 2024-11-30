import 'dart:core';
import 'package:dlox/scanner/token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final Object literal;
  final int line;

  const Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() {
    return "type: $type | lex: $lexeme | literal: $literal";
  }
}

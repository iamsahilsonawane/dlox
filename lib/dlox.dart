import 'dart:convert';
import 'dart:io';

import 'package:dlox/ast/ast_printer.dart';
import 'package:dlox/ast/expr.g.dart';
import 'package:dlox/interpreter/errors/runtime_error.dart';
import 'package:dlox/interpreter/interpreter.dart';
import 'package:dlox/parser/parser.dart';
import 'package:dlox/scanner/scanner.dart';
import 'package:dlox/scanner/token.dart';
import 'package:dlox/scanner/token_type.dart';

import 'ast/stmt.g.dart';

export 'package:dlox/scanner/token.dart';
export 'package:dlox/ast/expr.g.dart';

class DLox {
  static bool hadError = false;
  static bool hadRuntimeError = false;

  static final interpreter = Interpreter();

  Future<void> runFile(String path) async {
    final source = await File(path).readAsString(encoding: utf8);
    await run(source);
    if (hadError) exitCode = 65;
    if (hadRuntimeError) exitCode = 70;
  }

  Future<void> runPrompt() async {
    Stream codeListener =
        stdin.transform(Utf8Decoder()).transform(LineSplitter());

    await for (final code in codeListener) {
      await run(code);
      hadError = false;
    }
  }

  Future<void> run(String source) async {
    Scanner scanner = Scanner(source);
    List<Token> tokens = scanner.scanTokens();

    Parser parser = Parser(tokens: tokens);
    List<Stmt> statements = parser.parse();

    // Stop if there was a syntax error.
    if (hadError) return;

    // print(AstPrinter().print(expression!));
    interpreter.interpret(statements);
  }

  static void error(int line, String message) {
    report(line, "", message);
  }

  static void runtimeError(RuntimeError error) {
    print("[line ${error.token.line}] ${error.message}");
    hadRuntimeError = true;
  }

  static report(int line, String where, String message) {
    stderr.writeln("[line $line] Error $where: $message");
    hadError = true;
  }

  static void errorAt(Token token, String message) {
    if (token.type == TokenType.EOF) {
      report(token.line, "at end", message);
    } else {
      report(token.line, "at '${token.lexeme}'", message);
    }
  }
}

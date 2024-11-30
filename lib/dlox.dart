import 'dart:convert';
import 'dart:io';

import 'package:dlox/scanner/scanner.dart';
import 'package:dlox/scanner/token.dart';

class DLox {
  static bool hadError = false;

  Future<void> runFile(String path) async {
    final source = await File(path).readAsString(encoding: utf8);
    await run(source);
    if (hadError) exitCode = 65;
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

    for (Token token in tokens) {
      print(token);
    }
  }

  static void error(int line, String message) {
    report(line, "", message);
  }

  static report(int line, String where, String message) {
    stderr.writeln("[line $line] Error $where: $message");
    hadError = true;
  }
}

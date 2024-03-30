// import 'package:dlox/dlox.dart' as dlox;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

const lineNumber = 'line-number';

void main(List<String> arguments) {
  exitCode = 0;
  final parser =
      ArgParser(); //..addFlag(lineNumber, negatable: false, abbr: 'n');

  ArgResults argResults = parser.parse(arguments);
  final paths = argResults.rest;
  print("what rest do we got? ${paths.length}");

  if (paths.isEmpty) {
    runPrompt();
  } else {
    runFile(paths[0]);
  }
}

Future<void> runFile(String path) async {
  final source = await File(path).readAsString(encoding: utf8);
  run(source);
}

Future<void> runPrompt() async {
  Stream codeListener =
      stdin.transform(Utf8Decoder()).transform(LineSplitter());

  await for (final code in codeListener) {
    print("interactive: code typed: $code");
  }
}

Future<void> run(String source) async {
  Scanner scanner = Scanner(source);
  List<Token> tokens = scanner.scanTokens();

  for (Token token in tokens) {
    print(token);
  }
}

class Scanner {
  final String source;
  Scanner(this.source);

 List<Token> scanTokens() {}
}

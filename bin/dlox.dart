import 'dart:io';

import 'package:args/args.dart';
import 'package:dlox/dlox.dart';

const filePath = 'file-path';

Future<void> main(List<String> arguments) async {
  exitCode = 0;
  DLox dlox = DLox();

  final parser = ArgParser()..addFlag(filePath, negatable: true, abbr: 'f');

  ArgResults argResults = parser.parse(arguments);
  final paths = argResults.rest;

  if (paths.isEmpty) {
    await dlox.runPrompt();
  } else {
    await dlox.runFile(paths[0]);
  }
}

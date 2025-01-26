import 'package:dlox/scanner/token.dart';

class RuntimeError extends Error {
  final Token? token;
  final String? message;

  //force non-null prop
  RuntimeError(Token this.token, String this.message); 

  ///Should only be used for subtypes of RuntimeError.
  ///Should not be called to throw a runtime error
  RuntimeError.empty() : token = null, message = null;
}

import 'dart:io';

import 'package:dlox/dlox.dart';

void main(List<String> args) {
  if (args.length != 1) {
    print("Usage: dart run tool/generate_ast <output directory>");
  }

  String outputDir = args[0];

  defineAst(outputDir, "Expr", [
    "Binary   : Expr left, Token operator, Expr right",
    "Grouping : Expr expression",
    "Literal  : Object? value",
    "Unary    : Token operator, Expr right"
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  String path = "$outputDir/${baseName.toLowerCase()}.g.dart";
  final file = File(path);

  StringBuffer buf = StringBuffer();

  buf.writeln("import \"package:dlox/dlox.dart\";\n");
  buf.writeln("abstract class $baseName {");
  buf.writeln("  R accept<R>(Visitor<R> visitor);");
  buf.writeln("}\n");

  defineVisitor(buf, baseName, types);

  // The AST classes.
  for (String type in types) {
    String className = type.split(":")[0].trim();
    String fields = type.split(":")[1].trim();
    defineType(buf, baseName, className, fields);
  }

  file.writeAsStringSync(buf.toString());
}

void defineVisitor(StringBuffer buffer, String baseName, List<String> types) {
  buffer.writeln("abstract class Visitor<R> {");

  for (String type in types) {
    String typeName = type.split(":")[0].trim();
    buffer.writeln(
        "  R visit$typeName$baseName($typeName ${baseName.toLowerCase()});");
  }

  buffer.writeln("}\n");
}

void defineType(
    StringBuffer buffer, String baseName, String className, String fieldList) {
  buffer.writeln("class $className extends $baseName {");

  final fields = fieldList.split(", ");

  // Constructor.
  buffer.writeln("  $className({");
  for (String field in fields) {
    String name = field.split(" ")[1];
    buffer.writeln("    required this.$name,");
  }
  buffer.writeln("  });");
  buffer.writeln();

  // Visitor pattern.
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  R accept<R>(Visitor<R> visitor) {");
  buffer.writeln("    return visitor.visit$className$baseName(this);");
  buffer.writeln("  }");
  buffer.writeln();

  // Store parameters in fields.
  for (String field in fields) {
    String type = field.split(" ")[0];
    String name = field.split(" ")[1];
    buffer.writeln("  final $type $name;");
  }

  buffer.writeln("}\n");
}

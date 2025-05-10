import 'package:dlox/dlox.dart';
import 'package:test/test.dart';

void main() {
  group("static analysis - resolver", () {
    test("unused var", () async {
      DLox dlox = DLox();
      await dlox.runFile("./examples/unused_var.dlox");
      expect(DLox.hadError, true);
    });
  });
}

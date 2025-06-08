class UninitialisedVar {}

class Environment {
  final Environment? enclosing;

  Environment(this.enclosing);
  Environment.root() : enclosing = null;

  final values = <Object?>[];

  Object? getAt(int distance, int slot) {
    return ancestor(distance).values[slot];
  }

  Environment ancestor(int distance) {
    Environment targetEnv = this;
    for (var i = 0; i < distance; i++) {
      targetEnv = targetEnv.enclosing!;
    }
    return targetEnv;
  }

  void define(Object? value) {
    values.add(value);
  }

  void assignAt(int distance, int slot, Object? value) {
    ancestor(distance).values[slot] = value;
  }
}

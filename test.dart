int fib(int n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}

void main() {
  var before = DateTime.now().millisecondsSinceEpoch;
  print(fib(30));
  var after = DateTime.now().millisecondsSinceEpoch;
  print(after - before);
}

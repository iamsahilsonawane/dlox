class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  int get length => _list.length;

  E operator [](index) {
    return _list[index];
  }

  @override
  String toString() => _list.toString();
}

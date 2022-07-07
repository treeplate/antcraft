Map<TD, List<T>> group<T, TD>(List<T> ts, TD Function(T t) test) {
  Map<TD, List<T>> result = {};
  for (T t in ts) {
    TD td = test(t);
    result[td] ??= [];
    result[td]!.add(t);
  }
  return result;
}

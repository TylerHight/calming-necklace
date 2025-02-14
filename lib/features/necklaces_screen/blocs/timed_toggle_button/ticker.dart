class Ticker {
  const Ticker();
  Stream<int> tick({required int ticks}) {
    return Stream.periodic( 
      const Duration(seconds: 1),
      (x) {
        final remaining = ticks - x - 1;
        if (remaining < 0) return 0;
        return remaining;
      },
    ).take(ticks + 1);
  }
}

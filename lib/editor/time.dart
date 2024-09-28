/// Целое, всегда положительное число, выражающее количество миллисекунд.
class Millis implements Comparable<Millis> {
  final int _ticks;
  int get ticks => _ticks;

  /// # Инварианты
  /// ```dart
  /// assert(this.ticks >= 0);
  /// ```
  Millis(this._ticks) {
    assert(ticks >= 0);
  }

  Millis.clamp(int value) : _ticks = value < 0 ? 0 : value;

  @override
  int compareTo(Millis other) {
    return ticks.compareTo(other.ticks);
  }

  bool operator <(Millis other) => ticks < other.ticks;
  bool operator >(Millis other) => ticks > other.ticks;
  bool operator <=(Millis other) => ticks <= other.ticks;
  bool operator >=(Millis other) => ticks >= other.ticks;
}

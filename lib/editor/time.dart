class Millis implements Comparable<Millis> {
  int ticks;

  /// # Инварианты
  /// ```dart
  /// assert(this.ticks >= 0);
  /// ```
  Millis(this.ticks) {
    assert(ticks >= 0);
  }

  @override
  int compareTo(Millis other) {
    return ticks.compareTo(other.ticks);
  }

  Millis operator +(Millis other) {
    const max = (1 << 64) - 1;

    if (max - ticks < other.ticks) {
      return Millis(max);
    } else {
      return Millis(ticks + other.ticks);
    }
  }

  Millis operator -(Millis other) {
    if (other.ticks > ticks) {
      return Millis(0);
    } else {
      return Millis(ticks - other.ticks);
    }
  }
}

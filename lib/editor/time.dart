class MillisFormatted {
  final int hour, minute, second, millisecond;

  MillisFormatted(Millis millis)
      : hour = millis.hours,
        minute = millis.minutes % 60,
        second = millis.seconds % 60,
        millisecond = millis.ticks % 1000;
}

/// Целое, всегда положительное число, выражающее количество миллисекунд.
class Millis implements Comparable<Millis> {
  final int ticks;

  int get seconds => ticks ~/ 1000;
  int get minutes => seconds ~/ 60;
  int get hours => minutes ~/ 60;

  /// # Инварианты
  /// ```dart
  /// assert(this.ticks >= 0);
  /// ```
  Millis(this.ticks) {
    assert(ticks >= 0);
  }

  Millis.clamp(int value) : ticks = value < 0 ? 0 : value;

  @override
  int compareTo(Millis other) {
    return ticks.compareTo(other.ticks);
  }

  MillisFormatted format() => MillisFormatted(this);

  bool operator <(Millis other) => ticks < other.ticks;
  bool operator >(Millis other) => ticks > other.ticks;
  bool operator <=(Millis other) => ticks <= other.ticks;
  bool operator >=(Millis other) => ticks >= other.ticks;
}

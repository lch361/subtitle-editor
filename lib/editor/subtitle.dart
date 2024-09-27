import 'package:subtitle_editor/editor/time.dart';

class Subtitle implements Comparable<Subtitle> {
  Millis start, end;
  String text;

  /// # Инварианты
  /// ```dart
  /// assert(this.start < this.end);
  /// ```
  Subtitle(this.start, this.end, this.text) {
    assert(start.compareTo(end) < 0);
  }

  /// Количество символов в миллисекунду
  double get cpms => text.length / (end.ticks - start.ticks);

  /// Количество символов в секунду
  double get cps => cpms * 1000;

  @override
  int compareTo(Subtitle other) {
    return switch (start.compareTo(other.start)) {
      0 => end.compareTo(other.end),
      final v => v,
    };
  }
}

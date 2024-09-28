import 'package:subtitle_editor/collections/rb_indexed_tree.dart';
import 'package:subtitle_editor/editor/time.dart';

/// Функция редактирования субтитра.
/// # Возвращает
/// - `true` если субтитр успешно отредактирован
/// - `false` если субтитр нужно удалить
typedef EditFunction = bool Function(SubtitleEditor);

/// Таблица субтитров, эффективная, упорядоченная и изменяемая.
class SubtitleTable {
  final _subtitleTree = RbIndexedTree<Subtitle>();

  /// Пустая таблица
  SubtitleTable();

  int get length => _subtitleTree.length;

  /// Вставить субтитр в таблицу на позицию после `index`,
  /// предварительно отредактировав.
  /// Если `index` не в таблице, добавить субтитр в её начало.
  /// # Возвращает
  /// - Новый индекс вставленного субтитра
  /// - -1 если субтитр не был вставлен (переполнение или запрос на удаление)
  int insert(int index, EditFunction f) {
    const maxLength = (1 << 63) - 1;
    if (length == maxLength) return -1;

    final isIndexValid = 0 <= index && index < length;
    final time = isIndexValid ? this[index].end : Millis(0);
    final subtitle = Subtitle(time, time, "");
    final isNotDeleted = f(SubtitleEditor(subtitle));
    return isNotDeleted ? _subtitleTree.insert(subtitle) : -1;
  }

  /// Отредактировать субтитр на позиции `index`.
  /// # Инварианты
  /// ```dart
  /// assert(0 <= index && index < this.length);
  /// ```
  /// # Возвращает
  /// - Новый индекс отредактированного субтитра
  /// - -1 если субтитр был удалён
  int edit(int index, EditFunction f) {
    final subtitle = _subtitleTree.pop(index);
    final isNotDeleted = f(SubtitleEditor(subtitle));
    return isNotDeleted ? _subtitleTree.insert(subtitle) : -1;
  }

  /// Просмотреть субтитр на позиции `index`.
  /// # Инварианты
  /// ```dart
  /// assert(0 <= index && index < this.length);
  /// ```
  Subtitle operator [](int index) => _subtitleTree[index];
}

/// Редактор субтитра, не допускающий нарушения инвариантов.
class SubtitleEditor {
  final Subtitle inner;

  set text(String value) => inner._text = value;

  set start(Millis value) {
    inner._start = value;
    if (inner._end < value) {
      inner._end = value;
    }
  }

  set end(Millis value) {
    inner._end = value;
    if (inner._start > value) {
      inner._start = value;
    }
  }

  SubtitleEditor(this.inner);
}

/// Субтитр, доступный лишь для чтения.
/// Для редактирования нужно использовать класс `SubtitleEditor`.
class Subtitle implements Comparable<Subtitle> {
  Millis _start, _end;
  String _text;

  Millis get start => _start;
  Millis get end => _end;
  String get text => _text;

  /// # Инварианты
  /// ```dart
  /// assert(this.start <= this.end);
  /// ```
  Subtitle(this._start, this._end, this._text) {
    assert(start <= end);
  }

  /// Количество символов в миллисекунду
  double get cpms => _text.length / (end.ticks - start.ticks);

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

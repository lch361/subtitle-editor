import 'dart:io';

import 'package:subtitle_editor/collections/rb_indexed_tree.dart';
import 'package:subtitle_editor/collections/result.dart';
import 'package:subtitle_editor/editor/time.dart';

/// Функция редактирования субтитра.
/// # Возвращает
/// - `true` если субтитр успешно отредактирован
/// - `false` если субтитр нужно удалить
typedef EditFunction = bool Function(SubtitleEditor);

/// Функция импорта субтитров.
/// # Параметры
/// - [RandomAccessFile] всегда открыт на чтение.
/// - Если хоть раз [Iterable]<[Result]<[Subtitle], [E]>> вернёт
///   следующим элементом [Err]<[Subtitle], [E]>, то итерация заканчивается.
typedef ImportFunction<E> = Iterable<Result<Subtitle, E>> Function(
    RandomAccessFile);

/// Функция экспорта субтитров.
/// # Параметры
/// - [RandomAccessFile] всегда открыт на запись.
/// - [Iterable]<[Subtitle]> - последовательность отсортированных по времени
///   субтитров
typedef ExportFunction = void Function(RandomAccessFile, Iterable<Subtitle>);

Iterable<Subtitle> _filterSubsForExport(Iterable<Subtitle> subs) sync* {
  for (final sub in subs) {
    var result = StringBuffer();
    var newline = false;
    for (final line in sub.text.split('\n')) {
      if (line.isEmpty) continue;
      if (newline) result.write('\n');
      result.write(line);
      newline = true;
    }
    if (result.isEmpty) continue;
    yield Subtitle(sub.start, sub.end, result.toString());
  }
}

/// Таблица субтитров, эффективная, упорядоченная и изменяемая.
class SubtitleTable {
  final _subtitleTree = RbIndexedTree<Subtitle>();

  /// Пустая таблица
  SubtitleTable();

  int get length => _subtitleTree.length;

  /// Вставить субтитр в таблицу на позицию после [index],
  /// предварительно отредактировав.
  /// Если [index] не в таблице, добавить субтитр в её начало.
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

  /// Отредактировать субтитр на позиции [index].
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

  /// Просмотреть субтитр на позиции [index].
  /// # Инварианты
  /// ```dart
  /// assert(0 <= index && index < this.length);
  /// ```
  Subtitle operator [](int index) => _subtitleTree[index];

  /// Импортировать субтитры из файла [file]
  /// с помощью определённого форматировщика [f].
  /// # Исключения
  /// - [FileSystemException] при ошибке открытия, чтения файла или закрытия
  static Result<SubtitleTable, E> import<E>(File file, ImportFunction<E> f) {
    var result = SubtitleTable();

    var rafile = file.openSync(mode: FileMode.read);
    try {
      for (final x in f(rafile)) {
        switch (x) {
          case Ok(value: final s):
            result._subtitleTree.insert(s);
          case Err(value: final e):
            return Err(e);
        }
      }
    } finally {
      rafile.closeSync();
    }
    return Ok(result);
  }

  /// Экспортировать субтитры в файл [file]
  /// с помощью определённого форматировщика [f].
  /// # Исключения
  /// - [FileSystemException] при ошибке открытия, записи файла или закрытия
  void export(File file, ExportFunction f) {
    var rafile = file.openSync(mode: FileMode.writeOnly);
    try {
      f(rafile, _filterSubsForExport(_subtitleTree));
    } finally {
      rafile.closeSync();
    }
  }
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
/// Для редактирования нужно использовать класс [SubtitleEditor].
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

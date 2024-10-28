import 'dart:io';

import 'package:subtitle_editor/collections/result.dart';
import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:subtitle_editor/editor/time.dart';

enum MalformedSubRipCause {
  format,
  encoding,
}

class MalformedSubRip {
  int lineNumber, colNumber;
  MalformedSubRipCause cause;

  MalformedSubRip(this.lineNumber, this.colNumber, this.cause);
}

int _readSubsequentByteUtf8(RandomAccessFile file) {
  final result = file.readByteSync();
  return result & 0xC0 == 0x80 ? result & 0x3F : -1;
}

Result<String?, int> _readLineUtf8(RandomAccessFile file) {
  const newline = 0x0a;
  var buf = StringBuffer();

  outer:
  while (true) {
    var codepoint = file.readByteSync();
    switch (codepoint) {
      case -1:
      case newline:
        break outer;
    }

    if (codepoint & 0xE0 == 0xC0) {
      final second = _readSubsequentByteUtf8(file);
      codepoint = second != -1 ? codepoint << 6 | second : -1;
    } else if (codepoint & 0xF0 == 0xE0) {
      for (var i = 0; i < 2 && codepoint != -1; ++i) {
        final second = _readSubsequentByteUtf8(file);
        codepoint = second != -1 ? codepoint << 6 | second : -1;
      }
    } else if (codepoint & 0xF8 == 0xF0) {
      for (var i = 0; i < 3 && codepoint != -1; ++i) {
        final second = _readSubsequentByteUtf8(file);
        codepoint = second != -1 ? codepoint << 6 | second : -1;
      }
    } else if (codepoint & 0x80 != 0) {
      return Err(buf.length);
    }

    if (codepoint == -1) {
      return Err(buf.length);
    }

    buf.writeCharCode(codepoint);
  }
  return Ok(buf.toString());
}

(String, String)? _splitByArrow(String v) {
  final result = v.indexOf(" --> ");
  return result == -1
      ? null
      : (v.substring(0, result), v.substring(result + 5));
}

Millis? _parseTime(String s) {
  throw UnimplementedError;
}

Result<(Millis, Millis), int> _parseTimes(String line) {
  final String start, end;
  switch (_splitByArrow(line)) {
    case (final a, final b):
      (start, end) = (a, b);
    case null:
      return const Err(0);
  }

  final (startIndex, endIndex) = (0, start.runes.length + 5);
  final startTime = _parseTime(start);
  if (startTime == null) {
    return Err(startIndex);
  }

  final endTime = _parseTime(end);
  if (endTime == null) {
    return Err(endIndex);
  }

  return Ok((startTime, endTime));
}

Iterable<Result<Subtitle, MalformedSubRip>> import(
    RandomAccessFile file) sync* {
  var line = 1;
  outer:
  while (true) {
    final String numLine;
    switch (_readLineUtf8(file)) {
      case Ok(value: null):
        break outer;
      case Ok(value: final String v):
        numLine = v;
      case Err(value: final e):
        yield Err(MalformedSubRip(line, e, MalformedSubRipCause.encoding));
        break outer;
    }

    final maybeNum = int.tryParse(numLine);
    if (maybeNum == null || maybeNum <= 0) {
      yield Err(MalformedSubRip(line, 0, MalformedSubRipCause.format));
      break outer;
    }
    line += 1;

    final String timeLine;
    switch (_readLineUtf8(file)) {
      case Ok(value: null):
        yield Err(MalformedSubRip(line, 0, MalformedSubRipCause.format));
        break outer;
      case Ok(value: final String v):
        timeLine = v;
      case Err(value: final e):
        yield Err(MalformedSubRip(line, e, MalformedSubRipCause.encoding));
        break outer;
    }

    final Millis start, end;
    switch (_parseTimes(timeLine)) {
      case Ok(value: final v):
        (start, end) = v;
      case Err(value: final e):
        yield Err(MalformedSubRip(line, e, MalformedSubRipCause.format));
        break outer;
    }
    line += 1;

    var text = StringBuffer();
    var textNewline = false;
    text:
    while (true) {
      switch (_readLineUtf8(file)) {
        case Ok(value: null):
        case Ok(value: ""):
          break text;
        case Ok(value: final String textLine):
          if (textNewline) {
            text.write("\n");
          }
          text.write(textLine);
          textNewline = true;
        case Err(value: final e):
          yield Err(MalformedSubRip(line, e, MalformedSubRipCause.encoding));
          break outer;
      }
    }

    yield Ok(Subtitle(start, end, text.toString()));
  }
}

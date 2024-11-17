import 'dart:io';

import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:subtitle_editor/editor/time.dart';

void _writeDoubleDigitInt(RandomAccessFile file, int value) {
  const zero = 0x30; // 0
  final result = value.toString();
  if (result.length == 1) {
    file.writeByteSync(zero);
  }
  file.writeStringSync(result);
}

void _writeTime(RandomAccessFile file, MillisFormatted value) {
  const colon = 0x3a /* : */, comma = 0x2c /* , */;
  _writeDoubleDigitInt(file, value.hour);
  file.writeByteSync(colon);
  _writeDoubleDigitInt(file, value.minute);
  file.writeByteSync(colon);
  _writeDoubleDigitInt(file, value.second);
  file.writeByteSync(comma);
  _writeDoubleDigitInt(file, value.millisecond);
}

void export(RandomAccessFile file, Iterable<Subtitle> subs) {
  const newline = 0x0a; // \n
  for (final (i, v) in subs.indexed) {
    if (i != 0) {
      file.writeByteSync(newline);
    }

    file.writeStringSync((i + 1).toString());
    file.writeByteSync(newline);

    _writeTime(file, v.start.format());
    file.writeStringSync(" --> ");
    _writeTime(file, v.end.format());
    file.writeByteSync(newline);

    file.writeStringSync(v.text);
    file.writeByteSync(newline);
  }
}

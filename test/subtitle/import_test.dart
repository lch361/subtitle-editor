import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_editor/collections/result.dart';
import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:file/memory.dart';
import 'package:subtitle_editor/editor/time.dart';

import 'package:subtitle_editor/editor/import/srt.dart' as srt;

SubtitleTable tableFromList(Iterable<Subtitle> subs) {
  var result = SubtitleTable();
  for (final sub in subs) {
    result.insert(-1, (editor) {
      editor.start = sub.start;
      editor.end = sub.end;
      editor.text = sub.text;
      return true;
    });
  }
  return result;
}

void expectTablesEqual(SubtitleTable a, SubtitleTable b) {
  expect(a.length, b.length);
  for (var i = 0; i < a.length; ++i) {
    final subtitleA = a[i], subtitleB = b[i];
    final tupleA = (subtitleA.start.ticks, subtitleA.end.ticks, subtitleA.text);
    final tupleB = (subtitleB.start.ticks, subtitleB.end.ticks, subtitleB.text);
    expect(tupleA, tupleB);
  }
}

const sampleEnSrt = '''
1
00:02:16,612 --> 00:02:19,376
Senator, we're making
our final approach into Coruscant.

2
00:02:19,482 --> 00:02:21,609
Very good, Lieutenant.

3
00:03:13,336 --> 00:03:15,167
We made it.

4
00:03:18,608 --> 00:03:20,371
I guess I was wrong.

5
00:03:20,476 --> 00:03:22,671
There was no danger at all.
''';

const sampleRuSrt = '''
425
00:18:21,160 --> 00:18:22,599
Знаю, мы с Олли насрали на кровать,

426
00:18:22,600 --> 00:18:24,500
и всё же дай нам шанс сменить простыни.

427
00:18:24,600 --> 00:18:26,270
Это метафора.

428
00:18:26,370 --> 00:18:27,170
И плохая.

429
00:18:27,300 --> 00:18:28,700
Ей дали слишком много шансов.
''';

void testImport(String src, SubtitleTable expect, ImportFunction f) {
  var fs = MemoryFileSystem();
  final file = fs.file("/sample.srt");
  file.writeAsStringSync(src);

  final SubtitleTable result;
  switch (SubtitleTable.import(file, f)) {
    case Ok(value: final v):
      result = v;
    case Err(value: final e):
      fail("Import failed with this error: $e");
  }
  expectTablesEqual(result, expect);
}

void main() {
  group('English', () {
    final table = tableFromList([
      Subtitle(Millis(136612), Millis(139376),
          "Senator, we're making\nour final approach into Coruscant."),
      Subtitle(Millis(139482), Millis(141609), "Very good, Lieutenant."),
      Subtitle(Millis(193336), Millis(195167), "We made it."),
      Subtitle(Millis(198608), Millis(200371), "I guess I was wrong."),
      Subtitle(Millis(200476), Millis(202671), "There was no danger at all."),
    ]);

    test('SubRip', () {
      testImport(sampleEnSrt, table, srt.import);
    });
  });

  group('Russian', () {
    final table = tableFromList([
      Subtitle(Millis(1101160), Millis(1102599),
          "Знаю, мы с Олли насрали на кровать,"),
      Subtitle(Millis(1102600), Millis(1104500),
          "и всё же дай нам шанс сменить простыни."),
      Subtitle(Millis(1104600), Millis(1106270), "Это метафора."),
      Subtitle(Millis(1106370), Millis(1107170), "И плохая."),
      Subtitle(
          Millis(1107300), Millis(1108700), "Ей дали слишком много шансов."),
    ]);

    test('SubRip', () {
      testImport(sampleRuSrt, table, srt.import);
    });
  });
}

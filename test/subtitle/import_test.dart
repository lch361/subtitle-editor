import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_editor/collections/result.dart';
import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:file/memory.dart';
import 'package:subtitle_editor/editor/time.dart';

import 'package:subtitle_editor/editor/import/srt.dart' as srt;

SubtitleTable expectation() {
  var result = SubtitleTable();

  result.insert(-1, (editor) {
    editor.start = Millis(136612);
    editor.end = Millis(139376);
    editor.text = "Senator, we're making\nour final approach into Coruscant.";
    return true;
  });

  result.insert(-1, (editor) {
    editor.start = Millis(139482);
    editor.end = Millis(141609);
    editor.text = "Very good, Lieutenant.";
    return true;
  });

  result.insert(-1, (editor) {
    editor.start = Millis(193336);
    editor.end = Millis(195167);
    editor.text = "We made it.";
    return true;
  });

  result.insert(-1, (editor) {
    editor.start = Millis(198608);
    editor.end = Millis(200371);
    editor.text = "I guess I was wrong.";
    return true;
  });

  result.insert(-1, (editor) {
    editor.start = Millis(200476);
    editor.end = Millis(202671);
    editor.text = "There was no danger at all.";
    return true;
  });

  return result;
}

const sampleSrt = '''
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

void expectTablesEqual(SubtitleTable a, SubtitleTable b) {
  expect(a.length, b.length);
  for (var i = 0; i < a.length; ++i) {
    final subtitleA = a[i], subtitleB = b[i];
    final tupleA = (subtitleA.start.ticks, subtitleA.end.ticks, subtitleA.text);
    final tupleB = (subtitleB.start.ticks, subtitleB.end.ticks, subtitleB.text);
    expect(tupleA, tupleB);
  }
}

void main() {
  var fs = MemoryFileSystem();

  final table = expectation();

  test('SubRip', () {
    final file = fs.file("/sample.srt");
    file.writeAsStringSync(sampleSrt);

    final SubtitleTable result;
    switch (SubtitleTable.import(file, srt.import)) {
      case Ok(value: final v):
        result = v;
      case Err(value: final e):
        fail("Import failed with this error: $e");
    }
    expectTablesEqual(result, table);
  });
}

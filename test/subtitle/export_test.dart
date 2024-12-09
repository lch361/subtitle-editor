import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:file/memory.dart';
import 'package:subtitle_editor/editor/time.dart';

import 'package:subtitle_editor/editor/export/srt.dart' as srt;

SubtitleTable sample() {
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
    editor.start = Millis(198008);
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

const expectSrt = '''
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
00:03:18,008 --> 00:03:20,371
I guess I was wrong.

5
00:03:20,476 --> 00:03:22,671
There was no danger at all.
''';

void main() {
  var fs = MemoryFileSystem();

  final table = sample();

  test('SubRip', () {
    final file = fs.file("/sample.srt");
    expect(file.existsSync(), false);
    table.export(file, srt.export);

    final result = file.readAsStringSync();
    expect(result, expectSrt);
  });
}

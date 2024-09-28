import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:subtitle_editor/editor/time.dart';

void main() {
  test('Inserting', () {
    var table = SubtitleTable();

    expect(table.insert(0, (_) => false), -1);

    var result = table.insert(0, (editor) {
      editor.start = Millis(1);
      editor.text = "Lorem";
      return true;
    });
    expect(result, 0);

    result = table.insert(-1, (editor) {
      editor.start = Millis(0);
      editor.text = "Ipsum";
      return true;
    });
    expect(result, 0);

    result = table.insert(1, (editor) {
      editor.start = Millis(2);
      editor.text = "Dolor";
      return true;
    });
    expect(result, 2);

    result = table.insert(1, (editor) {
      editor.start = Millis(3);
      editor.text = "Sit";
      return true;
    });
    expect(result, 3);

    expect(table[0].text, "Ipsum");
    expect(table[1].text, "Lorem");
    expect(table[2].text, "Dolor");
    expect(table[3].text, "Sit");
  });

  test('Editing', () {
    var table = SubtitleTable();
    table.insert(-1, (editor) {
      editor.start = Millis(1);
      editor.text = "Lorem";
      return true;
    });
    table.insert(-1, (editor) {
      editor.start = Millis(2);
      editor.text = "Ipsum";
      return true;
    });
    table.insert(-1, (editor) {
      editor.start = Millis(3);
      editor.text = "Dolor";
      return true;
    });
    table.insert(-1, (editor) {
      editor.start = Millis(4);
      editor.text = "Sit";
      return true;
    });
    table.insert(-1, (editor) {
      editor.start = Millis(5);
      editor.text = "Amet";
      return true;
    });

    var result = table.edit(4, (editor) {
      editor.text = "Do";
      editor.start = Millis(0);
      return true;
    });
    expect(result, 0);

    expect(table.edit(2, (_) => false), -1);
    expect(table.edit(2, (_) => false), -1);

    expect(table[0].text, "Do");
    expect(table[1].text, "Lorem");
    expect(table[2].text, "Sit");
  });
}

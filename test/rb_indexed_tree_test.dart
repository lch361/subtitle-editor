import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_editor/collections/rb_indexed_tree.dart';

void main() {
  group('RbIndexedTree', () {
    test('Insertion', () {
      var rb = RbIndexedTree<num>();
      expect(rb.insert(1), 0);
      expect(rb.insert(5), 1);
      expect(rb.insert(4), 1);
      expect(rb.insert(6), 3);
      expect(rb.insert(2), 1);
      expect(rb.insert(3), 2);
      expect(rb.insert(0), 0);
      expect(rb.insert(9), 7);
      expect(rb.insert(8), 7);
      expect(rb.insert(7), 7);
    });

    var rb = RbIndexedTree<num>();

    setUp(() {
      rb.insert(1);
      rb.insert(5);
      rb.insert(4);
      rb.insert(6);
      rb.insert(2);
      rb.insert(3);
      rb.insert(0);
      rb.insert(9);
      rb.insert(8);
      rb.insert(7);
    });

    tearDown(() {
      rb = RbIndexedTree();
    });

    test('Length', () {
      expect(rb.length, 10);

      rb.insert(1);
      rb.insert(5);
      rb.insert(4);
      expect(rb.length, 13);

      rb.insert(6);
      rb.insert(2);
      rb.insert(3);
      rb.insert(0);
      expect(rb.length, 17);

      rb.insert(9);
      rb.insert(8);
      rb.insert(7);
      expect(rb.length, 20);
    });

    test('Indices', () {
      for (int i = 0; i < 10; ++i) {
        expect(rb[i], i);
      }
    });
  });
}

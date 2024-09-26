enum Color { red, black }

class RbIndexedNode<T extends Comparable<T>> {
  T value;
  int length = 1;
  Color color;
  RbIndexedTree<T> left = RbIndexedTree(), right = RbIndexedTree();
  RbIndexedNode<T>? parent;

  RbIndexedNode(this.value, this.parent, this.color) {
    var node = parent;
    while (node != null) {
      node.length += 1;
      node = node.parent;
    }
  }

  void decrementLength() {
    var node = this;
    while (node.parent != null) {
      node.length -= 1;
      node = node.parent as RbIndexedNode<T>;
    }
  }

  RbIndexedNode<T> insertRebalance() {
    var current = this;

    // while (true) {
    //   final parent = current.parent;
    //   if (parent == null) break; // Case 3
    //   if (parent.color == Color.black) break; // Case 1

    //   final grandParent = parent.parent;
    //   if (grandParent == null) {
    //     // Case 4
    //     parent.color = Color.black;
    //     break;
    //   }

    //   final uncleTree = identical(grandParent.left.node, parent)
    //       ? grandParent.right
    //       : grandParent.left;

    //   assert(uncleTree.node != null);
    //   final uncle = uncleTree.node as RbIndexedNode<T>;

    //   assert(parent.color == Color.red);
    //   assert(grandParent.color == Color.black);

    //   if (uncle.color == Color.red) {
    //     // Case 2
    //     parent.color = uncle.color = Color.black;
    //     grandParent.color = Color.red;
    //     current = grandParent;
    //     continue;
    //   }

    //   // Case 5: TODO
    //   // Case 6: TODO
    //   break;
    // }

    return current;
  }

  int index() {
    var result = left.length;
    var current = this;

    while (true) {
      final parent = current.parent;
      if (parent == null) break;

      if (identical(parent.right.node, current)) {
        result += parent.left.length + 1;
      }

      current = parent;
    }

    return result;
  }
}

class RbIndexedTree<T extends Comparable<T>> {
  RbIndexedNode<T>? node;

  int get length => node?.length ?? 0;

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index < length);
  /// assert(this._treeByIndex(index).node != null);
  /// ```
  RbIndexedTree<T> _treeByIndex(int index) {
    var tree = this;
    var start = 0;

    while (true) {
      final node = tree.node as RbIndexedNode<T>;
      final leftLength = node.left.length;
      final treeIndex = start + leftLength;

      switch (index.compareTo(treeIndex)) {
        case -1:
          tree = node.left;
        case 1:
          start += leftLength + 1;
          tree = node.right;
        case 0:
          return tree;
      }
    }
  }

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index < length);
  /// ```
  T operator [](int index) {
    return (_treeByIndex(index).node as RbIndexedNode<T>).value;
  }

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index < length);
  /// ```
  T pop(int index) {
    final tree = _treeByIndex(index);
    final value = (tree.node as RbIndexedNode<T>).value;
    tree._remove();
    return value;
  }

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index < length);
  /// ```
  void erase(int index) => _treeByIndex(index)._remove();

  /// # Инварианты
  /// ```dart
  /// assert(this.node != null);
  /// ```
  void _remove() {
    var node = this.node as RbIndexedNode<T>;
    switch ((node.left, node.right)) {
      case (RbIndexedTree<T>(node: null), RbIndexedTree<T>(node: null)):
        final parent = node.parent;
        if (parent == null) {
          this.node = null;
        } else if (node.color == Color.red) {
          parent.decrementLength();
          this.node = null;
        } else {
          throw UnimplementedError("Black childless node rebalancing");
        }
      case (RbIndexedTree<T>(node: null), RbIndexedTree<T> child):
      case (RbIndexedTree<T> child, RbIndexedTree<T>(node: null)):
        var node = child.node as RbIndexedNode<T>;
        node.color = Color.black;
        node.parent?.decrementLength();

        this.node = node;
      case (_, RbIndexedTree<T> right):
        var leftmost = right;
        while (true) {
          final left = (leftmost.node as RbIndexedNode<T>).left;
          if (left.node == null) break;
          leftmost = left;
        }

        node.value = (leftmost.node as RbIndexedNode<T>).value;
        leftmost._remove();
    }
  }

  /// # Инварианты
  /// ```dart
  /// assert(ret.color == Color.red);
  /// ```
  RbIndexedNode<T> _insert(T value) {
    RbIndexedNode<T>? parent;
    var tree = this;
    while (tree.node != null) {
      final node = tree.node as RbIndexedNode<T>;
      parent = node;
      tree = value.compareTo(node.value) == -1 ? node.left : node.right;
    }

    final node = RbIndexedNode(value, parent, Color.red);
    tree.node = node;
    return node;
  }

  /// # Инварианты
  /// ```dart
  /// assert(this.length != (1 << 63) - 1);
  /// ```
  int insert(T value) => _insert(value).insertRebalance().index();
}

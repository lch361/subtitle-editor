enum _Color { red, black }

class _RbIndexedNode<T extends Comparable<T>> {
  T value;
  int length = 1;
  _Color color;
  RbIndexedTree<T> left = RbIndexedTree(), right = RbIndexedTree(), parent;

  _RbIndexedNode(this.value, this.parent, this.color) {
    var node = parent._node;
    while (node != null) {
      node.length += 1;
      node = node.parent._node;
    }
  }

  void decrementLength() {
    var node = this;
    while (true) {
      node.length -= 1;
      final parent = node.parent._node;
      if (parent == null) break;
      node = parent;
    }
  }

  /// # Инварианты
  /// Применять лишь к недавно удалённой ноде.
  /// ```dart
  /// assert(this.parent._node != null);
  /// assert(this.left._node == this.right._node == null);
  /// assert(this.color == _Color.black);
  /// ```
  void removeRebalance() {
    var parent = this.parent;
    var parentNode = parent._node as _RbIndexedNode<T>;

    var isCurrentLeft = parentNode.left._node == null;

    while (true) {
      var sibling = isCurrentLeft ? parentNode.right : parentNode.left;
      var siblingNode = sibling._node as _RbIndexedNode<T>;

      var closeNephew = isCurrentLeft ? siblingNode.left : siblingNode.right;
      var distantNephew = isCurrentLeft ? siblingNode.right : siblingNode.left;

      if (siblingNode.color == _Color.red) {
        // Case 3
        parent = isCurrentLeft
            ? parent._rotateCounterClockwise()
            : parent._rotateClockwise();

        parentNode.color = _Color.red;
        siblingNode.color = _Color.black;

        sibling = closeNephew;
        siblingNode = closeNephew._node as _RbIndexedNode<T>;
        distantNephew = isCurrentLeft ? siblingNode.right : siblingNode.left;
        closeNephew = isCurrentLeft ? siblingNode.left : siblingNode.right;
      }

      final closeNephewNode = closeNephew._node;
      if (closeNephewNode != null && closeNephewNode.color == _Color.red) {
        // Case 5
        final newSibling = isCurrentLeft
            ? sibling._rotateClockwise()
            : sibling._rotateCounterClockwise();
        closeNephew = sibling;
        sibling = newSibling;

        siblingNode.color = _Color.red;
        closeNephewNode.color = _Color.black;

        distantNephew = sibling;
        sibling = closeNephew;
        siblingNode = sibling._node as _RbIndexedNode<T>;
      }

      final distantNephewNode = distantNephew._node;
      if (distantNephewNode != null && distantNephewNode.color == _Color.red) {
        // Case 6
        isCurrentLeft
            ? parent._rotateCounterClockwise()
            : parent._rotateClockwise();

        siblingNode.color = parentNode.color;
        parentNode.color = _Color.black;
        distantNephewNode.color = _Color.black;
        break;
      }

      if (parentNode.color == _Color.red) {
        // Case 4
        siblingNode.color = _Color.red;
        parentNode.color = _Color.black;
        break;
      }

      // Case 2
      siblingNode.color = _Color.red;
      final newParent = parentNode.parent;
      final newParentNode = newParent._node;

      // Case 1
      if (newParentNode == null) break;
      isCurrentLeft = newParentNode.left._node == parentNode;

      parent = newParent;
      parentNode = newParentNode;
      break;
    }
  }

  void insertRebalance() {
    var currentNode = this;

    while (true) {
      final parent = currentNode.parent;

      var parentNode = parent._node;
      if (parentNode == null || parentNode.color == _Color.black) {
        break; // Case 3 || Case 1
      }

      final grandParent = parentNode.parent;
      final grandParentNode = grandParent._node;
      if (grandParentNode == null) {
        // Case 4
        parentNode.color = _Color.black;
        break;
      }

      final isParentLeft = identical(grandParentNode.left._node, parentNode);
      final uncleTree =
          isParentLeft ? grandParentNode.right : grandParentNode.left;

      final uncleNode = uncleTree._node;
      assert(grandParentNode.color == _Color.black);

      if (uncleNode != null && uncleNode.color == _Color.red) {
        // Case 2
        parentNode.color = uncleNode.color = _Color.black;
        grandParentNode.color = _Color.red;
        currentNode = grandParentNode;
        continue;
      }

      final isCurrentLeft = identical(parentNode.left._node, currentNode);
      final innerChild = isCurrentLeft ^ isParentLeft;
      if (innerChild) {
        // Case 5
        if (isParentLeft) {
          parent._rotateCounterClockwise();
        } else {
          parent._rotateClockwise();
        }

        (currentNode, parentNode) = (parentNode, currentNode);
      }

      // Case 6
      if (isParentLeft) {
        grandParent._rotateClockwise();
      } else {
        grandParent._rotateCounterClockwise();
      }
      parentNode.color = _Color.black;
      grandParentNode.color = _Color.red;

      break;
    }
  }

  int index() {
    var result = left.length;
    var current = this;

    while (true) {
      final parent = current.parent._node;
      if (parent == null) break;

      if (identical(parent.right._node, current)) {
        result += parent.left.length + 1;
      }

      current = parent;
    }

    return result;
  }
}

class RbIndexedTree<T extends Comparable<T>> with Iterable<T> {
  _RbIndexedNode<T>? _node;

  RbIndexedTree._withNode([this._node]);
  RbIndexedTree();

  @override
  int get length => _node?.length ?? 0;

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index && index < length);
  /// assert(this._treeByIndex(index).node != null);
  /// ```
  RbIndexedTree<T> _treeByIndex(int index) {
    assert(0 <= index && index < this.length);

    var tree = this;
    var start = 0;

    while (true) {
      final node = tree._node as _RbIndexedNode<T>;
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
    return (_treeByIndex(index)._node as _RbIndexedNode<T>).value;
  }

  @override
  Iterator<T> get iterator {
    return Iterable.generate(this.length, (index) => this[index]).iterator;
  }

  /// # Инварианты
  /// ```dart
  /// assert(0 <= index < length);
  /// ```
  T pop(int index) {
    final tree = _treeByIndex(index);
    final value = (tree._node as _RbIndexedNode<T>).value;
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
    var node = this._node as _RbIndexedNode<T>;
    switch ((node.left, node.right)) {
      case (RbIndexedTree<T>(_node: null), RbIndexedTree<T>(_node: null)):
        this._node = null;
        final parent = node.parent._node;
        if (parent == null) break;
        parent.decrementLength();
        if (node.color == _Color.black) node.removeRebalance();
      case (
          RbIndexedTree<T>(_node: null),
          RbIndexedTree<T>(_node: _RbIndexedNode<T> childNode)
        ):
      case (
          RbIndexedTree<T>(_node: _RbIndexedNode<T> childNode),
          RbIndexedTree<T>(_node: null)
        ):
        childNode.color = _Color.black;
        childNode.parent._node?.decrementLength();

        this._node = childNode;
        childNode.parent = node.parent;
      case (_, RbIndexedTree<T> right):
        var leftmost = right;
        while (true) {
          final left = (leftmost._node as _RbIndexedNode<T>).left;
          if (left._node == null) break;
          leftmost = left;
        }

        node.value = (leftmost._node as _RbIndexedNode<T>).value;
        leftmost._remove();
    }
  }

  /// # Инварианты
  /// ```dart
  /// assert(this.length != (1 << 63) - 1);
  /// assert(this._insert(value).color == Color.red);
  /// ```
  _RbIndexedNode<T> _insertNode(T value) {
    assert(this.length != (1 << 63) - 1);

    var parent = RbIndexedTree<T>();
    var tree = this;
    while (tree._node != null) {
      parent = tree;
      final node = tree._node as _RbIndexedNode<T>;
      tree = value.compareTo(node.value) < 0 ? node.left : node.right;
    }

    final node = _RbIndexedNode(value, parent, _Color.red);
    tree._node = node;
    return node;
  }

  /// # Инварианты
  /// ```dart
  /// assert(this.length != (1 << 63) - 1);
  /// ```
  int insert(T value) {
    final node = _insertNode(value);
    node.insertRebalance();
    return node.index();
  }

  /// # Инварианты
  /// ```dart
  /// assert(this._node?.right._node != null);
  /// ```
  /// # Возвращает
  /// Новое дерево для смещённого с корня узла
  RbIndexedTree<T> _rotateCounterClockwise() {
    assert(this._node?.right._node != null);

    final current = this;

    final currentNode = current._node as _RbIndexedNode<T>;
    final parent = currentNode.parent;

    final child = currentNode.right;
    final childNode = child._node as _RbIndexedNode<T>;

    final grandInnerChild = childNode.left;
    final grandOuterChild = childNode.right;

    final newTree = RbIndexedTree._withNode(currentNode);
    currentNode.left._node?.parent = newTree;
    currentNode.right = grandInnerChild;
    grandInnerChild._node?.parent = newTree;

    this._node = childNode;
    childNode.parent = parent;

    childNode.left = newTree;
    currentNode.parent = this;

    grandOuterChild._node?.parent = this;

    childNode.length = currentNode.length;
    currentNode.length -= grandOuterChild.length + 1;

    return newTree;
  }

  /// # Инварианты
  /// ```dart
  /// assert(this._node?.left._node != null);
  /// ```
  /// # Возвращает
  /// Новое дерево для смещённого с корня узла
  RbIndexedTree<T> _rotateClockwise() {
    assert(this._node?.left._node != null);

    final current = this;

    final currentNode = current._node as _RbIndexedNode<T>;
    final parent = currentNode.parent;

    final child = currentNode.left;
    final childNode = child._node as _RbIndexedNode<T>;

    final grandInnerChild = childNode.right;
    final grandOuterChild = childNode.left;

    final newTree = RbIndexedTree._withNode(currentNode);
    currentNode.right._node?.parent = newTree;
    currentNode.left = grandInnerChild;
    grandInnerChild._node?.parent = newTree;

    this._node = childNode;
    childNode.parent = parent;

    childNode.right = newTree;
    currentNode.parent = this;

    grandOuterChild._node?.parent = this;

    childNode.length = currentNode.length;
    currentNode.length -= grandOuterChild.length + 1;

    return newTree;
  }

  /// Вывод дерева в JSON для отладки
  @override
  String toString() {
    final length = this.length;
    final result = StringBuffer("{\"length\":$length");

    final node = this._node;
    if (node != null) {
      final value = node.value;
      final color = node.color == _Color.red ? "\"Red\"" : "\"Black\"";
      final left = node.left.toString();
      final right = node.right.toString();
      result.write(
          ",\"value\":$value,\"color\":$color,\"right\":$right,\"left\":$left");
    }
    result.write("}");
    return result.toString();
  }
}

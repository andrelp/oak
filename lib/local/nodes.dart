part of 'local_base.dart';

/// Superclass for all nodes of the internal database tree
abstract class _Node {}

/// leaf node which holds data. Allowed types include String,int,double,bool,NodeReference and BlobReference
class _LeafNode<T> extends _Node {
  final T value;
  _LeafNode(this.value);
}

/// superclass for all non-leaf node types
class _BranchNode extends _Node{}

/// a superclass for all branching nodes except list nodes
abstract class _NamedBranchNode extends _BranchNode {
  /// fields of the node or the map
  Map<String,_Node> children;
  /// [children] is set to [actionChildren] when a action was completed successfully
  Map<String,_Node> actionChildren;
  _NamedBranchNode(this.children);
}

class _DocumentNode extends _NamedBranchNode {
  _DocumentNode(Map<String, _Node> children) : super(children);
}

class _MapNode extends _NamedBranchNode {
  _MapNode(Map<String, _Node> children) : super(children);
}

class _CollectionNode extends _NamedBranchNode {
  _CollectionNode(Map<String, _Node> children) : super(children);
}

class _ListNode extends _BranchNode {
  /// elements of the list
  List<_LeafNode> children;
  /// [children] is set to [actionChildren] when a action was completed successfully
  List<_LeafNode> actionChildren;
}


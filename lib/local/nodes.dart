part of 'local_base.dart';

/// Superclass for all nodes of the internal database tree
abstract class _Node {
  /// parent of current node. If this is the root node [parentNode] is `null`.
  final _BranchNode parentNode;
  /// normalized path of this node. Always ends on '/'
  /// If the node is a child of a list, its [normalizedPath] is `null`
  final NodeReference normalizedPath;
  /// get the [NodeType] of this node
  NodeType get type;
  _Node(this.parentNode,this.normalizedPath);
}

/// leaf node which holds data. Allowed types include String,int,double,bool,NodeReference and BlobReference
class _LeafNode<T> extends _Node {
  final T value;
  @override
  final NodeType type;

  static NodeType _extractNodeType(dynamic value) {
    if (value is String) return NodeType.String;
    if (value is int)    return NodeType.Int;
    if (value is double) return NodeType.Double;
    if (value is bool)   return NodeType.Bool;
    if (value is NodeReference) return NodeType.Reference;
    if (value is BlobReference) return NodeType.BlobReference;
    // should never execute this.
    assert(false);
    return null;
  }

  _LeafNode(_BranchNode parentNode,NodeReference normalizedPath,this.value) : type=_extractNodeType(value), super(parentNode,normalizedPath);
}



/// superclass for all non-leaf node types
abstract class _BranchNode extends _Node{
  _BranchNode(_BranchNode parentNode,NodeReference normalizedPath) : super(parentNode,normalizedPath);
}

/// a superclass for all branching nodes except list nodes
abstract class _NamedBranchNode extends _BranchNode {
  /// fields of the node or the map
  Map<String,_Node> children;
  /// [children] is set to [actionChildren] when a action was completed successfully
  Map<String,_Node> actionChildren;
  _NamedBranchNode(_BranchNode parentNode,NodeReference normalizedPath,this.children) : super(parentNode,normalizedPath);
}

class _DocumentNode extends _NamedBranchNode {
  @override
  NodeType get type => NodeType.Document;
  _DocumentNode(_BranchNode parentNode, NodeReference normalizedPath, Map<String, _Node> children) : super(parentNode,normalizedPath,children);
}

class _MapNode extends _NamedBranchNode {
  @override
  NodeType get type => NodeType.Map;
  _MapNode(_BranchNode parentNode, NodeReference normalizedPath, Map<String, _Node> children) : super(parentNode,normalizedPath,children);
}

class _CollectionNode extends _NamedBranchNode {
  @override
  NodeType get type => NodeType.Collection;
  _CollectionNode(_BranchNode parentNode, NodeReference normalizedPath, Map<String, _Node> children) : super(parentNode,normalizedPath,children);
}

class _ListNode extends _BranchNode {
  @override
  NodeType get type => NodeType.List;
  /// elements of the list
  List<_LeafNode> children;
  /// [children] is set to [actionChildren] when a action was completed successfully
  List<_LeafNode> actionChildren;
  _ListNode(_BranchNode parentNode, this.children) : super(parentNode,null);
}


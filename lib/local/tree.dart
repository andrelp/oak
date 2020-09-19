part of 'local_base.dart';

class _DBTree {

  _DocumentNode root;

  _DBTree(this.root);

  /// Returns the node at reference. Returns null if the node does not exist
  _Node locateNode(NodeReference reference) {
    // used to determine whether a reference points to one of its children
    var usedReferenceNodes = <String>{};
    
    _Node Function(NodeReference reference) locate;

    _Node nextNode(_Node current, String pathComponent) {
      if (current is _NamedBranchNode) {
        if (pathComponent=='.') return current;
        if (pathComponent=='..') return current.parentNode;
        return current.children[pathComponent];
      } else if (current is _LeafNode<NodeReference>) {
        if (usedReferenceNodes.contains(current.normalizedPath.path)) return null;
        usedReferenceNodes.add(current.normalizedPath.path);
        var target = locate(current.value);
        if (target==null) return null;
        return nextNode(target, pathComponent);
      } else {
        return null;
      }
    }

    locate = (reference) {
      var path = reference.pathComponents;
      _Node current = root;
      for (var pc in path) {
        current = nextNode(current, pc);
        if (current==null) return null;
      }
      return current;
    };

    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    
    return locate(reference);
  }

  /// Locates the parent node of the node at [reference].
  /// Returns `null` if the parent does not exist (including when the root node is at [reference])
  _Node locateParentNode(NodeReference reference) {
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    if (reference.isRootPath) return null;
    var pre = locateNode(reference.prefixPath);
    if (pre==null) return null;
    var pc  = reference.lastPathComponent;
    if (pre is _NamedBranchNode) {
      if (pc=='.') return pre.parentNode;
      if (pc=='..') return pre.parentNode?.parentNode;
      return pre;
    } else if (pre is _LeafNode<NodeReference>) {
      var target = locateNode(pre.value);
      if (target==null) return null;
      if (pc=='.') return target.parentNode;
      if (pc=='..') return target.parentNode?.parentNode;
      return target;
    } else {
      return null;
    }
  }

  dynamic extractValue(_Node node) {
    if (node==null) throw NullThrownError();

    dynamic extract(_Node node, [bool nested=true]) {
      if (node is _LeafNode) return node.value;
      if (node is _CollectionNode) {
        if (nested) return CollectionChildPlaceholder(node.normalizedPath);
        return node.children.keys.toList();
      }
      if (node is _ListNode) {
        return node.children.map((n) => extract(n)).toList();
      }
      if (node is _DocumentNode && nested) {
        return DocumentChildPlaceholder(node.normalizedPath);
      }
      if (node is _MapNode || node is _DocumentNode) {
        return (node as _NamedBranchNode).children.map<String,dynamic>(
          (key,child) => MapEntry(key, extract(child))
        );
      }
      // should never execute this.
      assert(false);
      return null;
    }

    return extract(node,false);
  }

}
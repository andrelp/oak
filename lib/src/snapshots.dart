
part of 'oak_base.dart';

/// A node snapshot contains data of a node.
/// It stores whether it exists, its type, its normalized path within the database tree
/// and (some) data of the subtree of the database beginning with the node.
/// 
/// When using [OakProvider.watch] one snapshot is fired immediately. Subsequently a snapshot is fired every time
/// - The node is created (when node at the requested path did not exist previously)
/// - The node is replaced (changed)
/// - The node is a document or a map and some descendant node is replaced/created/deleted, excluding all document- and collection-subtrees (but including the document and collection nodes themselves)
/// - The node is deleted
/// - The normalization of the requested path changes (e.g. because a value of a cross reference was changed)
class NodeSnapshot {

  /// The type of the node of this snapshot. If node does not exist, type is `null`.
  final NodeType type;

  /// indicates whether a node exist at [requestReference]
  bool get exists => type!=null; 

  /// Stores the value of the node.
  /// 
  /// If node is a leaf node, i.e. stores a primitive value or a (blob-) reference, or a list node,
  /// then [value] is set to that value or to a `List` with corresponding entries.
  /// 
  /// If the node is a document or a map node, [value] is set to an instance of `Map<String,dynamic>` 
  /// which contains a (nested) map of the subtree beginning with the node.
  /// However, each direct or indirect child-sub-tree which is a document or a collection,
  /// is replaced by an instance of either [DocumentChildPlaceholder] or [CollectionChildPlaceholder].
  /// 
  /// If the node is a collection or if the node does not exist, [value] will be set to `null`.
  final dynamic value;

  /// Normalized path to the specific node fetched. If node does not exist, [normalizedReference] is `null`.
  final NodeReference normalizedReference;

  /// (Multi-)path which was used for fetching this snapshot.
  final NodeReference requestReference;

  NodeSnapshot(this.requestReference,this.normalizedReference,this.type,this.value);
  factory NodeSnapshot.doesNotExist(NodeReference reference) => NodeSnapshot(reference,null,null, null); 
}

/// A Replacement of a child document in a snapshot copy of a map or a document
class DocumentChildPlaceholder {
  /// normalized path reference to the child document
  final NodeReference reference;
  DocumentChildPlaceholder(this.reference);
}

/// A Replacement of a child collection in a snapshot copy of a map or a document
class CollectionChildPlaceholder {
  /// normalized path reference to the child document
  final NodeReference reference;
  CollectionChildPlaceholder(this.reference);
}


/// A snapshot for all nodes matching a query.
/// 
/// When using [OakProvider.watchQuery] one snapshot is fired immediately 
/// and subsequently every time the set of nodes included in this query changes
/// or a node included in the query is modified.
class QuerySnapshot {
  /// Snapshots of all nodes included in the query
  final List<NodeSnapshot> snapshots;
  /// sub list of snapshots. All nodes which are added to the the query either by change
  /// or creation of the node or by change of the normalization of the request reference. 
  /// In the first snapshot every node matching the query is in this list.
  final List<NodeSnapshot> added;
  /// sub list of snapshots. All nodes which where included in previous snapshot and in
  /// this one and where changed in between those two. This also includes document nodes
  /// for which some descendant node is replaced/created/deleted, excluding all document-
  /// and collection-subtrees (but including the document and collection nodes themselves).
  final List<NodeSnapshot> modified;
  /// All nodes which where included in last query snapshot but no longer are included
  /// either because of deletion or because of modification.
  final List<NodeSnapshot> removed;

  QuerySnapshot(this.snapshots,this.added,this.modified,this.removed);
}


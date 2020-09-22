
part of 'oak_base.dart';

/// A node snapshot contains data of a node.
/// It stores whether it exists, its type, its normalized path within the database tree
/// and (some) data of the subtree of the database beginning with the node.
/// 
/// When using [OakProvider.watch] one snapshot is fired immediately. Subsequently a snapshot is fired every time
/// - The node is created (when node at the requested path did not exist previously)
/// - The node is replaced (changed)
/// - the node is a document or map node and some of its descendant nodes are replaced/created/deleted, excluding all descendants of other documents or collections.
/// - The node is a collection and a document is added to or removed from that collection.
/// - The node is a list and elements are added or removed from the list.
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
  /// If the node is a collection, [value] will be a [List] of type [String] with the names of all documents contained in the collection.
  /// If the node does not exist, [value] will be set to `null`.
  final dynamic value;

  /// Normalized path to the specific node fetched.
  /// If node does not exist, [normalizedReference] is `null`.
  /// If node does not exist, but this snap was included in the removed list of a query snapshot,
  /// then [normalizedReference] is not `null`, but the normalized reference to the node which is now deleted
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
/// The first snapshot is fired immediately 
/// and subsequently every time
/// - the set of nodes included in this query changes (via creation/deletion/modification)
/// - a node included in the query is modified
/// - a document or map node is included in this query and some of its descendant nodes are replaced/created/deleted, excluding all descendants of other documents or collections.
/// - a collection is included in the query and a document is added to or removed from that collection or a document in the collection was changed
/// - a list is included in the query and an element was added to or removed from the list
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


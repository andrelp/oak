part of 'oak_base.dart';


/// Describes for a node if it stores values (is a leaf node), and if so which kinds of data it can store, or is a branch node.
enum NodeType {
  String, Int, Double, Bool, Reference, List, Map, Document, Collection, BlobReference
}

extension NodeTypeExtension on NodeType {
  /// indicated whether the node stores any data or if the node is a branch node. References are considered leafs.
  bool get isLeaf => this==NodeType.String||this==NodeType.Int||this==NodeType.Double||this==NodeType.Bool||this==NodeType.Reference||this==NodeType.BlobReference;
}

/// The database may resolve a `Future` with this exception if it
/// could not fullfil an requested action on the database.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}


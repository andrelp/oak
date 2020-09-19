part of 'oak_base.dart';


/// Describes for a node if it stores values (is a leaf node), and if so which kinds of data it can store, or is a branch node.
enum NodeType {
  String, Int, Double, Bool, Reference, List, Map, Document, Collection, BlobReference
}

extension NodeTypeExtension on NodeType {
  /// indicated whether the node stores any data or if the node is a branch node. References are considered leafs.
  bool get isLeaf => this==NodeType.String||this==NodeType.Int||this==NodeType.Double||this==NodeType.Bool||this==NodeType.Reference||this==NodeType.BlobReference;
}

/// [BlobData] is used as a parameter for [OakProvider.set] and [OakProvider.update].
/// 
/// The database will write the blob data to it, give it an unique id
/// and save the corresponding blob reference to the node in the database.
class BlobData {
  /// raw data which is to be written to the database.
  Uint8List data;
  BlobData(this.data);
}

/// [DocumentData] is used as a parameter for [OakProvider.set] and [OakProvider.update].
/// 
/// It will create a new document node with child nodes as defined by [fields]
class DocumentData {
  /// data for the child nodes of the document node which will be created.
  final Map<String,dynamic> fields;
  DocumentData(this.fields);
}

/// [CollectionData] is used as a parameter for [OakProvider.set] and [OakProvider.update].
/// 
/// It will create a new collection node with child document nodes as defined by list [children].
class CollectionData {
  /// child documents of the new collection.
  final Map<String,DocumentData> children;
  CollectionData([this.children]);
}

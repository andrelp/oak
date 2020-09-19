
part of 'oak_base.dart';

abstract class OakProvider {

  //##################################
  //#                                #
  //#  Reading & Querying            #
  //#                                #
  //##################################

  /// Retrieves data from a node in the database tree.
  /// 
  /// [path] must be a absolute path to a single node.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The future may _resolve_ with a [DatabaseException] if retrieval fails.
  Future<NodeSnapshot> get(String path);


  /// Retrieves data from a node in the database tree and watches for any changes.
  /// 
  /// The first snapshot is fired immediately. Subsequently a snapshot is fired every time
  /// - the node is created (when node at the requested path did not exist previously)
  /// - the node is replaced (changed)
  /// - the node is a document or a map and some descendant node is replaced/created/deleted, excluding all document- and collection-subtrees (but including the document and collection descendants themselves)
  /// - the node is deleted
  /// - the normalization of the requested path changes (e.g. because a value of a cross reference was changed)
  /// 
  /// [path] must be a absolute path to a single node.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The stream may _dispatch_ a [DatabaseException] if retrieval fails at some point.
  Stream<NodeSnapshot> watch(String path);

  /// Queries the database tree.
  /// 
  /// [path] must be a absolute (multi-)path.
  /// [filter] may be null or any scheme a node must pass in order to
  /// be included in the query.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// The future may _resolve_ with a [DatabaseException] if querying fails.
  Future<QuerySnapshot> query(String path, [Schema filterSchema]);

  /// Queries the database tree and watches for any changes.
  /// 
  /// The first snapshot is fired immediately 
  /// and subsequently every time the set of nodes included in this query changes, a node included in the query is modified or
  /// some descendant node of a document included in the query is replaced/created/deleted, excluding all document- and collection-subtrees (but including the document and collection descendants themselves)
  /// 
  /// [path] must be a absolute (multi-)path.
  /// [filter] may be null or any scheme a node must pass in order to
  /// be included in the query.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// The stream may _dispatch_ a [DatabaseException] if querying fails at some point.
  Stream<QuerySnapshot> watchQuery(String path, [Schema filter]);

  //##################################
  //#                                #
  //#  Writing & Updating            #
  //#                                #
  //##################################

  /// Writes data in the tree database.
  /// It creates,deletes or replaces a sub-tree of the database-tree located at [path].
  /// 
  /// It will override or create the node at [path] with the new data,
  /// deleting the node, if [data] is `null`.
  /// 
  /// The type od [data] may be one of the following:
  /// - `null`. This will delete the node and has no effect, if it previously did not exist.
  /// - [String],[int],[double],[bool],[NodeReference]. This will create a leaf node with the corresponding data/reference.
  /// - [BlobReference]. This will create a leaf node with the blob reference. If the blob however does not exist, the future will resolve with an [BlobDoesNotExistError] and no changes to the database will be made.
  /// - [BlobData]. If an instance of [BlobData] is given to the database, it will write the given data to it, assign it a unique id and save the corresponding blob reference to the node.
  /// - [List] with [String],[int],[double],[bool],[NodeReference],[BlobReference] and [BlobData] entries.
  /// - [Map] with [String] keys and arbitrary entries of type listed here. `null` entries will be ignored.
  /// - [DocumentData]. To create a new document, an instance of [DocumentData] is passed to this function. The behavior is essentially the same as for [Map] parameters with the only difference being, that the new node will be marked as an document and not as an map.
  /// - [CollectionData]. Will create a new collection nodes with given child documents.
  /// 
  /// If the [data] does not match one of the types above, an [UnsupportedDataError] will be thrown.
  /// All the child node names, which are not a syntactically correct path component, and their values as defined in an instance of either [Map],[DocumentData] or [CollectionData] will be ignored.
  /// 
  /// If the new data would violate the database scheme, the future resolves
  /// with [DatabaseSchemaViolationException] and the write request is discarded.
  /// 
  /// If the parent node to the node at [path] does not exist, the data cant be written
  /// and the future resolves with an [ParentNodeDoesNotExistException].
  /// 
  /// [path] must be a absolute path to a single node.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The future may _resolve_ with a [DatabaseException] if writing to the database fails.
  Future<void> set(String path, dynamic data);

  /// Deletes data from the database.
  /// It deleted the node located at [path].
  /// 
  /// if the node or a part of its path do not exist, nothing happens.
  /// 
  /// [path] must be a absolute path to a single node.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The future may _resolve_ with a [DatabaseException] if writing to the database fails.
  Future<void> delete(String path) => set(path,null);

  /// Embeds the data in the sub-tree at [path], so that the tree is minimally modified.
  /// 
  /// Allowed data types are the same as for [OakProvider.set] but used differently:
  /// - if no node exist at [path] or if [data] is `null` or an instance of [String],[int],[double],[bool],[NodeReference],[BlobReference],[BlobData] or [List] it will behave exactly as [OakProvider.set].
  /// - If [data] is an instance of [Map] it will do the following:
  ///   * If the node does not exist or is not a Map, behave exactly as [OakProvider.set], otherwise:
  ///   * delete all child nodes for which there is a null entry in the map
  ///   * update all child nodes of the map for which there is a non-`null` entry in the map with the same procedure as listed here.
  /// - If [data] is an instance of [DocumentData] or [CollectionData] it will behave analog to the [Map] case (deleting `null` entries and updating children)
  /// 
  /// If the [data] does not match one of the types above, an [UnsupportedDataError] will be thrown.
  /// All the child node names, which are not a syntactically correct path component, and their values as defined in an instance of either [Map],[DocumentData] or [CollectionData] will be ignored.
  /// 
  /// If the new data would violate the database scheme, the future resolves
  /// with [DatabaseSchemaViolationException] and the write request is discarded.
  /// 
  /// If the parent node to the node at [path] does not exist, the data cant be written
  /// and the future resolves with an [ParentNodeDoesNotExistException].
  /// 
  /// [path] must be a absolute path to a single node.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a relative, then a [PathNoContext] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The future may _resolve_ with a [DatabaseException] if writing to the database fails.
  Future<void> update(String path, dynamic data);

}

/// This error is thrown, when data of unsupported type is being written to the database.
/// In that case, the update or write will fail.
class UnsupportedDataError extends Error {}

/// This exception is thrown, when data is written to the database and not only 
/// the requested node does not exist (yet), but also its parent node.
class ParentNodeDoesNotExistException implements Exception {}

/// This Error is thrown if a reference to a non existing blob is written to the database.
class BlobDoesNotExistError extends Error {
  /// Blob which does not exist.
  final BlobReference reference;
  BlobDoesNotExistError(this.reference);
}

/// This exception is thrown, when a write or update action to the database
/// would violate the schema of the database. The Action is discarded and this exception thrown.
/// 
/// This exception is also thrown, when the database schema is changed,
/// i.e. the predefined classes, and some nodes in the database tree
/// violate the new database schema.
class DatabaseSchemaViolationException implements Exception {
  /// normalized path to the violating node
  final NodeReference violater;

  DatabaseSchemaViolationException(this.violater);
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

abstract class OakDatabase extends OakProvider {

  //##################################
  //#                                #
  //#  Classes                       #
  //#                                #
  //##################################

  /// Saves predefined schemata to the database.
  /// 
  /// The database may define predefined schemata with associated names.
  /// They may be referenced in query filter and other class schemata, including themselves,
  /// via [ClassSchema]. A node passes schema test `ClassSchema('MySchema')`
  /// if and only if it passes the predefined schema `classes['MySchema']` in
  /// the given parameter [classes]. If the class does not exist, it passes as well.
  /// 
  /// One may define for example a class for a person who is friends with other persons as such:
  /// ```
  ///  classes['Person'] = DocumentSchema(
  ///    path: NodeReference.parse('/persons/~'),
  ///    schema: {
  ///      'name': StringSchema(),
  ///      'friends': ListSchema(
  ///         elementSchema: ReferenceSchema(
  ///           referentSchema: ClassSchema('Person')
  ///         )
  ///       ),
  ///     }
  ///   );
  /// ```
  /// 
  /// A class named 'Root' is always automatically applied to the root document, if it exist.
  /// From this the whole schema of the database follows.
  /// If the system of classes is changed, it may occur, that the data in the
  /// database no longer fits the predefined schemata. 
  /// [transitionTransactionHandler] can be used as a transaction handler similarly
  /// to a transaction handler of [runTransaction]. During the transaction all type checks during writing
  /// to or updating of the database are ignored and only applied after the transaction has finished.
  /// If [deleteViolatingNodes] is `true`, all nodes which violate the new database schematics
  /// will be deleted. if [deleteViolatingNodes] is `true` and the root node had to be deleted or if [deleteViolatingNodes] is `false` and there exist some node
  /// (after the transition transaction has finished) which (still) violates the new class
  /// system, this function will fail, resolve with a [DatabaseSchemaViolationException]. The transaction will be rolled back
  /// and the classes will not be changed, so that no changes to the database were made.
  /// 
  /// The future may resolve with a [DatabaseException].
  Future<void> setDatabaseSchema(Map<String,Schema> classes, {Function(OakProvider) transitionTransactionHandler, bool deleteViolatingNodes=false});

  /// Reads the predefined classes and the database schema from the database.
  /// 
  /// The future may resolve with a [DatabaseException].
  Future<Map<String,Schema>> getDatabaseSchema();


  //##################################
  //#                                #
  //#  Transaction                   #
  //#                                #
  //##################################

  /// Runs an atomic operation on the database.
  /// 
  /// The [transactionHandler] is given an [OakProvider] which can be used 
  /// to modify the database. The database is not modified in any way other
  /// then by the [transactionHandler] during its execution.
  /// 
  /// If one of the database actions executed by the [transactionHandler]
  /// using the provided [OakProvider] fails, all previous changes to the
  /// database by the [transactionHandler] will be rolled back and the 
  /// transaction resolves with an error.
  Future<void> runTransaction(Function(OakProvider) transactionHandler);

}




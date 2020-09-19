
part of 'oak_base.dart';

//TODO: Documentation
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
  /// - [ListData]. This will update the list node children. If the node at [path] is not a list or does not exist, it will be created as a list node with entries from [ListData.add]. If the list node already exists, it will not be marked as replaced.
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
  /// If the parent node to the node at [path] does not exist, the data can't be written
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
  /// - if no node exist at [path] or if [data] is `null` or an instance of [String],[int],[double],[bool],[NodeReference],[BlobReference],[BlobData],[ListData] or [List] it will behave exactly as [OakProvider.set].
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


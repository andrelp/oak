part of 'oak_base.dart';

//TODO: documentation
abstract class OakDatabase extends OakProvider {

  //##################################
  //#                                #
  //#  Watch                         #
  //#                                #
  //##################################

  /// Retrieves data from a node in the database tree and watches for any changes.
  /// 
  /// The first snapshot is fired immediately. Subsequently a snapshot is fired every time
  /// - the node is created (when node at the requested path did not exist previously)
  /// - the node is replaced (changed)
  /// - the node is a document or a map and some descendant node is replaced/created/deleted, excluding all document- and collection-subtrees (but including the document and collection descendants themselves)
  /// - the node is deleted
  /// - the normalization of the requested path changes (e.g. because a value of a cross reference was changed)
  /// 
  /// [path] may not be a multi-path
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// If [path] is a multi path, [InvalidUseOfMultiPath] error is thrown.
  /// The stream may _dispatch_ a [DatabaseException] if retrieval fails at some point.
  Stream<NodeSnapshot> watch(String path);

  /// Queries the database tree and watches for any changes.
  /// 
  /// The first snapshot is fired immediately 
  /// and subsequently every time the set of nodes included in this query changes, a node included in the query is modified or
  /// some descendant node of a document included in the query is replaced/created/deleted, excluding all document- and collection-subtrees (but including the document and collection descendants themselves)
  /// 
  /// [path] must be a (multi-)path.
  /// [filterSchema] may be null or any scheme a node must pass in order to
  /// be included in the query.
  /// If [path] is syntactically wrong, [InvalidPathSyntax] error is thrown.
  /// The stream may _dispatch_ a [DatabaseException] if querying fails at some point.
  Stream<QuerySnapshot> watchQuery(String path, [Schema filterSchema]);

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
  /// if the database violates the new class system after the transaction, this function will fail, resolve with a [DatabaseSchemaViolationException]
  /// and all changes will be rolled back.
  /// 
  /// The future may resolve with a [DatabaseException].
  Future<void> setDatabaseSchema(Map<String,Schema> classes, {TransactionHandler transitionTransactionHandler});

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
  /// During the transaction all type checks during writing
  /// to or updating of the database are ignored and only applied after the transaction has finished.
  /// if the database schema is violated after the transaction, this function will fail, resolve with a [DatabaseSchemaViolationException]
  /// and all changes will be rolled back.
  /// 
  /// If one of the database actions executed by the [transactionHandler]
  /// using the provided [OakProvider] fails, all previous changes to the
  /// database by the [transactionHandler] will be rolled back and the 
  /// transaction resolves with an error.
  /// 
  /// The future may resolve with a [DatabaseException].
  Future<void> runTransaction(TransactionHandler transactionHandler);

  //##################################
  //#                                #
  //#  Cloning & encoding            #
  //#                                #
  //##################################

  /// Reads a blob from the database
  /// 
  /// It future resolves with a [BlobDoesNotExistError], if the blob does not exist.
  /// The future may resolve with a [DatabaseException].
  Future<Uint8List> readBlob(BlobReference reference);

  //##################################
  //#                                #
  //#  encoding                      #
  //#                                #
  //##################################

  //TODO: documentation

  Future<Uint8List> encodeDatabase();
  

}


/// executes the atomic database operation of an transaction given an [OakProvider] instance
typedef TransactionHandler(OakProvider provider);
part of 'oak_base.dart';

//TODO: documentation
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



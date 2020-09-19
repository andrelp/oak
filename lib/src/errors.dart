part of 'oak_base.dart';


/// The database may resolve a `Future` with this exception if it
/// could not fullfil an requested action on the database.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
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
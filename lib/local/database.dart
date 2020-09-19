
part of 'local_base.dart';

class _LocalOakDatabaseProvider extends OakProvider {
  /// if transaction id is `null`, this provider dispatches
  /// actions not in the context of a transaction. 
  final dynamic transactionID;


  _LocalOakDatabaseProvider({this.transactionID});
  

  Future<NodeSnapshot> get(String path) {

  }

  Stream<NodeSnapshot> watch(String path) {

  }

  Future<QuerySnapshot> query(String path, [Schema filterSchema]) {

  }

  Stream<QuerySnapshot> watchQuery(String path, [Schema filter]) {

  }

  Future<void> set(String path, dynamic data) {

  }
  
  Future<void> update(String path, dynamic data) {

  }

}

class _LocalOakActionHandler {

}

class LocalOakDatabase extends _LocalOakDatabaseProvider implements OakDatabase {

  LocalOakDatabase.empty();
  LocalOakDatabase.decode(Uint8List encodedDatabase);



  Future<void> setDatabaseSchema(Map<String,Schema> classes, {Function(OakProvider) transitionTransactionHandler, bool deleteViolatingNodes=false}) {

  }

  Future<Map<String,Schema>> getDatabaseSchema() {

  }

  Future<void> runTransaction(Function(OakProvider) transactionHandler) {

  }

  Future<Uint8List> readBlob(BlobReference reference) {

  }

  Future<Uint8List> encodeDatabase() {

  }

}
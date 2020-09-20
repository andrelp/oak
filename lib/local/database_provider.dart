
part of 'local_base.dart';

class _LocalOakDatabaseProvider extends OakProvider {
  /// if transaction id is `null`, this provider dispatches
  /// actions not in the context of a transaction. 
  final dynamic transactionID;
  final _Backbone _backbone;

  _LocalOakDatabaseProvider(this._backbone, {this.transactionID});
  
  @override
  Future<NodeSnapshot> get(String path) {
    var reference = NodeReference.parse(path);
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    var completer = Completer<NodeSnapshot>();
    var action = _Action(
      type: _ActionType.Get,
      completer: completer,
      reference: reference,
      transactionID: transactionID
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  @override
  Future<QuerySnapshot> query(String path, [Schema filterSchema]) {
    var reference = NodeReference.parse(path);
    var completer = Completer<QuerySnapshot>();
    var action = _Action(
      type: _ActionType.Query,
      completer: completer,
      reference: reference,
      filterSchema: filterSchema,
      transactionID: transactionID
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  @override
  Future<void> set(String path, dynamic data) {
    var reference = NodeReference.parse(path);
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    var completer = Completer<void>();
    var action = _Action(
      type: _ActionType.Set,
      completer: completer,
      reference: reference,
      data: data,
      transactionID: transactionID
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }
  
  @override
  Future<void> update(String path, dynamic data) {
    var reference = NodeReference.parse(path);
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    var completer = Completer<void>();
    var action = _Action(
      type: _ActionType.Update,
      completer: completer,
      reference: reference,
      data: data,
      transactionID: transactionID
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

}

class LocalOakDatabase extends _LocalOakDatabaseProvider implements OakDatabase {


  LocalOakDatabase.empty() : super(_Backbone());
  LocalOakDatabase.decode(Uint8List encodedDatabase) : super(_Backbone());

  @override
  Stream<NodeSnapshot> watch(String path) {
    var reference = NodeReference.parse(path);
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    var streamController = StreamController<NodeSnapshot>();
    var action = _Action(
      type: _ActionType.Watch,
      streamController: streamController,
      reference: reference,
    );
    _backbone.dispatchAction(action);
    return streamController.stream;
  }

  @override
  Stream<QuerySnapshot> watchQuery(String path, [Schema filterSchema]) {
    var reference = NodeReference.parse(path);
    var streamController = StreamController<QuerySnapshot>();
    var action = _Action(
      type: _ActionType.WatchQuery,
      streamController: streamController,
      reference: reference,
      filterSchema: filterSchema,
    );
    _backbone.dispatchAction(action);
    return streamController.stream;
  }
  
  Future<void> setDatabaseSchema(Map<String,Schema> classes, {TransactionHandler transitionTransactionHandler}) {
    var completer = Completer<void>();
    classes = Map<String,Schema>.unmodifiable(classes??{});
    var action = _Action(
      type: _ActionType.SetDatabaseSchema,
      completer: completer,
      classes: classes,
      transactionHandler: transitionTransactionHandler
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  Future<Map<String,Schema>> getDatabaseSchema() {
    var completer = Completer<Map<String,Schema>>();
    var action = _Action(
      type: _ActionType.GetDatabaseSchema,
      completer: completer
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  Future<void> runTransaction(TransactionHandler transactionHandler) {
    if (transactionHandler==null) throw NullThrownError();
    var completer = Completer<void>();
    var action = _Action(
      type: _ActionType.Transaction,
      completer: completer,
      transactionHandler: transactionHandler
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  Future<Uint8List> readBlob(BlobReference reference) {
    if (reference==null) throw NullThrownError();
    var completer = Completer<Uint8List>();
    var action = _Action(
      type: _ActionType.ReadBlob,
      completer: completer,
      blobReference: reference
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

  Future<Uint8List> encodeDatabase() {
    var completer = Completer<Uint8List>();
    var action = _Action(
      type: _ActionType.EncodeDatabase,
      completer: completer,
    );
    _backbone.dispatchAction(action);
    return completer.future;
  }

}
part of 'local_base.dart';


enum _ActionType {
  Get,Watch,Query,WatchQuery,
  Set,Update,
  Transaction,
  GetDatabaseSchema,SetDatabaseSchema,
  EncodeDatabase,
  ReadBlob
}

class _Action {
  final _ActionType type;
  /// required argument for [_ActionType.Get],[_ActionType.Watch],[_ActionType.Query],
  /// [_ActionType.WatchQuery],[_ActionType.Set] and [_ActionType.Update].
  /// Is guaranteed not to be a multi-path when [type] is [_ActionType.Get],
  /// [_ActionType.Watch],[_ActionType.Set] and [_ActionType.Update]
  final NodeReference reference;
  /// optional argument for [_ActionType.Query],[_ActionType.WatchQuery]
  final Schema filterSchema;
  /// optional argument for [_ActionType.Set],[_ActionType.Update]
  final dynamic data;
  /// required argument for [_ActionType.SetDatabaseSchema]
  final Map<String,Schema> classes;
  /// required argument for [_ActionType.SetDatabaseSchema]
  final bool deleteViolatingNodes;
  /// optional argument for [_ActionType.SetDatabaseSchema]
  /// and required argument for [_ActionType.Transaction]
  final TransactionHandler transactionHandler;
  /// required argument for [_ActionType.ReadBlob]
  final BlobReference blobReference;
  /// required argument for get,watch,query,watchQuery,set,update
  /// May be null if action is executed outside a transaction
  final String transactionID;
  /// required for every action except [_ActionType.Watch],[_ActionType.WatchQuery]
  final Completer completer;
  /// required for [_ActionType.Watch],[_ActionType.WatchQuery]
  final StreamController streamController;
  const _Action({this.type,this.reference,this.filterSchema,this.data,this.classes,this.deleteViolatingNodes,this.blobReference,this.completer,this.transactionHandler,this.transactionID,this.streamController});
}


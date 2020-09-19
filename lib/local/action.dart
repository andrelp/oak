

import 'dart:async';

import 'package:oak/base/oak_base.dart';

enum _ActionType {
  Get,Watch,Query,WatchQuery,
  Set,Update,
  Transaction,
  GetDatabaseSchema,SetDatabaseSchema,
  EncodeDatabase
}

class _Action {
  final _ActionType type;
  final NodeReference path;
  final Schema filterSchema;
  final dynamic data;
  final Map<String,Schema> classes;
  final bool deleteViolatingNodes;
  final TransactionHandler transactionHandler;
  final BlobReference blobReference;
  final String transactionID;
  final Completer completer;
  const _Action({this.type,this.path,this.filterSchema,this.data,this.classes,this.deleteViolatingNodes,this.blobReference,this.completer,this.transactionHandler,this.transactionID});
}

/*
possible database actions:
- get
- watch
- query
- watchQuery
- set
- update
- transaction
- getDatabaseSchema
- setDatabaseSchema
- encodeDatabase
*/












/*
1) execute write action on database by using "temp" children
2) Check for schema violation
3) roll back if neccessary
4) integrate change in DB and mark each *replaced* node as modified and each document or map node as modified for which one of their descendants was created, replaced or deleted
5) redo every query and get which has a watch open and fire event if neccessary
6) unmark every node.

*/



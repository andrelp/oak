part of 'local_base.dart';

class _Backbone {

  final StreamController<_Action> _actionQueueController = StreamController();
  _DBTree _tree;

  _Backbone() {
    _executeActionQueue();
  }

  void dispatchAction(_Action action) {
    if (action.transactionID==null) {
      _actionQueueController.add(action);
    } else {
      //TODO: add to transaction specific queue
    }
  }


  Future<void> _executeActionQueue() async {
    await for (var action in _actionQueueController.stream) {
      switch (action.type) {
        
        case _ActionType.Get:
          _executeGetAction(action);
          break;
        case _ActionType.Watch:
          // TODO: Handle this case.
          break;
        case _ActionType.Query:
          // TODO: Handle this case.
          break;
        case _ActionType.WatchQuery:
          // TODO: Handle this case.
          break;
        case _ActionType.Set:
          // TODO: Handle this case.
          break;
        case _ActionType.Update:
          // TODO: Handle this case.
          break;
        case _ActionType.Transaction:
          // TODO: Handle this case.
          break;
        case _ActionType.GetDatabaseSchema:
          // TODO: Handle this case.
          break;
        case _ActionType.SetDatabaseSchema:
          // TODO: Handle this case.
          break;
        case _ActionType.EncodeDatabase:
          // TODO: Handle this case.
          break;
        case _ActionType.ReadBlob:
          // TODO: Handle this case.
          break;
      }
    }
  }

  void _executeGetAction(_Action action) {
    var node  = _tree.locateNode(action.reference);
    if (node==null) {
      action.completer.complete(NodeSnapshot.doesNotExist(action.reference));
    } else {
      var value = _tree.extractValue(node);
      var snap  = NodeSnapshot(action.reference, node.normalizedPath, node.type, value);
      action.completer.complete(snap);
    }
  }

}

/*

Write algorithm:

1) Do write to database tree using tempChildren. 
   While doing that create a set of normalized paths of
    - updatedDocuments    (child created/replaces/deleted)
    - updatedCollections  (child document added/removed)
    - modifiedNodes       (node is created/deleted/changed)
  Put a node in updatedDocuments or updatedCollections only if it
  isn't already in modifiedNodes (if a child changes), because in that
  case the document/collection fow which a child has changed is already
  a replacement of the original document.
  If a document or collection node is created/deleted/changed remove it
  from the updatedDocuments and updatedCollections lists and put it in modified list;
  before you replace the node, roll back all changes to the node and remove corresponding entries 
  from modifiedNodes.
  The nodes with changed tempChildren parameter are prefixPaths of nodes listed in modified nodes.

2) Check for schema violation, roll back if necessary
3) Integrate change in database and set tempChildren to null.
4) Alert watches:
    - (non-query) watches: If a path or a prefix of the path of a (reference) node used
      for normalizing target path is in modifiedNodes, dispatch next snap. Otherwise 
      dispatch if the normalized target is in updatedDocuments,updatedCollections or in 
      modifiedNodes.
    - query-watches: Just redo the query. 


For every watch snapshot save
1) set of normalized paths to reference-nodes used to normalize request path
2) normalized target path

For every query watch snapshot save
1) set of normalized paths of every included node in the snap

 */
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
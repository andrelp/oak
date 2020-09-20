part of 'local_base.dart';

class _Backbone {

  final StreamController<_Action> actionQueueController = StreamController();
  final Map<String,StreamController<_Action>> transactionQueueController = {};
  final Set<_Watch> watches = {};
  final Set<_QueryWatch> queryWatches = {};
  Map<String,Schema> classes;

  Set<NodeReference> tmpUpdatedDocuments;
  Set<NodeReference> tmpUpdatedCollections;
  Set<NodeReference> tmpReplacedNodes;
  _Node temporarilyReplacedRoot;

  _DBTree _tree;

  _Backbone() {
    _tree = _DBTree(_DocumentNode(null, NodeReference.root, {}));
    _executeActionQueue();
  }

  void dispatchAction(_Action action) {
    if (action.transactionID==null) {
      actionQueueController.add(action);
    } else {
      if (transactionQueueController.containsKey(action.transactionID)) {
        transactionQueueController[action.transactionID].add(action);
      } else {
        var err = DatabaseException('No open transaction with id "${action.transactionID}".');
        action.completer?.completeError(err);
        action.streamController?.addError(err);
        action.streamController?.close();
      }
    }
  }

  Future<void> _executeActionQueue() async {
    await for (var action in actionQueueController.stream) {
      tmpUpdatedDocuments = {};
      tmpUpdatedCollections = {};
      tmpReplacedNodes = {};
      temporarilyReplacedRoot = null;

      bool isWriteAction=false;

      switch (action.type) {
        case _ActionType.Get:
          _executeGet(action);
          break;
        case _ActionType.Watch:
          _executeWatch(action);
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

      if (isWriteAction) {

        bool violated

      }


    }
  }

  /// rolls back replaced nodes to their position
  void rollBack(_Node node) {
    if (node.normalizedPath.isRootPath) {
      _tree.root = temporarilyReplacedRoot;
      temporarilyReplacedRoot=null;
    } else {
      
    }
  }

  Set<_Node> query(NodeReference ref, Schema filter) {
    var nodes = _tree.resolveMultiPath(ref);
    nodes.retainWhere((element) => _tree.fitSchema(element, filter??DynamicSchema(), classes));
    
  }

  void _executeGet(_Action action) {
    var node = _tree.locateNode(action.reference);
    if (node==null) {
      action.completer.complete(NodeSnapshot.doesNotExist(action.reference));
    } else {
      var value = _tree.extractValue(node);
      var snap  = NodeSnapshot(action.reference, node.normalizedPath, node.type, value);
      action.completer.complete(snap);
    }
  }

  void _executeWatch(_Action action) {
    var node_references = _tree.locateNodeAndReturnReferences(action.reference);
    var node = node_references[0];
    NodeSnapshot snap;
    NodeReference normalizedTarget;
    if (node==null) {
      snap = NodeSnapshot.doesNotExist(action.reference);
    } else {
      var value = _tree.extractValue(node);
      snap  = NodeSnapshot(action.reference, node.normalizedPath, node.type, value);
      normalizedTarget=node.normalizedPath;
    }
    action.streamController.add(snap);
    var watch = _Watch(action.reference, action.streamController);
    watch.normalizedTarget=normalizedTarget;
    watch.usedReferenceNodes=node_references[1];
    watches.add(watch);
  }

}

class _Watch {
  final NodeReference requestReference;
  final StreamController<NodeSnapshot> controller;
  /// null if target does not exist
  NodeReference normalizedTarget;
  /// normalized paths to all references used
  Set<NodeReference> usedReferenceNodes;
  _Watch(this.requestReference,this.controller);
}

class _QueryWatch {
  final NodeReference requestReference;
  final Schema filterSchema;
  Set<NodeReference> lastIncluded;
  _QueryWatch(this.requestReference,this.filterSchema);
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
  from modifiedNodes. (there should be no modified child of a modified node)
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





/// A person A can only consider person B a friend, if they have one hobby in common.
/// and if a person A is married to person B, so must person B be married to person A.
var personClass =  AndSchema([
  NodeVariable("spouse"),
  PathSchema(NodeReference.parse('/persons/~')),
  DocumentSchema(
    mustMatchFieldsExactly: true,
    schema: {
      'name': StringSchema(),
      'hobbies': ListSchema(
        every: StringSchema(),
        any: ValueVariable("common hobby")
      ),
      'fiends': ListSchema(
        every: ReferenceSchema(
          referentSchema: ClassSchema("Person")
        ),
        any: ReferenceSchema(
          referentSchema: DocumentSchema(
            mustMatchFieldsExactly: false,
            schema: {
              'hobbies': ListSchema(
                any: ValueVariable("common hobby")
              ),
            }
          )
        )
      ),
      'spouse': NullableSchema(ReferenceSchema(
        referentSchema: AndSchema([
          ClassSchema("Person"),
          DocumentSchema(
            mustMatchFieldsExactly: false,
            schema: {
              'spouse': ReferenceSchema(
                referentSchema: NodeVariable("spouse")
              )
            }
          ) 
        ])
      ))
    }
  )
]);




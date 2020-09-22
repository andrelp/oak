part of 'local_base.dart';

class _Backbone {

  final StreamController<_Action> actionQueueController = StreamController();
  final Map<String,StreamController<_Action>> transactionQueueController = {};
  final Set<_Watch> watches = {};
  final Set<_QueryWatch> queryWatches = {};
  
  Set<_Node> tmpReplacedNodes; // set of all nodes which where replaced in the tree. Should always be prefix free. roll back changed to children if necessary
  Map<String,Set<_LeafNode<BlobReference>>> tmpBlobReferences; //copy of blobReferences with applied actions
  Map<String,Uint8List> tmpBlobs; // contains only temp changes and new temp blobs.

  _DBTree _tree;
  Map<String,Schema> classes;
  Map<String,Uint8List> blobs;
  Map<String,Set<_LeafNode<BlobReference>>> blobReferences;
  

  _Backbone() {
    _tree = _DBTree(_DocumentNode(null, NodeReference.root, {}));

    //set all variables indicate changes in the database tree
    tmpReplacedNodes = {};
    tmpBlobReferences = blobReferences.map((key, value) => MapEntry(key,Set<_LeafNode<BlobReference>>.of(value))); //makes copy
    tmpBlobs = {};

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
      
      bool isWriteAction=false;

      switch (action.type) {
        case _ActionType.Get:
          _executeGet(action);
          break;
        case _ActionType.Watch:
          _executeWatch(action);
          break;
        case _ActionType.Query:
          _executeQuery(action);
          break;
        case _ActionType.WatchQuery:
          _executeQueryWatch(action);
          break;
        case _ActionType.Set:
          // TODO: Handle this case.
          isWriteAction=true;
          break;
        case _ActionType.Update:
          // TODO: Handle this case.
          isWriteAction=true;
          break;
        case _ActionType.Transaction:
          // TODO: Handle this case.
          isWriteAction=true;
          break;
        case _ActionType.GetDatabaseSchema:
          _executeGetDatabaseSchema(action);
          break;
        case _ActionType.SetDatabaseSchema:
          // TODO: Handle this case.
          isWriteAction=true;
          break;
        case _ActionType.EncodeDatabase:
          // TODO: Handle this case.
          break;
        case _ActionType.ReadBlob:
          _executeReadBlob(action);
          break;
      }

      if (isWriteAction) {
        var classSystem = action.classes??classes;
        if (classes.containsKey('Root') && !_tree.fitSchema(_tree.root, classSystem['Root'], classSystem)) {
          
          

        } else {
          // integrate blob changes:
          blobReferences=tmpBlobReferences;
          blobReferences.removeWhere((ref,nodes) => nodes==null||nodes.isEmpty);
          tmpBlobs.forEach((ref, data) {
            blobs[ref]=data;
          });
          blobs.removeWhere((ref,_) => !blobReferences.containsKey(ref));

          // integrate new class system
          if (action.classes!=null) classes=action.classes;

          // integrate changes to the nodes
          var parents = tmpReplacedNodes.map((n) => n.parentNode).toSet()..remove(null);
          parents.forEach((n) {
            if (n is _NamedBranchNode) {
              n.children=n.actionChildren;
            } else if (n is _ListNode) {
              n.children=n.actionChildren;
            } else {
              assert(false);
            }
          });
          
          var parentDocs = tmpReplacedNodes.map((n) => _tree.findYoungestDocumentAncestor(n)).toSet()..remove(null);
          var parentCols = tmpReplacedNodes.map((n) => _tree.findYoungestCollectionAncestor(n)).toSet()..remove(null);

          // alarm watches

          watches.forEach((watch) {
            if (watch.controller.isClosed) {
              watches.remove(watch);
            } else {
              var node = _tree.locateNode(watch.requestReference);
              if  (node?.normalizedPath!=watch.normalizedTarget || ((watch.normalizedTarget!=null) &&
                 ((watch.normalizedTarget!=null&&tmpReplacedNodes.any((repl) => repl.normalizedPath.isPrefixPathOf(watch.normalizedTarget)))
                ||(parentDocs.any((doc) => doc.normalizedPath==watch.normalizedTarget))
                ||(parentCols.any((col) => col.normalizedPath==watch.normalizedTarget))))) {
                watch.normalizedTarget=node?.normalizedPath;
                var value = node==null?null:_tree.extractValue(node);
                var snap  = NodeSnapshot(watch.requestReference, node?.normalizedPath, node?.type, value);
                watch.controller.add(snap);
              }
            }
          });
          
          queryWatches.forEach((watch) {
            if (watch.controller.isClosed) {
              queryWatches.remove(watch);
            } else {
              var nodes = _tree.resolveMultiPath(watch.requestReference);
              nodes.retainWhere((element) => _tree.fitSchema(element, watch.filterSchema??DynamicSchema(), classes));
              var snapshots = List<NodeSnapshot>.unmodifiable(nodes.map((n) => NodeSnapshot(watch.requestReference, n.normalizedPath, n.type, _tree.extractValue(n))));
              var added = List<NodeSnapshot>.unmodifiable(snapshots.where((s) => !watch.lastIncluded.contains(s.normalizedReference)));
              var removed = <NodeSnapshot>[];
              watch.lastIncluded.where((l) => !nodes.any((n) => n.normalizedPath==l)).forEach((li) {
                var n = _tree.locateNode(li);
                var value = n==null?null:_tree.extractValue(n);
                removed.add(NodeSnapshot(watch.requestReference, li, n?.type, value));
              });
              removed = List<NodeSnapshot>.unmodifiable(removed);
              var modified = List<NodeSnapshot>.unmodifiable(snapshots.where((s) => watch.lastIncluded.contains(s.normalizedReference) && 
                  (tmpReplacedNodes.any((repl) => repl.normalizedPath.isPrefixPathOf(s.normalizedReference)))
                ||(parentDocs.any((doc) => doc.normalizedPath==s.normalizedReference))
                ||(parentCols.any((col) => col.normalizedPath==s.normalizedReference))
              ));
              var querySnapshot = QuerySnapshot(snapshots, added, modified, removed);
              watch.controller.add(querySnapshot);
              watch.lastIncluded=nodes.map((n) => n.normalizedPath).toSet();
            }
          });
          
        }

        //reset all variables indicate changes in the database tree
        tmpReplacedNodes = {};
        tmpBlobReferences = blobReferences.map((key, value) => MapEntry(key,Set<_LeafNode<BlobReference>>.of(value))); //makes copy
        tmpBlobs = {};

      }


    }
  }

  /// rolls back replaced nodes to their position
  /*void rollBack(_Node node) {
    if (node.normalizedPath.isRootPath) {
      _tree.root = temporarilyReplacedRoot;
      temporarilyReplacedRoot=null;
    } else {
      // roll bak any changes of children
      tmpUpdatedDocuments.removeWhere((doc) => node.normalizedPath.isPrefixPathOf(doc.normalizedPath));
      tmpUpdatedCollections.removeWhere((col) => node.normalizedPath.isPrefixPathOf(col.normalizedPath));
      var changedChildren = tmpReplacedNodes.where((n) => node.normalizedPath.isPrefixPathOf(n.normalizedPath) && n.normalizedPath!=node.normalizedPath);
      changedChildren.forEach((n) => rollBack(n));

      // redo write
      var parentDoc = _tree.findYoungestDocumentAncestor(node);
      var parentCol = _tree.findYoungestCollectionAncestor(node);
      var parent = node.parentNode;

      if (parentDoc!=null) tmpUpdatedDocuments.add(parentDoc);
      if (parentCol!=null) tmpUpdatedCollections.add(parentCol);

      if (parent == null) {

      } else

      if (parent is _ListNode) {

      } else

      if (parent is _NamedBranchNode) {
        if (parent.actionChildren==null) return;

      }

    }
  }*/


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
    var node = _tree.locateNode(action.reference);
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
    watches.add(watch);
  }

  void _executeQuery(_Action action) {
    var nodes = _tree.resolveMultiPath(action.reference);
    nodes.retainWhere((element) => _tree.fitSchema(element, action.filterSchema??DynamicSchema(), classes));
    var snaps = List<NodeSnapshot>.unmodifiable(nodes.map((n) => NodeSnapshot(action.reference, n.normalizedPath, n.type, _tree.extractValue(n))));
    var querySnap = QuerySnapshot(snaps, snaps, [], []);
    action.completer.complete(querySnap);
  }

  void _executeQueryWatch(_Action action) {
    var nodes = _tree.resolveMultiPath(action.reference);
    nodes.retainWhere((element) => _tree.fitSchema(element, action.filterSchema??DynamicSchema(), classes));
    var snaps = List<NodeSnapshot>.unmodifiable(nodes.map((n) => NodeSnapshot(action.reference, n.normalizedPath, n.type, _tree.extractValue(n))));
    var querySnap = QuerySnapshot(snaps, snaps, [], []);
    action.streamController.add(querySnap);
    var watch = _QueryWatch(action.reference,action.streamController,action.filterSchema);
    queryWatches.add(watch);
  }

  void _executeGetDatabaseSchema(_Action action) {
    var system = classes.map((key, value) => MapEntry(key, Schema.decode(value.encode())));
    action.completer.complete(system);
  }

  void _executeReadBlob(_Action action) {
    var blob = blobs[action.blobReference.id];
    if (blob==null) {
      action.completer.completeError(BlobDoesNotExistError(action.blobReference));
    } else {
      action.completer.complete(blob);
    }
  }

}

class _Watch {
  final NodeReference requestReference;
  final StreamController<NodeSnapshot> controller;
  /// null if target does not exist
  NodeReference normalizedTarget;
  _Watch(this.requestReference,this.controller);
}

class _QueryWatch {
  final NodeReference requestReference;
  final StreamController<QuerySnapshot> controller;
  final Schema filterSchema;
  Set<NodeReference> lastIncluded;
  _QueryWatch(this.requestReference,this.controller,this.filterSchema);
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




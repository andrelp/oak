



/*
possible database actions:
- get
- watch
- query
- watchQuery
- set
- update
- getDatabaseSchema
- setDatabaseSchema
- encodeDatabase
*/










/// A node in the data base tree
class _DBNode {
  _DBNode parent;
}

/// String, int, double, bool, (blob-)reference,Lists
class _DBValueNode<T> extends _DBNode {
  final T value;
  _DBValueNode(this.value);
}

class _DBMapNode extends _DBNode {
  Map<String,_DBNode> children;
  Map<String,_DBNode> tempChildren;
}

class _DBDocumentNode extends _DBNode {
  Map<String,_DBNode> children;
  Map<String,_DBNode> tempChildren;
}

class _DBCollectionNode extends _DBNode {
  Map<String,_DBNode> children;
  Map<String,_DBNode> tempChildren;
}


class _DBAction {}

class _DBGetAction {

}




/*
1) execute write action on database by using "temp" children
2) Check for schema violation
3) roll back if neccessary
4) integrate change in DB and mark each *replaced* node as modified and each document or map node as modified for which one of their descendants was created, replaced or deleted
5) redo every query and get which has a watch open and fire event if neccessary
6) unmark every node.

*/



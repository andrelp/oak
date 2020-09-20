part of 'local_base.dart';

class _DBTree {

  _DocumentNode root;

  _DBTree(this.root);

  /// Returns the node at reference. Returns null if the node does not exist
  _Node locateNode(NodeReference reference) {
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    // used to determine whether a reference points to one of its children
    var usedReferenceNodes = <String>{};
    
    _Node Function(NodeReference reference) locate;

    _Node nextNode(_Node current, String pathComponent) {
      if (current is _NamedBranchNode) {
        if (pathComponent=='.') return current;
        if (pathComponent=='..') return current.parentNode;
        return current.children[pathComponent];
      } else if (current is _LeafNode<NodeReference>) {
        if (usedReferenceNodes.contains(current.normalizedPath.path)) return null;
        usedReferenceNodes.add(current.normalizedPath.path);
        var target = locate(current.value);
        if (target==null) return null;
        return nextNode(target, pathComponent);
      } else {
        return null;
      }
    }

    locate = (reference) {
      var path = reference.pathComponents;
      _Node current = root;
      for (var pc in path) {
        current = nextNode(current, pc);
        if (current==null) return null;
      }
      return current;
    };
    
    return locate(reference);
  }

  /// Locates the parent node of the node at [reference].
  /// Returns `null` if the parent does not exist (including when the root node is at [reference])
  _Node locateParentNode(NodeReference reference) {
    if (reference.isMultiPath) throw InvalidUseOfMultiPath(reference);
    if (reference.isRootPath) return null;
    var pre = locateNode(reference.prefixPath);
    if (pre==null) return null;
    var pc  = reference.lastPathComponent;
    if (pre is _NamedBranchNode) {
      if (pc=='.') return pre.parentNode;
      if (pc=='..') return pre.parentNode?.parentNode;
      return pre;
    } else if (pre is _LeafNode<NodeReference>) {
      var target = locateNode(pre.value);
      if (target==null) return null;
      if (pc=='.') return target.parentNode;
      if (pc=='..') return target.parentNode?.parentNode;
      return target;
    } else {
      return null;
    }
  }

  dynamic extractValue(_Node node) {
    if (node==null) throw NullThrownError();

    dynamic extract(_Node node, [bool nested=true]) {
      if (node is _LeafNode) return node.value;
      if (node is _CollectionNode) {
        if (nested) return CollectionChildPlaceholder(node.normalizedPath);
        return node.children.keys.toList();
      }
      if (node is _ListNode) {
        return node.children.map((n) => extract(n)).toList();
      }
      if (node is _DocumentNode && nested) {
        return DocumentChildPlaceholder(node.normalizedPath);
      }
      if (node is _MapNode || node is _DocumentNode) {
        return (node as _NamedBranchNode).children.map<String,dynamic>(
          (key,child) => MapEntry(key, extract(child))
        );
      }
      // should never execute this.
      assert(false);
      return null;
    }

    return extract(node,false);
  }

  /// Returns the set of all nodes included in the given (multi-path)
  Set<_Node> resolveMultiPath(NodeReference reference) {

    Set<_Node> combine(Set<_Node> a, Set<_Node> b)
      => <_Node>{}..addAll(a)..addAll(b);
    
    if (reference.isCompositePath) {
      return reference.compositePathComponents.map((e) => resolveMultiPath(e)).fold(<_Node>{}, combine);
    }

    Set<_Node> Function(NodeReference reference) find;

    Set<_Node> nextNodes(_Node current, String pathComponent) {
      if (current is _NamedBranchNode) {
        if (pathComponent=='.') return <_Node>{current};
        if (pathComponent=='..') return <_Node>{current.parentNode};
        if (pathComponent=='~') return <_Node>{}..addAll(current.children.values);
        return <_Node>{current.children[pathComponent]};
      } else if (current is _LeafNode<NodeReference>) {
        var target = locateNode(current.value);
        if (target==null) return <_Node>{};
        return nextNodes(target, pathComponent);
      } else {
        return <_Node>{};
      }
    }

    find = (reference) {
      var path = reference.pathComponents;
      var current = <_Node>{root};
      for (var pc in path) {
        current = current.map((cn) => nextNodes(cn,pc)).fold(<_Node>{}, combine);
        if (current==null) return null;
      }
      return current;
    };
    
    return find(reference);
  }

  

  bool fitSchema(_Node node, Schema schema, Map<String, Schema> classes) {
    /*
    Check fot schema violation: Create a class A for the schema given and start with this node class combination:
    1) for every node,class combination that comes up, define variables E(path A,class B), meaning: node at path A satisfies the class B.
    2) Create variables Var(path A,class B,path C,String varName): while checking node at path A for class B a Value variable by the name varName is in class B.
      Var(...) is a variable if true, meaning that node at path C is in the group of nodes which values must be equal to one another
    3) Analogous create NodeVar(...)
    4) create for any pairing {A,B} of Var(...) that come up, the formula A∧B⇒C where C is either true or false (given the structure of the tree)
    5) Analogous create for every pairing of NodeVar(...) these clauses.
    6) create for every node,class comb that comes up: E(...) ⇔ X, where X is some clause depending on set of all Var(...),NodeVar(...) and E(...)
    7) combine clauses to Z(node,class) = ( ⋀(VarA∧VarB⇒VarC) ∧ ⋀(NodeA∧NodeB⇒NodeC) ∧ E(...) ⇔ X )
    8) for every E(...) variable that comes up recursively redo steps 1 through 8.
    9) Combine them Schema = ⋀Z(node,class)
    10) If Schema is solvable then hurray, the node follows the given schema.
    */
    
    // unused class name to assign [schema] a class name
    final rootClassName = classes.keys.fold<String>('', (p,e) => (e.length>p.length)?e:p) + '_';
    
    Schema getClass(String name) {
      if (name==rootClassName) return schema;
      return classes[name] ?? DynamicSchema();
    }

    final open = <_NodeClassPair>{_NodeClassPair(node, rootClassName)};
    final handled = <String>{};
    final clauses = <l.Expression>[];
    final usedVariables = <String>[]; 

    while (open.isNotEmpty) {
      final pair = open.first;
      open.remove(pair);
      if (handled.contains(pair.expressionVariableName)) continue;
      handled.add(pair.expressionVariableName);
      final schema   = getClass(pair.schemaClass);
      final node     = pair.node;
      final valVars  = <_ValueVariable>{};
      final nodeVars = <_NodeVariable>{};
      usedVariables.add(pair.expressionVariableName);

      l.Value $(bool v) => l.Value(v);
      
      l.Expression applySchema(_Node n, Schema s) {
        if (n==null && !(s is NullableSchema)) return l.Value(false);
        
        if (s is StringSchema) {
          if (n is _LeafNode<String>) {
            final v = (s.isEqualTo==null||n.value==s.isEqualTo)
            && (s.maxLength==null||n.value.length<=s.maxLength)
            && (s.minLength==null||n.value.length>=s.minLength)
            && !(s.mayBeEmpty==false&&n.value.isEmpty)
            && (s.regularExpression==null||s.regularExpression.stringMatch(n.value)==n.value)
            && (s.hasMatch==null||s.hasMatch.hasMatch(n.value));
            return $(v);
          }
          return $(false);
        }

        if (s is IntSchema) {
          if (n is _LeafNode<int>) {
            final v = (s.isEqualTo==null||n.value==s.isEqualTo)
            && (s.min==null||n.value>=s.min)
            && (s.max==null||n.value>=s.max);
            return $(v);
          }
          return $(false);
        }

        if (s is DoubleSchema) {
          if (n is _LeafNode<double>) {
            final v = (s.isEqualTo==null||n.value==s.isEqualTo)
            && (s.min==null||n.value>=s.min)
            && (s.max==null||n.value>=s.max);
            return $(v);
          }
          return $(false);
        }

        if (s is BoolSchema) {
          if (n is _LeafNode<bool>) {
            final v = (s.isEqualTo==null||n.value==s.isEqualTo);
            return $(v);
          }
          return $(false);
        }

        if (s is ReferenceSchema) {
          if (n is _LeafNode<NodeReference>) {
            if (s.referentSchema==null) return $(true);
            final target = locateNode(n.value);
            return applySchema(target, s.referentSchema);
          }
          return $(false);
        }

        if (s is BlobReferenceSchema) {
          return $(n is _LeafNode<BlobReference>);
        }

        if (s is ListSchema) {
          if (n is _ListNode) {
            children(Schema param) => (n.actionChildren??n.children).map((c) => applySchema(c, param));
            return l.and([
              if (s.every!=null)
                ...children(s.every),
              if (s.any!=null)
                l.or(children(s.any).toList(growable: false)),
              if (s.one!=null)
                l.xor(children(s.one).toList(growable: false))
            ]);
          }
          return $(false);
        }

        if (s is MapSchema) {
          if (n is _MapNode) {
            var nodeChildren   = n.actionChildren??n.children;
            var schemaChildren = s.schema??<String,Schema>{};
            if (s.mustMatchKeysExactly) {
              if (nodeChildren.keys.any((e) => !schemaChildren.containsKey(e))) return $(false);
              if (schemaChildren.keys.any((e) => !nodeChildren.containsKey(e))) return $(false);
            }
            return l.and(
              schemaChildren.entries.map((e) => applySchema(nodeChildren[e.key],e.value)).toList()
            );
          }
          return $(false);
        }

        if (s is DocumentSchema) {
          if (n is _DocumentNode) {
            var nodeChildren   = n.actionChildren??n.children;
            var schemaChildren = s.schema??<String,Schema>{};
            if (s.mustMatchFieldsExactly) {
              if (nodeChildren.keys.any((e) => !schemaChildren.containsKey(e))) return $(false);
              if (schemaChildren.keys.any((e) => !nodeChildren.containsKey(e))) return $(false);
            }
            return l.and(
              schemaChildren.entries.map((e) => applySchema(nodeChildren[e.key],e.value)).toList()
            );
          }
          return $(false);
        }

        if (s is CollectionSchema) {
          if (n is _CollectionNode) {
            if (s.childSchema==null) return $(true);
            var nodeChildren = n.actionChildren??n.children;
            return l.and(
              nodeChildren.values.map((e) => applySchema(e, s.childSchema)).toList()
            );
          }
          return $(false);
        }

        if (s is NullableSchema) {
          // s==null case handled at beginning
          if (s.childSchema==null) return $(true);
          return applySchema(n, s.childSchema);
        }

        if (s is DynamicSchema) {
          // s==null case handled at beginning
          return $(true);
        }

        if (s is PathSchema) {
          if (s.path==null) return $(true);
          return $(resolveMultiPath(s.path).contains(n));
        }

        if (s is ClassSchema) {
          if (s.name==null) return $(true);
          final pair = _NodeClassPair(n, s.name);
          open.add(pair);
        }

        if (s is ValueVariable) {
          var vv = _ValueVariable(pair, n, s.name);
          valVars.add(vv);
          return vv.expressionVariable;
        }

        if (s is NodeVariable) {
          var nv = _NodeVariable(pair, n, s.name);
          nodeVars.add(nv);
          return nv.expressionVariable;
        }
        
        if (s is AndSchema) {
          return l.and((s.schemata??<Schema>[]).map((child) => applySchema(n, child)).toList());
        }

        if (s is OrSchema) {
          return l.or((s.schemata??<Schema>[]).map((child) => applySchema(n, child)).toList());
        }

        if (s is NotSchema) {
          if (s.schema==null) return $(false);
          return l.not(applySchema(n, s.schema));
        }

        if (s is XorSchema) {
          return l.xor((s.schemata??<Schema>[]).map((child) => applySchema(n, child)).toList());
        }

        // programming error, didn't cover a schema. Should never reach that state
        assert(false);
        return null;
      }

      final valVarsL  = valVars.toList(growable: false);
      final nodeVarsL = nodeVars.toList(growable: false);
      final boundaryConditions = <l.Expression>[];

      // Add boundary conditions: if both node a and node b are assigned to the
      // same schema variable, they must hold the same data
      for (var i = 0; i < valVarsL.length; i++) {
        final a = valVarsL[i];
        usedVariables.add(a.expressionVariableName);
        for (var j = i+1; j < valVarsL.length; j++) {
          final b = valVarsL[j];
          final val = l.Value(a.target.value==b.target.value);
          boundaryConditions.add(l.ifThen(l.and([a.expressionVariable,b.expressionVariable]), val));
        }
      }

      // Add boundary conditions: if both node a and node b are assigned to the
      // same schema variable, they must hold the same data
      for (var i = 0; i < nodeVarsL.length; i++) {
        final a = nodeVarsL[i];
        usedVariables.add(a.expressionVariableName);
        for (var j = i+1; j < nodeVarsL.length; j++) {
          final b = nodeVarsL[j];
          final val = l.Value(a.target.normalizedPath==b.target.normalizedPath);
          boundaryConditions.add(l.ifThen(l.and([a.expressionVariable,b.expressionVariable]), val));
        }
      }

      // create clause for this node and class pair and add to all clauses
      var clause = l.and([
        l.iff(pair.expressionVariable, applySchema(node, schema)),
        ...boundaryConditions
      ]);

      clauses.add(clause);
    }

    // if this combined expression is true, the node fits the schema 
    final schemaExpression = l.and(clauses);
    return schemaExpression.findSolution(usedVariables)!=null;
  }

}


class _NodeClassPair {
  final _Node node;
  final String schemaClass;
  final String expressionVariableName;
  l.Variable get expressionVariable => l.Variable(expressionVariableName);
  _NodeClassPair(this.node,this.schemaClass) : expressionVariableName=node.normalizedPath.path+':#:'+schemaClass;
  @override
  bool operator==(dynamic other) => other is _NodeClassPair && other.expressionVariableName==expressionVariableName;
  @override
  int get hashCode => expressionVariableName.hashCode;
}

class _ValueVariable {
  final String variableName;
  final _LeafNode target;
  final String expressionVariableName;
  l.Variable get expressionVariable => l.Variable(expressionVariableName);
  _ValueVariable(_NodeClassPair context,this.target,this.variableName) : expressionVariableName='var:#:'+context.expressionVariableName+':#:'+target.normalizedPath.path+':#:'+variableName;

  @override
  bool operator==(dynamic other) => other is _ValueVariable && other.expressionVariableName==expressionVariableName;
  @override
  int get hashCode => expressionVariableName.hashCode;
}


class _NodeVariable {
  final String variableName;
  final _Node target;
  final String expressionVariableName;
  l.Variable get expressionVariable => l.Variable(expressionVariableName);
  _NodeVariable(_NodeClassPair context,this.target,this.variableName) : expressionVariableName='var:#:'+context.expressionVariableName+':#:'+target.normalizedPath.path+':#:'+variableName;

  @override
  bool operator==(dynamic other) => other is _NodeVariable && other.expressionVariableName==expressionVariableName;
  @override
  int get hashCode => expressionVariableName.hashCode;
}

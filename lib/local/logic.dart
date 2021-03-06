

abstract class Expression {
  bool evaluate(Map<String,bool> varValues);

  Map<String,bool> findSolution(Iterable<String> variables) {
    var vars = List<String>.from(variables);
    var init = ()=>List<bool>.generate(variables.length+1, (index) => false);
    //count binary
    void increment(List<bool> i) {
      int index;
      for (index=0; i[index]; index++) {
        i[index]=false;
      }

      i[index]=true;
    }

    for (var i = init(); !i.last; increment(i)) {
      var varValues = Map<String,bool>.fromIterables(vars, i);
      if (evaluate(varValues)) return varValues;
    }

    return null;
  }
}


class VariableNoValueError extends Error {
  final String name;
  VariableNoValueError(this.name);
}

class Variable extends Expression {
  final String name;
  Variable(this.name);
  @override
  bool evaluate(Map<String, bool> varValues) {
    var v = varValues[name];
    if (v==null) throw VariableNoValueError(name);
    return v;
  }
  @override
  String toString() {
    return 'Var[$name]'; 
  }
}

class _Not extends Expression {
  final Expression child;
  _Not(this.child);
  @override
  bool evaluate(Map<String, bool> varValues) {
    return !child.evaluate(varValues);
  }
  @override
  String toString() {
    return '¬${child.toString()}'; 
  }
}

class _And extends Expression {
  final List<Expression> children;
  _And(this.children);
  @override
  bool evaluate(Map<String, bool> varValues) {
    return children.every((e) => e.evaluate(varValues));
  }
  @override
  String toString() {
    return '(' + children.join('∧') + ')';
  }
}

class _Or extends Expression {
  final List<Expression> children;
  _Or(this.children);
  @override
  bool evaluate(Map<String, bool> varValues) {
    return children.any((e) => e.evaluate(varValues));
  }
  @override
  String toString() {
    return '(' + children.join('∨') + ')';
  }
}

class _Xor extends Expression {
  final List<Expression> children;
  _Xor(this.children);
  @override
  bool evaluate(Map<String, bool> varValues) {
    bool any = false;
    for (var c in children) {
      if (c.evaluate(varValues)) {
        if (any) return false;
        any = true;
      }
    }
    return any;
  }
  @override
  String toString() {
    return '(' + children.join('⊕') + ')';
  }
}

class _Iff extends Expression {
  Expression a;
  Expression b;
  _Iff(this.a,this.b);
  @override
  bool evaluate(Map<String, bool> varValues) {
    var va = a.evaluate(varValues);
    var vb = b.evaluate(varValues);
    return (va&&vb)||(!va&&!vb);
  }
  @override
  String toString() {
    return '(' + a.toString() + '⇔' + b.toString() + ')';
  }
}

class Value extends Expression {
  final bool value;
  Value(bool value) : this.value = value??false;
  @override
  bool evaluate(Map<String,bool> varValues) => value;
  @override
  String toString() {
    return value?'true':'false';
  }
}

Expression not(Expression child) {
  if (child is Value) return Value(!child.value);
  return _Not(child);
}

Expression and(List<Expression> children) {
  if (children.any((e) => e is Value && !e.value)) return Value(false);
  if (children.every((e) => e is Value && e.value)) return Value(true);
  return _And(children);
}

Expression or(List<Expression> children) {
  if (children.any((e) => e is Value && e.value)) return Value(true);
  if (children.every((e) => e is Value && !e.value)) return Value(false);
  return _Or(children);
}

Expression xor(List<Expression> children) {
  bool foundAlwaysTrue = false;
  for (var c in children) {
    if (c is Value && c.value) {
      if (foundAlwaysTrue) return Value(false);
      foundAlwaysTrue=true;
    }
  }
  if (!foundAlwaysTrue && children.every((e) => e is Value && !e.value)) return Value(false);
  return _Xor(children);
}

Expression ifThen(Expression a, Expression b) {
  return or([not(a),b]);
}

Expression iff(Expression a, Expression b) {
  if (a is Value) {
    if (a.value) return b;
    return not(b);
  }
  if (b is Value) {
    if (b.value) return a;
    return not(a);
  }
  return _Iff(a, b);
}





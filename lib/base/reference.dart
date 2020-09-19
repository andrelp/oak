part of 'oak_base.dart';

// TODO: Long as shit explöination of paths and their termonology
/// Relative or absolute, single- or multi-path to a map value or node.
class NodeReference {

  /// String of the path given by this instance.
  /// If this path is not the root path, it wont end in '/'.
  final String path;
  /// prefix of this path without last path component.
  /// For a relative path this chain of prefixes will end and [prefixPath] will have value `null`.
  /// [prefixPath] has also value `null` if this is the root reference '/'.
  final NodeReference prefixPath;
  /// last path component of [path].
  /// If this path is a composed path, [lastPathComponent] is `null`. 
  /// If this is a the root reference '/', then [lastPathComponent] is an empty string.
  String get lastPathComponent => isCompositePath?null:path.split('/').last;
  /// [compositePathComponents] is a List of all paths this composed path is composed of.
  /// If this path is not a composed path this list will be `null`.
  final List<NodeReference> compositePathComponents;
  /// Does this path contain a wildcard symbol
  bool get isWildcardPath => path.contains('~');
  /// is this path composed of other paths
  bool get isCompositePath => compositePathComponents!=null;
  /// is this path either composed of other paths or does it contain a wildcard symbol
  bool get isMultiPath => isWildcardPath || isCompositePath;
  /// is this a absolute or relative path? If it is a composed path it is considered relative,
  /// if at least one of its components is relative.
  bool get isRelative => (!isMultiPath&&path.startsWith('/')) || (isMultiPath&&compositePathComponents.any((cpc) => cpc.isRelative));

  const NodeReference._(this.path, this.prefixPath, this.compositePathComponents);
  static const NodeReference root = NodeReference._('/', null, null);

  @override
  bool operator==(dynamic other) => other is NodeReference && other.path==path;
  @override
  int get hashCode => path.hashCode;

  /// Returns a absolute path from this (relative) path, given a context.
  /// For a composed path it will make each composition element absolute.
  /// If this path is relative and context is also relative or a composed path, then [PathNoContext] will be thrown.
  NodeReference absolute(NodeReference context) {
    if (!isRelative) return this;
    if (context.isRelative||context.isCompositePath) throw PathNoContext(this,context);

    if (!isCompositePath) {
      return NodeReference.parse(context.path+'/'+path);
    } else {
      var cPc = compositePathComponents.map((pc) => pc.absolute(context)).toList();
      var absPath = cPc.map((pc) => pc.path).join('--');
      return NodeReference._(absPath, null, cPc);
    }
  }

  /// parses any path, which may be relative, and returns same as [NodeReference.parse]
  /// if path is absolute, otherwise it will set this [path] as a prefix to the
  /// relative path given. if path given is a composed path, it will apply this procedure 
  /// to every composite path component.
  NodeReference reference(String path) {
    var mpComponents = path.split('--').map((cpc) {
      if (cpc.startsWith('/')||cpc.isEmpty) return cpc;
      return path+'/'+cpc;
    });

    path = mpComponents.join('--');

    return NodeReference.parse(path);
  }

  /// This function parses an path to an [NodeReference] instance.
  /// If the path is syntactically invalid, it will throw [InvalidPathSyntax]
  factory NodeReference.parse(String path) {
    if (path != '/' && path.endsWith('/')) path = path.substring(0,path.length-1);

    var mpComponents = path.split('--');

    if (mpComponents.length>1) {
      List<NodeReference> compositePathComponents;
      try {
        compositePathComponents = mpComponents.map((p) => NodeReference.parse(p)).toList();
      } on InvalidPathSyntax {throw InvalidPathSyntax(path);}
      return NodeReference._(path, null, compositePathComponents);
    } else {
      if (path=='/') return root;

      var isRelative = !path.startsWith('/');
      var pathComponents = (isRelative?path:path.substring(1)).split('/');
      if (!pathComponents.every((pc) => RegExp(r'(\.\.|\.|~|([A-Za-z][A-Za-z0-9]*))').stringMatch(pc)==pc)) throw InvalidPathSyntax(path);
      var current = isRelative?null:root;

      for (var pc in pathComponents) {
        var compPath = (current?.path ?? '') + '/' + pc;
        current = NodeReference._(compPath,current,null);
      }

      return current;
    }
    
  }
  
}

/// This error is thrown, when a given path is syntactically wrong. If this occurs, it is likely typo or programming error.
class InvalidPathSyntax extends Error {
  /// the string which could not be parsed into an instance of [NodeReference].
  final String faultyPath;
  InvalidPathSyntax(this.faultyPath);
}

/// This is thrown, when a relative path is converted to a absolute path, but the context given to resolve this wss insufficient.
class PathNoContext extends Error {
  /// context which was being used to create an absolute path. [context] is composed or relative. 
  final NodeReference context;
  /// relative path which should be converted to absolute path.
  final NodeReference path;
  PathNoContext(this.path,this.context);
}

/// This error is thrown, when a multi path was used in
/// a context where this is not allowed.
class InvalidUseOfMultiPath extends Error {
  final NodeReference reference;
  InvalidUseOfMultiPath(this.reference);
}

/// References a stored blob with the unique identification [id].
class BlobReference {
  /// unique identification of the blob
  final String id; 
  const BlobReference(this.id);
}
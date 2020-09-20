part of 'oak_base.dart';

// TODO: Long as shit explöination of paths and their termonology
/// single- or multi-path to a map value or node.
class NodeReference {

  /// String of the path given by this instance.
  /// If this path is not the root path, it wont end in '/'.
  final String path;
  /// prefix of this path without last path component.
  /// [prefixPath] has value `null` if this is the root reference '/'
  /// or if this is a multi-path.
  final NodeReference prefixPath;
  /// last path component of [path].
  /// If this path is a composed path, [lastPathComponent] is `null`. 
  /// If this is a the root reference '/', then [lastPathComponent] is an empty string.
  String get lastPathComponent => isCompositePath?null:path.split('/').last;
  /// returns a list of all path components. If this is a composed path, it returns `null`.
  /// If it is the root path '/' it returns an empty list.
  List<String> get pathComponents => isCompositePath?null:(isRootPath?[]:path.substring(1).split('/'));
  /// [compositePathComponents] is a List of all paths this composed path is composed of.
  /// If this path is not a composed path this list will be `null`.
  final List<NodeReference> compositePathComponents;
  /// Does this path contain a wildcard symbol
  bool get isWildcardPath => path.contains('~');
  /// is this path composed of other paths
  bool get isCompositePath => compositePathComponents!=null;
  /// is this path either composed of other paths or does it contain a wildcard symbol
  bool get isMultiPath => isWildcardPath || isCompositePath;
  /// returns whether this path is the root path '/'
  bool get isRootPath => path=='/';

  const NodeReference._(this.path, this.prefixPath, this.compositePathComponents);
  static const NodeReference root = NodeReference._('/', null, null);

  @override
  bool operator==(dynamic other) => other is NodeReference && other.path==path;
  @override
  int get hashCode => path.hashCode;

  /// parses any path, which may be relative to this.
  /// If path is absolute (i.e. starts with '/'), it returns same as [NodeReference.parse]
  /// if the path is relative to this reference (i.e. does not start with '/')
  /// it will set this [path] as a prefix to the relative path given. 
  /// if path given is a composed path, it will apply this procedure 
  /// to every composite path component.
  NodeReference reference(String path) {
    var mpComponents = path.split('--').map((cpc) {
      if (cpc.startsWith('/')||cpc.isEmpty) return cpc;
      return path+'/'+cpc;
    });

    path = mpComponents.join('--');

    return NodeReference.parse(path);
  }

  /// This function parses a path to an [NodeReference] instance.
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

      if (!path.startsWith('/')) throw InvalidPathSyntax(path);
      var pathComponents = path.substring(1).split('/');

      if (!pathComponents.every((pc) 
        => RegExp(r'(\.\.|\.|~|([A-Za-z][A-Za-z0-9]*))').stringMatch(pc)==pc)
      ) throw InvalidPathSyntax(path);

      var current = root;
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



Oak is a persistent NoSQL, tree based graph database with cross referencing ability and optional structure and value schematics and type safety.

The database is structured as a tree with below listed node types:

| | |
| ------ | ------ |
| _primitives_ | `String`, `int`, `double`, `bool`. These are the leaf nodes of the tree which hold all the data. |
| References | A reference to any other node in the tree. References are also leaf nodes.  |
| Lists | Lists are branch nodes whose children may only be leaf nodes. A list may only contain primitives and (blob-)references.  |
| Maps | Maps with string keys. A map is a branch node with arbitrary child nodes. Each child node is identifies by a key. |
| Documents | Documents are essentially maps. Documents are branch nodes with arbitrary fields (child nodes). Each child node is identifies by a key. Maps and documents only differ in how the data is retrieved (see below). |
| Collections | Collections are essentially maps with String keys and document values. They are branch nodes whose children are only documents which are identified by an ID. A collection should be used to group (a potentially large amount) of similarly structured data. |
| Blob Reference | The database can also store raw data files. Each file has a globally unique id and can be referenced (multiple times) from the tree via a blob reference. A file is deleted as soon as the tree has no references to it. Similarly, the node which holds a blob reference is deleted as soon as the file is deleted it refers to. The id of a blob may be a arbitrary string. |

The root node of the tree is always a document. Note that there is no equivalent of a node which can store value `null`. A node, including as a child of a list or map, "storing" a `null` value is equivalent to the node not existing at all.

## Locate data within the tree

Each node in the tree can be referenced by (multiple) paths.

+ `/` is the path to the root document
+ if _`path`_ is a path to either a map, document or collection, then _`path/child`_ is a path to one of its children.
+ if _`path`_ is a path to a reference with value _`target`_, then _`path/subPath`_ is equivalent to _`target/subPath`_.
+ `.` and `..` also have similar meaning as in file systems. They are especially useful in combination with references. `/path/to/reference/.` and  `/path/to/reference/..` for example are not paths to a reference and its parent, but to the target of that reference and the parent of the target.

Each path component (field name, map key and collection identifier) may only contain characters '0'-'9', 'a'-'z' and 'A'-'Z', may not begin with a number and may not be empty.
A path may or may not end with an additional slash `/`, so `path/to/node` and `path/to/node/` are both valid.

A normalized path is a absolute path which does not use cross-referencing and does not contain path components `.` or `..`.

### Multi paths

For retrieving and querying the database it might be useful to reference multiple nodes at once. This is possible by using wildcard symbols and composing paths.

A path may replace one or more of its path components with the wildcard "`~`". The resulting wildcard path A is a path to every node in the tree for which a path B exist which can be obtained from A by replacing all wildcards by a valid path component name. If for example _`path`_ is a path to a collection, so is _`path/~/~`_ a reference to every field of every document in that collection.

Another way to reference multiple nodes is to compose two or more paths. if `path1`,...,`pathN` are non composed paths, then `path1--path2--`...`--pathN` is a composed path which references the union of all composite path components. If for example _`path`_ is a path to a collection, so is _`path/~/--path/document/field`_ a reference to every field of every document in that collection _and_ the one specific field of one specific document in that collection.

Any path which is composed or contains a wildcard symbol is called a multi path. They may only be used for retrieving and querying the database. A reference within the database must be a single path reference.

## Schema

Schemata may be used to restrict the structure and stored values within a database. They may also be used for querying the database.



## Usage

A simple usage example:

```dart
import 'package:oak/oak.dart';

main() {
  var awesome = new Awesome();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

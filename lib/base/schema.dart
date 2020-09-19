
part of 'oak_base.dart';

//TODO: long as hell documentation
/// A Schema restricts the structure of a (sub-)tree of the database. It can also enforce specific types and restrictions on values of primitive-typed data.
/// It may also be used as parameter for querying the database.
abstract class Schema {
  Schema._();
}

// ###### primitive types ######

/// Node must be of primitive type String.
class StringSchema extends Schema {
  /// String must be equal to [isEqualTo]
  final String isEqualTo;
  /// indicates whether a String may be empty
  final bool mayBeEmpty;
  /// the whole string must match the regular expression [regularExpression]
  final RegExp regularExpression;
  /// the string must contain at least [minLength] characters
  final int minLength;
  /// the length of the string must not exceed [maxLength]
  final int maxLength;
  

  StringSchema({this.isEqualTo,this.mayBeEmpty=true,this.regularExpression,this.minLength,this.maxLength}) : super._();
}

/// Node must be of primitive type int.
class IntSchema extends Schema {
  /// int must be of value [isEqualTo]
  final int isEqualTo;
  /// int must be greater or equal to [min]
  final int min;
  /// int must be smaller or equal to [min]
  final int max;

  IntSchema({this.isEqualTo,this.min,this.max}) : super._();
}

/// Node must be of primitive type double.
class DoubleSchema extends Schema {
  /// int must be of value [isEqualTo]
  final double isEqualTo;
  /// int must be greater or equal to [min]
  final double min;
  /// int must be smaller or equal to [min]
  final double max;

  DoubleSchema({this.isEqualTo,this.min,this.max}) : super._();
}

/// Node must be of primitive type bool.
class BoolSchema extends Schema {
  /// boolean must be equal to [isEqualTo]
  final bool isEqualTo;

  BoolSchema({this.isEqualTo}) : super._();
}

/// Node must be a reference
class ReferenceSchema extends Schema {
  /// The referenced data must follow the schema [referentSchema]. 
  final Schema referentSchema; 

  ReferenceSchema({this.referentSchema}) : super._();
}

// Node must be reference to a blob
class BlobReferenceSchema extends Schema {
  BlobReferenceSchema() : super._();
}

// ###### List & Map ######

/// Node must be a List
class ListSchema extends Schema {
  /// Each element in the list must follow the schema [elementSchema]. 
  final Schema elementSchema; 

  ListSchema({this.elementSchema}) : super._();
}

/// Node value must be a map.
class MapSchema extends Schema {
  /// each value of the map must follow the given schema by [schema] to their associated keys.
  final Map<String,Schema> schema;
  /// if [noOtherKeys] is `true`, map may not contain keys which are not listed in [schema].
  final bool noOtherKeys;
  /// if [noLessKeys] is `true`, map must contain at least all keys which are listed in [schema]. This excludes values with a `NullableSchema`s.
  final bool noLessKeys;
  /// if [mustMatchKeysExactly] is `true`, map must contain exactly those keys specified in [schema] and no more and no less. This excludes values with a `NullableSchema`s.
  final bool mustMatchKeysExactly;

  MapSchema({this.schema=const <String,Schema>{},this.noOtherKeys=false,this.noLessKeys=false,this.mustMatchKeysExactly=false}) : super._();
}

// ###### Collections & Documents ######

/// Node must be Collection
class CollectionSchema extends Schema {
  /// Each document in the collection must follow the schema [childSchema]. 
  final Schema childSchema; 

  CollectionSchema({this.childSchema}) : super._();
}

/// Node must be a Document
class DocumentSchema extends Schema {
  /// each child node of the document must follow the given schema by [schema] to their associated field names.
  final Map<String,Schema> schema;
  /// if [noOtherFields] is `true`, document may not have child fields which are not listed in [schema].
  final bool noOtherFields;
  /// if [noLessFields] is `true`, document must have at least all fields which are listed in [schema]. This excludes fields with a `NullableSchema`s.
  final bool noLessFields;
  /// if [mustMatchFields] is `true`, documents must have exactly those fields specified in [schema] and no more and no less. This excludes fields with a `NullableSchema`s. 
  final bool mustMatchFieldsExactly;
  /// [path] may be any (multi-)path. The document must be located at a path matching which have a matching in [path].
  final NodeReference path;

  DocumentSchema({this.schema=const <String,Schema>{},this.noOtherFields=false,this.noLessFields=false,this.mustMatchFieldsExactly=false,this.path}) : super._();
}

// ###### Miscellaneous ###### 

/// Node with this schema might exist or might not exist
class NullableSchema extends Schema {
  /// if the node or map value exist it must follow [childSchema]
  final Schema childSchema;
  NullableSchema([this.childSchema]) : super._();
}

/// Node may be of arbitrary type and form, but it must exist. Use `NullableSchema(DynamicSchema())` if a node should be completely arbitrary, including not existing at all
class DynamicSchema extends Schema {
  DynamicSchema() : super._();
}

/// Node must follow the schema defined in the database with the name [name].
/// If the database doesn't know the class, it will treat this schema equivalently to [DynamicSchema].
class ClassSchema extends Schema {
  /// Name of the class (named Schema)
  final String name;
  ClassSchema(this.name) : super._() {
    if (name==null) throw NullThrownError();
  }
}

// ###### Logical Operators ######

/// Node value must follow each schema given by [schemata].
class AndSchema extends Schema {
  final List<Schema> schemata;
  AndSchema(this.schemata) : super._() {
    if (schemata==null) throw NullThrownError();
  }
}

/// Node must follow at least one schema given by [schemata].
class OrSchema extends Schema {
  final List<Schema> schemata;
  OrSchema(this.schemata) : super._() {
    if (schemata==null) throw NullThrownError();
  }
}

/// Node may not follow schema [schema].
class NotSchema extends Schema {
  final Schema schema;
  NotSchema(this.schema) : super._() {
    if (schema==null) throw NullThrownError();
  }
}

/// Node must follow exactly one of the schemata given by [schemata].
class XorSchema extends Schema {
  final List<Schema> schemata;
  XorSchema(this.schemata) : super._() {
    if (schemata==null) throw NullThrownError();
  }
}
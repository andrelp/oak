
import 'dart:typed_data';
import '../local_oak.dart';

part 'provider.dart';
part 'snapshots.dart';
part 'util.dart';
part 'schema.dart';
part 'reference.dart';
part 'errors.dart';
part 'database.dart';

//TODO: documentation
Future<LocalOakDatabase> cloneDatabase(OakDatabase other) async =>  LocalOakDatabase.decode(await other.encodeDatabase());
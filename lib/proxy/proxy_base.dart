import 'dart:developer' as dev;



part 'client.dart';
part 'server.dart';

Future<dev.ServiceExtensionResponse> handler(String v, Map<String, String> p) async {
  print("INCOMING EVENT: $v");
  return dev.ServiceExtensionResponse.result("Hey hat geklappt");
}

var foo = dev.registerExtension("oak",handler);




import 'package:yaml/yaml.dart';

Object? yamlToDart(final Object? node) {
  if (node is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      node.entries.map(
        (final entry) =>
            MapEntry(entry.key.toString(), yamlToDart(entry.value)),
      ),
    );
  }
  if (node is YamlList) {
    return node.map(yamlToDart).toList();
  }
  if (node is Map) {
    return Map<String, dynamic>.fromEntries(
      node.entries.map(
        (final entry) =>
            MapEntry(entry.key.toString(), yamlToDart(entry.value)),
      ),
    );
  }
  if (node is List) {
    return node.map(yamlToDart).toList();
  }
  return node;
}

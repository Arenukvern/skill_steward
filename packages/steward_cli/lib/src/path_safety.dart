import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves [childPath] under [root] and rejects lexical or symlink escapes.
String resolveUnderRoot(final String root, final String childPath) {
  final rootPath = Directory(root).resolveSymbolicLinksSync();
  final candidate = p.normalize(
    p.isAbsolute(childPath) ? childPath : p.join(rootPath, childPath),
  );
  if (!isInsideRoot(rootPath, candidate)) {
    throw ArgumentError('Path is outside the repository root: $childPath');
  }
  final ancestor = nearestExistingAncestor(candidate);
  final ancestorCanonical = Directory(ancestor).resolveSymbolicLinksSync();
  final suffix = p.relative(candidate, from: ancestor);
  final resolved = p.normalize(p.join(ancestorCanonical, suffix));
  if (!isInsideRoot(rootPath, resolved)) {
    throw ArgumentError('Path is outside the repository root: $childPath');
  }
  return resolved;
}

String repoRelativePath(final String root, final String path) => p
    .relative(path, from: Directory(root).resolveSymbolicLinksSync())
    .replaceAll(r'\', '/');

bool isInsideRoot(final String root, final String path) {
  final normalizedRoot = p.normalize(root);
  final normalizedPath = p.normalize(path);
  return normalizedPath == normalizedRoot ||
      p.isWithin(normalizedRoot, normalizedPath);
}

String nearestExistingAncestor(final String path) {
  var current = p.normalize(path);
  while (!FileSystemEntity.isDirectorySync(current)) {
    final parent = p.dirname(current);
    if (parent == current) {
      throw ArgumentError('No existing parent for path: $path');
    }
    current = parent;
  }
  return current;
}

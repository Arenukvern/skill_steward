import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks upward from [start] until `skills.sh.json`, `skills.json`, or `.git` is found.
/// Falls back to the absolute path of [start] if no marker is found.
String findRepoRoot(final Directory start) {
  var dir = start.absolute;
  while (true) {
    if (File(p.join(dir.path, 'skills.sh.json')).existsSync() ||
        File(p.join(dir.path, 'skills.json')).existsSync() ||
        Directory(p.join(dir.path, '.git')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return start.absolute.path;
    }
    dir = parent;
  }
}

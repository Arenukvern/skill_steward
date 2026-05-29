import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks upward from [start] until `skills.sh.json` is found.
String findRepoRoot(final Directory start) {
  var dir = start.absolute;
  while (true) {
    if (File(p.join(dir.path, 'skills.sh.json')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Not inside a Skill Steward repo (missing skills.sh.json).',
      );
    }
    dir = parent;
  }
}

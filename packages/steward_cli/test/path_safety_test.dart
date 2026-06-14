import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/path_safety.dart';
import 'package:test/test.dart';

void main() {
  late Directory sandbox;
  late Directory root;
  late Directory outside;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('steward_path_safety_');
    root = Directory(p.join(sandbox.path, 'repo'))..createSync();
    outside = Directory(p.join(sandbox.path, 'outside'))..createSync();
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  test('lexical dot-dot escapes are rejected', () {
    expect(
      () => resolveUnderRoot(root.path, '../outside/escape.txt'),
      throwsArgumentError,
    );
  });

  test('absolute paths outside root are rejected', () {
    expect(
      () => resolveUnderRoot(root.path, p.join(outside.path, 'escape.txt')),
      throwsArgumentError,
    );
  });

  test('existing symlink file escaping root is rejected', () {
    final outsideFile = File(p.join(outside.path, 'escape.txt'))
      ..writeAsStringSync('outside');
    Link(p.join(root.path, 'linked-file')).createSync(outsideFile.path);

    expect(
      () => resolveUnderRoot(root.path, 'linked-file'),
      throwsArgumentError,
    );
  });

  test('existing symlink directory escaping root is rejected', () {
    Link(p.join(root.path, 'linked-dir')).createSync(outside.path);

    expect(
      () => resolveUnderRoot(root.path, 'linked-dir'),
      throwsArgumentError,
    );
  });

  test('missing child under in-root existing ancestor is allowed', () {
    Directory(p.join(root.path, 'docs')).createSync();

    expect(
      resolveUnderRoot(root.path, 'docs/new.md'),
      p.join(root.resolveSymbolicLinksSync(), 'docs', 'new.md'),
    );
  });

  test('missing child under escaping symlink ancestor is rejected', () {
    Link(p.join(root.path, 'linked-dir')).createSync(outside.path);

    expect(
      () => resolveUnderRoot(root.path, 'linked-dir/new.md'),
      throwsArgumentError,
    );
  });

  test('broken symlinks fail closed', () {
    Link(
      p.join(root.path, 'broken-link'),
    ).createSync(p.join(outside.path, 'missing.txt'));

    expect(
      () => resolveUnderRoot(root.path, 'broken-link'),
      throwsArgumentError,
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/repo_root.dart';
import 'package:test/test.dart';

void main() {
  late final String repoRoot;
  late final Directory schemasDir;

  setUpAll(() {
    String findRootForTest() {
      try {
        return findRepoRoot(Directory.current);
      } on Object {
        final scriptPath = Platform.script.toFilePath();
        return findRepoRoot(File(scriptPath).parent);
      }
    }

    repoRoot = findRootForTest();
    schemasDir = Directory(p.join(repoRoot, 'docs', 'schemas'));
  });

  test('schema directory exposes current Steward contract schemas', () {
    final expected = {
      'steward-v1.schema.json',
      'scenario-manifest-v1.schema.json',
      'plugin-manifest-v1.schema.json',
      'plugin-bundle-v1.schema.json',
      'plugin-bundle-index-v1.schema.json',
      'doctor-v1.schema.json',
      'observation-v1.schema.json',
      'unknown-case-v1.schema.json',
      'action-candidate-v1.schema.json',
      'benchmark-summary-v1.schema.json',
    };

    for (final fileName in expected) {
      expect(
        File(p.join(schemasDir.path, fileName)).existsSync(),
        isTrue,
        reason: 'Missing docs/schemas/$fileName',
      );
    }
  });

  test('all JSON schema artifacts parse and declare stable ids', () {
    final schemaFiles =
        schemasDir
            .listSync()
            .whereType<File>()
            .where((final file) => file.path.endsWith('.schema.json'))
            .toList()
          ..sort((final a, final b) => a.path.compareTo(b.path));

    expect(schemaFiles, isNotEmpty);
    for (final file in schemaFiles) {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(data[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
      expect(data[r'$id'], isA<String>());
      expect(data['title'], isA<String>());
      expect(data['type'], 'object');
      expect(data['required'], isA<List>());
    }
  });

  test('schema README links every schema artifact', () {
    final readme = File(
      p.join(schemasDir.path, 'README.mdx'),
    ).readAsStringSync();
    final schemaFiles = schemasDir
        .listSync()
        .whereType<File>()
        .map((final file) => p.basename(file.path))
        .where((final name) => name.endsWith('.schema.json'));

    for (final fileName in schemaFiles) {
      expect(readme, contains(fileName));
    }
  });
}

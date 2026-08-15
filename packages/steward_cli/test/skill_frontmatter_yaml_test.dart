import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/repo_root.dart';
import 'package:steward_cli/src/validation/skill_frontmatter.dart';
import 'package:test/test.dart';

void main() {
  late final String repoRoot;

  setUpAll(() {
    try {
      repoRoot = findRepoRoot(Directory.current);
    } on Object {
      repoRoot = findRepoRoot(File(Platform.script.toFilePath()).parent);
    }
  });

  group('skill frontmatter YAML (npx skills / js-yaml gate)', () {
    test('rejects unquoted compact mapping in description', () {
      const content = '''
---
name: example-skill
description: Contract for any agent-operated engineering repository: app, library.
license: MIT
---

# Body
''';
      final parsed = parseFrontmatter(content);
      expect(parsed.error, isNotNull);
      expect(parsed.error, contains('Invalid YAML frontmatter'));
      expect(parsed.error, contains('npx skills'));
    });

    test('accepts the same description as a folded block', () {
      const content = '''
---
name: example-skill
description: >-
  Contract for any agent-operated engineering repository: app, library.
license: MIT
---

# Body
''';
      final parsed = parseFrontmatter(content);
      expect(parsed.error, isNull);
      expect(
        parsed['description'],
        'Contract for any agent-operated engineering repository: app, library.',
      );
    });

    test('every installable skills/*/SKILL.md frontmatter is valid YAML', () {
      final skillsDir = Directory(p.join(repoRoot, 'skills'));
      expect(skillsDir.existsSync(), isTrue);

      final failures = <String>[];
      for (final entry in skillsDir.listSync().whereType<Directory>()) {
        final skillMd = File(p.join(entry.path, 'SKILL.md'));
        if (!skillMd.existsSync()) {
          failures.add('${p.basename(entry.path)}: missing SKILL.md');
          continue;
        }
        final parsed = parseFrontmatter(skillMd.readAsStringSync());
        if (parsed.error != null) {
          failures.add('${p.basename(entry.path)}: ${parsed.error}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'npx skills skips skills whose frontmatter js-yaml cannot parse.\n'
            '${failures.join('\n')}',
      );
    });
  });
}

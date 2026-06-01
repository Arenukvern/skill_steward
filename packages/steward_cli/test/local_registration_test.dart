import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/install_command.dart';
import 'package:steward_cli/src/commands/validate_command.dart';
import 'package:steward_cli/src/validation/validation.dart';

import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Local Validation and Manifest Parsing', () {
    test('reports missing skills.json', () async {
      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(report.registryWarnings.first, contains('Missing required project configuration file: skills.json'));
    });

    test('validates matching local skills successfully', () async {
      // 1. Create skills.json
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(jsonEncode({
        'skills': [
          {
            'source': 'test/repo',
            'skills': ['skill-a']
          }
        ]
      }));

      // 2. Create local skill directory
      final localSkillDir = Directory(p.join(tempDir.path, '.agents', 'skills', 'skill-a'))..createSync(recursive: true);
      final skillMd = File(p.join(localSkillDir.path, 'SKILL.md'));
      await skillMd.writeAsString('''---
name: skill-a
description: This is a test skill for validation.
license: MIT
---
Instruction steps here.
''');
      
      final sourcesMd = File(p.join(localSkillDir.path, 'references', 'sources.md'))..createSync(recursive: true);
      await sourcesMd.writeAsString('Sources contents');

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isTrue);
      expect(report.skills.length, equals(1));
      expect(report.skills.first.dirName, equals('skill-a'));
      expect(report.skills.first.isValid, isTrue);
    });

    test('detects missing skill directory', () async {
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(jsonEncode({
        'skills': [
          {
            'source': 'test/repo',
            'skills': ['skill-missing']
          }
        ]
      }));

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(report.skills.first.errors.first, contains('Declared skill is missing'));
    });

    test('detects undeclared extra local skill directories', () async {
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(jsonEncode({
        'skills': [
          {
            'source': 'test/repo',
            'skills': ['skill-a']
          }
        ]
      }));

      // Create skill-a
      final localSkillDirA = Directory(p.join(tempDir.path, '.agents', 'skills', 'skill-a'))..createSync(recursive: true);
      await File(p.join(localSkillDirA.path, 'SKILL.md')).writeAsString('''---
name: skill-a
description: This is a test skill for validation.
license: MIT
---
Steps
''');
      await File(p.join(localSkillDirA.path, 'references', 'sources.md'))..createSync(recursive: true)..writeAsString('Sources');

      // Create extra skill-b
      final localSkillDirB = Directory(p.join(tempDir.path, '.agents', 'skills', 'skill-b'))..createSync(recursive: true);
      await File(p.join(localSkillDirB.path, 'SKILL.md')).writeAsString('''---
name: skill-b
description: This is an extra test skill for validation.
license: MIT
---
Steps
''');

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(report.registryWarnings.first, contains('Undeclared skill directory found: .agents/skills/skill-b'));
    });
  });

  group('Frontmatter Translation Utility', () {
    test('translates cursor metadata successfully', () {
      const input = '''---
name: test-skill
description: Test skill description.
metadata:
  author: tester
  cursor:
    paths:
      - "docs/**"
      - "DESIGN_FAQ.md"
    disable-model-invocation: true
---
Body steps.
''';

      final output = InstallCommand.translateFrontmatter(input, 'cursor');
      expect(output, contains('paths:\n  - "docs/**"\n  - "DESIGN_FAQ.md"'));
      expect(output, contains('Body steps.'));

      // Generic target should leave unchanged
      final outputGeneric = InstallCommand.translateFrontmatter(input, 'generic');
      expect(outputGeneric, equals(input));
    });
  });

  group('Command Registration', () {
    test('ValidateCommand supports --local option', () {
      final cmd = ValidateCommand();
      expect(cmd.argParser.options.containsKey('local'), isTrue);
    });

    test('InstallCommand is registered with correct options', () {
      final cmd = InstallCommand();
      expect(cmd.argParser.options.containsKey('local'), isTrue);
      expect(cmd.argParser.options.containsKey('target'), isTrue);
      expect(cmd.argParser.options.containsKey('lock'), isTrue);
      expect(cmd.argParser.options.containsKey('force'), isTrue);
    });
  });
}



import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/action_candidate_command.dart';
import 'package:steward_cli/src/commands/action_command.dart';
import 'package:steward_cli/src/commands/actions_command.dart';
import 'package:steward_cli/src/commands/adopt_command.dart';
import 'package:steward_cli/src/commands/benchmark_command.dart';
import 'package:steward_cli/src/commands/diagnose_command.dart';
import 'package:steward_cli/src/commands/doctor_command.dart';
import 'package:steward_cli/src/commands/dogfood_command.dart';
import 'package:steward_cli/src/commands/ecology_command.dart';
import 'package:steward_cli/src/commands/evidence_command.dart';
import 'package:steward_cli/src/commands/install_command.dart';
import 'package:steward_cli/src/commands/map_command.dart';
import 'package:steward_cli/src/commands/observe_command.dart';
import 'package:steward_cli/src/commands/probe_command.dart';
import 'package:steward_cli/src/commands/uninstall_command.dart';
import 'package:steward_cli/src/commands/unknown_case_command.dart';
import 'package:steward_cli/src/commands/update_command.dart';
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

  Future<void> runGit(final List<String> arguments) async {
    await _runGitAt(tempDir, arguments);
  }

  group('Local Validation and Manifest Parsing', () {
    test('reports missing skills.json', () async {
      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.first,
        contains('Missing required project configuration file: skills.json'),
      );
    });

    test('validates matching local skills successfully', () async {
      // 1. Create skills.json
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(
        jsonEncode({
          'skills': [
            {
              'source': 'test/repo',
              'skills': ['skill-a'],
            },
          ],
        }),
      );

      // 2. Create local skill directory
      final localSkillDir = Directory(
        p.join(tempDir.path, '.agents', 'skills', 'skill-a'),
      )..createSync(recursive: true);
      final skillMd = File(p.join(localSkillDir.path, 'SKILL.md'));
      await skillMd.writeAsString('''
---
name: skill-a
description: This is a test skill for validation.
license: MIT
---
Instruction steps here.
''');

      final sourcesMd = File(
        p.join(localSkillDir.path, 'references', 'sources.md'),
      )..createSync(recursive: true);
      await sourcesMd.writeAsString('Sources contents');

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isTrue);
      expect(report.skills.length, equals(1));
      expect(report.skills.first.dirName, equals('skill-a'));
      expect(report.skills.first.isValid, isTrue);
    });

    test('detects missing skill directory', () async {
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(
        jsonEncode({
          'skills': [
            {
              'source': 'test/repo',
              'skills': ['skill-missing'],
            },
          ],
        }),
      );

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.skills.first.errors.first,
        contains('Declared skill is missing'),
      );
    });

    test('detects undeclared extra local skill directories', () async {
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(
        jsonEncode({
          'skills': [
            {
              'source': 'test/repo',
              'skills': ['skill-a'],
            },
          ],
        }),
      );

      // Create skill-a
      final localSkillDirA = Directory(
        p.join(tempDir.path, '.agents', 'skills', 'skill-a'),
      )..createSync(recursive: true);
      await File(p.join(localSkillDirA.path, 'SKILL.md')).writeAsString('''
---
name: skill-a
description: This is a test skill for validation.
license: MIT
---
Steps
''');
      final sourcesFile = File(
        p.join(localSkillDirA.path, 'references', 'sources.md'),
      )..createSync(recursive: true);
      await sourcesFile.writeAsString('Sources');

      // Create extra skill-b
      final localSkillDirB = Directory(
        p.join(tempDir.path, '.agents', 'skills', 'skill-b'),
      )..createSync(recursive: true);
      await File(p.join(localSkillDirB.path, 'SKILL.md')).writeAsString('''
---
name: skill-b
description: This is an extra test skill for validation.
license: MIT
---
Steps
''');

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.first,
        contains('Undeclared skill directory found: .agents/skills/skill-b'),
      );
    });
  });

  group('Frontmatter Translation Utility', () {
    test('translates cursor metadata successfully', () {
      const input = '''
---
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
      final outputGeneric = InstallCommand.translateFrontmatter(
        input,
        'generic',
      );
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

    test('UpdateCommand is registered with correct options', () {
      final cmd = UpdateCommand();
      expect(cmd.argParser.options.containsKey('local'), isTrue);
      expect(cmd.argParser.options.containsKey('target'), isTrue);
      expect(cmd.argParser.options.containsKey('force'), isTrue);
    });

    test('adoption discovery commands are registered with JSON options', () {
      final adopt = AdoptCommand();
      final doctor = DoctorCommand();
      final actions = ActionsCommand();
      final action = ActionCommand();
      final actionCandidate = ActionCandidateCommand();
      final probe = ProbeCommand();
      final observe = ObserveCommand();
      final unknownCase = UnknownCaseCommand();
      final diagnose = DiagnoseCommand();
      final benchmark = BenchmarkCommand();
      final ecology = EcologyCommand();
      final evidence = EvidenceCommand();
      final dogfood = DogfoodCommand();

      expect(adopt.argParser.options.containsKey('archetype'), isTrue);
      expect(adopt.argParser.options.containsKey('with-harness'), isTrue);
      expect(evidence.subcommands.containsKey('init'), isTrue);
      expect(
        evidence.subcommands['init']!.argParser.options.containsKey('minimal'),
        isTrue,
      );
      expect(
        evidence.subcommands['init']!.argParser.options.containsKey('json'),
        isTrue,
      );
      expect(doctor.argParser.options.containsKey('json'), isTrue);
      expect(actions.subcommands.containsKey('list'), isTrue);
      expect(
        actions.subcommands['list']!.argParser.options.containsKey('json'),
        isTrue,
      );
      expect(action.subcommands.containsKey('inspect'), isTrue);
      expect(actionCandidate.subcommands.containsKey('create'), isTrue);
      expect(actionCandidate.subcommands.containsKey('review'), isTrue);
      expect(
        action.subcommands['inspect']!.argParser.options.containsKey('json'),
        isTrue,
      );
      expect(
        actionCandidate.subcommands['create']!.argParser.options.containsKey(
          'from',
        ),
        isTrue,
      );
      expect(
        actionCandidate.subcommands['create']!.argParser.options.containsKey(
          'argv-json',
        ),
        isTrue,
      );
      expect(
        actionCandidate.subcommands['review']!.argParser.options.containsKey(
          'from',
        ),
        isTrue,
      );
      expect(probe.argParser.options.containsKey('json'), isTrue);
      expect(probe.argParser.options.containsKey('profile'), isTrue);
      expect(observe.argParser.options.containsKey('json'), isTrue);
      expect(observe.argParser.options.containsKey('profile'), isTrue);
      expect(observe.argParser.options.containsKey('from'), isTrue);
      expect(unknownCase.subcommands.containsKey('create'), isTrue);
      expect(
        unknownCase.subcommands['create']!.argParser.options.containsKey(
          'json',
        ),
        isTrue,
      );
      expect(
        unknownCase.subcommands['create']!.argParser.options.containsKey(
          'from',
        ),
        isTrue,
      );
      expect(diagnose.argParser.options.containsKey('json'), isTrue);
      expect(diagnose.argParser.options.containsKey('from'), isTrue);
      expect(benchmark.argParser.options.containsKey('json'), isTrue);
      expect(benchmark.argParser.options.containsKey('scenario'), isTrue);
      expect(ecology.subcommands.containsKey('snapshot'), isTrue);
      expect(ecology.subcommands.containsKey('route'), isTrue);
      expect(
        ecology.subcommands['route']!.argParser.options.containsKey('json'),
        isTrue,
      );
      expect(dogfood.subcommands.containsKey('status'), isTrue);
      expect(
        dogfood.subcommands['status']!.argParser.options.containsKey('json'),
        isTrue,
      );
    });
  });

  group('InstallCommand Integration', () {
    test('copies local skill directory successfully', () async {
      final originalCwd = Directory.current;
      try {
        // Set up dummy workspace
        final workspaceDir = tempDir;
        Directory.current = workspaceDir;

        // Create skills.sh.json to mark repo root
        await File(
          p.join(workspaceDir.path, 'skills.sh.json'),
        ).writeAsString('{}');

        // Create dummy source skill
        final srcSkillDir = Directory(
          p.join(workspaceDir.path, 'skills', 'dummy-skill'),
        )..createSync(recursive: true);
        await File(p.join(srcSkillDir.path, 'SKILL.md')).writeAsString('''
---
name: dummy-skill
description: A dummy test skill.
metadata:
  cursor:
    paths:
      - "docs/**"
---
Instruction body.
''');

        // Run install command
        final runner = CommandRunner<void>('steward', 'test')
          ..addCommand(InstallCommand());
        await runner.run([
          'install',
          'skills/dummy-skill',
          '--local',
          '--target',
          'cursor',
          '--force',
        ]);

        // Verify copy exists under .agents/skills/dummy-skill
        final destSkillDir = Directory(
          p.join(workspaceDir.path, '.agents', 'skills', 'dummy-skill'),
        );
        expect(destSkillDir.existsSync(), isTrue);

        final skillMd = File(p.join(destSkillDir.path, 'SKILL.md'));
        expect(skillMd.existsSync(), isTrue);

        final content = await skillMd.readAsString();
        expect(content, contains('paths:\n  - "docs/**"'));
        expect(content, contains('Instruction body.'));
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('installs config source pinned to a raw commit sha', () async {
      final originalCwd = Directory.current;
      try {
        final workspaceDir = tempDir;
        Directory.current = workspaceDir;
        await File(
          p.join(workspaceDir.path, 'skills.sh.json'),
        ).writeAsString('{}');

        final sourceRepo = Directory(p.join(workspaceDir.path, 'source-repo'))
          ..createSync(recursive: true);
        await _runGitAt(sourceRepo, ['init']);
        await _runGitAt(sourceRepo, [
          'config',
          'user.email',
          'test@example.invalid',
        ]);
        await _runGitAt(sourceRepo, ['config', 'user.name', 'Skill Test']);

        final skillDir = Directory(
          p.join(sourceRepo.path, 'skills', 'pinned-skill'),
        )..createSync(recursive: true);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: pinned-skill
description: First committed version.
license: MIT
---
First version.
''');
        await _runGitAt(sourceRepo, ['add', '.']);
        await _runGitAt(sourceRepo, ['commit', '-m', 'first skill']);
        final firstCommit = await _runGitAt(sourceRepo, ['rev-parse', 'HEAD']);

        await skillFile.writeAsString('''
---
name: pinned-skill
description: Second committed version.
license: MIT
---
Second version.
''');
        await _runGitAt(sourceRepo, ['add', '.']);
        await _runGitAt(sourceRepo, ['commit', '-m', 'second skill']);

        await File(p.join(workspaceDir.path, 'skills.json')).writeAsString(
          jsonEncode({
            'skills': [
              {
                'source': sourceRepo.uri.toString(),
                'commit': firstCommit,
                'skills': ['pinned-skill'],
              },
            ],
          }),
        );

        final runner = CommandRunner<void>('steward', 'test')
          ..addCommand(InstallCommand());
        await runner.run(['install', '--local', '--force']);

        final installedSkill = File(
          p.join(
            workspaceDir.path,
            '.agents',
            'skills',
            'pinned-skill',
            'SKILL.md',
          ),
        );
        expect(installedSkill.existsSync(), isTrue);
        final installed = await installedSkill.readAsString();
        expect(installed, contains('First version.'));
        expect(installed, isNot(contains('Second version.')));
      } finally {
        Directory.current = originalCwd;
      }
    });
  });

  group('New Agent CLI Commands and Plan Hygiene', () {
    test('detects active plan files during local validation', () async {
      // 1. Create skills.json
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(jsonEncode({'skills': []}));

      // 2. Create task.md
      final taskFile = File(p.join(tempDir.path, 'task.md'));
      await taskFile.writeAsString('Dummy task list');

      var report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.any(
          (final w) => w.contains('Stale/active plan file found: task.md'),
        ),
        isTrue,
      );

      // Clean task.md and add implementation_plan.md
      await taskFile.delete();
      final planFile = File(p.join(tempDir.path, 'implementation_plan.md'));
      await planFile.writeAsString('Dummy plan');

      report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.any(
          (final w) => w.contains(
            'Stale/active plan file found: implementation_plan.md',
          ),
        ),
        isTrue,
      );

      // Clean implementation_plan.md and add active plan in docs/exec-plans/active/
      await planFile.delete();
      final activePlanDir = Directory(
        p.join(tempDir.path, 'docs', 'exec-plans', 'active'),
      )..createSync(recursive: true);
      final execPlanFile = File(
        p.join(activePlanDir.path, '2026-06-02-test-plan.md'),
      );
      await execPlanFile.writeAsString('Active plan details');

      report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.any(
          (final w) => w.contains(
            'Stale/active plan file found: docs/exec-plans/active/2026-06-02-test-plan.md',
          ),
        ),
        isTrue,
      );
    });

    test('steward adopt initializes workspace configs', () async {
      final originalCwd = Directory.current;
      try {
        Directory.current = tempDir;

        final runner = CommandRunner<void>('steward', 'test')
          ..addCommand(AdoptCommand());
        await runner.run(['adopt']);

        final skillsJson = File(p.join(tempDir.path, 'skills.json'));
        expect(skillsJson.existsSync(), isTrue);

        final stewardYaml = File(p.join(tempDir.path, 'steward.yaml'));
        expect(stewardYaml.existsSync(), isTrue);
        final stewardContent = await stewardYaml.readAsString();
        expect(stewardContent, contains('schema: steward/v1'));
        expect(stewardContent, contains('archetype: library'));
        expect(stewardContent, contains('archetype_detection:'));
        expect(stewardContent, contains('confidence: 0.4'));
        expect(stewardContent, contains('default fallback'));
        expect(stewardContent, contains('installable_skills: false'));
        expect(
          stewardContent,
          contains(
            "validate: 'blocked: native validation command not detected'",
          ),
        );
        expect(stewardContent, contains('enabled: false'));
        expect(stewardContent, contains('actions: {}'));
        expect(stewardContent, isNot(contains('doctor.local:')));
        expect(
          Directory(p.join(tempDir.path, 'steward', 'scenarios')).existsSync(),
          isFalse,
        );

        final agentsMd = File(p.join(tempDir.path, 'AGENTS.md'));
        expect(agentsMd.existsSync(), isTrue);
        final agentsContent = await agentsMd.readAsString();
        expect(agentsContent, contains('steward map'));
        expect(agentsContent, contains('## North Star Impact'));
        expect(agentsContent, contains('north_star_impact'));
        expect(agentsContent, contains('sub_star'));
        expect(agentsContent, contains('amends'));
        expect(agentsContent, contains('conflicts'));
        expect(
          agentsContent,
          contains('whether a mechanism is becoming the mission'),
        );
        expect(agentsContent, contains('## Claims and Evidence'));
        expect(agentsContent, contains('same friction loops twice'));
        expect(agentsContent, contains('pain signal'));
        expect(agentsContent, contains('owner'));
        expect(agentsContent, contains('native validation gate'));
        expect(agentsContent, contains('smallest disposition'));
        expect(agentsContent, contains('rerun route'));
        expect(agentsContent, contains('current ledger'));
        expect(agentsContent, contains('non-claims'));
        expect(agentsContent, contains('steward evidence init --minimal'));
        expect(
          agentsContent,
          contains('native validation command recorded in `steward.yaml`'),
        );
        expect(
          agentsContent,
          contains(
            'Default to no harness: do not add actions, probes, benchmarks, or scenarios',
          ),
        );
        expect(
          agentsContent,
          contains(
            'unless typed actions, probes, or benchmarks help real repo work',
          ),
        );
        expect(agentsContent, isNot(contains('doctor.local:')));
        expect(agentsContent, contains('Record non-claims.'));
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('steward adopt accepts explicit archetype and native gate', () async {
      final originalCwd = Directory.current;
      try {
        Directory.current = tempDir;
        await File(p.join(tempDir.path, 'package.json')).writeAsString(
          jsonEncode({
            'scripts': {'validate': 'node validate.js'},
          }),
        );

        final runner = CommandRunner<void>('steward', 'test')
          ..addCommand(AdoptCommand());
        await runner.run(['adopt', '--archetype', 'app']);

        final stewardYaml = File(p.join(tempDir.path, 'steward.yaml'));
        final stewardContent = await stewardYaml.readAsString();
        expect(stewardContent, contains('archetype: app'));
        expect(stewardContent, contains('confidence: 1.0'));
        expect(stewardContent, contains('explicit --archetype'));
        expect(stewardContent, contains("validate: 'pnpm run validate'"));
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('steward adopt detects common native validation gates', () async {
      final fixtures = <String, Future<void> Function(Directory)>{
        "validate: 'just check'": (final dir) async {
          await File(p.join(dir.path, 'Justfile')).writeAsString('check:\n');
        },
        "validate: 'make test'": (final dir) async {
          await File(p.join(dir.path, 'Makefile')).writeAsString('test:\n');
        },
        "validate: 'dart test'": (final dir) async {
          await File(
            p.join(dir.path, 'pubspec.yaml'),
          ).writeAsString('name: fixture\n');
        },
      };

      for (final entry in fixtures.entries) {
        final fixtureDir = Directory.systemTemp.createTempSync('steward_gate_');
        final originalCwd = Directory.current;
        try {
          Directory.current = fixtureDir;
          await entry.value(fixtureDir);

          final runner = CommandRunner<void>('steward', 'test')
            ..addCommand(AdoptCommand());
          await runner.run(['adopt']);

          final stewardContent = await File(
            p.join(fixtureDir.path, 'steward.yaml'),
          ).readAsString();
          expect(stewardContent, contains(entry.key));
        } finally {
          Directory.current = originalCwd;
          if (fixtureDir.existsSync()) {
            fixtureDir.deleteSync(recursive: true);
          }
        }
      }
    });

    test(
      'steward adopt --with-harness initializes quick proof scaffold',
      () async {
        final originalCwd = Directory.current;
        try {
          Directory.current = tempDir;
          await File(
            p.join(tempDir.path, 'README.md'),
          ).writeAsString('fixture');
          await runGit(['init']);
          await runGit(['config', 'user.email', 'test@example.invalid']);
          await runGit(['config', 'user.name', 'Skill Steward Test']);
          await runGit([
            'remote',
            'add',
            'origin',
            'https://example.invalid/steward-fixture.git',
          ]);
          await runGit(['add', 'README.md']);
          await runGit(['commit', '-m', 'fixture']);

          final runner = CommandRunner<void>('steward', 'test')
            ..addCommand(AdoptCommand());
          await runner.run(['adopt', '--with-harness']);

          final stewardYaml = File(p.join(tempDir.path, 'steward.yaml'));
          final stewardContent = await stewardYaml.readAsString();
          expect(stewardContent, contains('enabled: true'));
          expect(stewardContent, contains('doctor.local:'));
          expect(stewardContent, isNot(contains('fs_read: ["."]')));
          expect(stewardContent, contains('- steward.yaml'));
          expect(stewardContent, contains('- skills.json'));
          expect(stewardContent, contains('- AGENTS.md'));
          expect(stewardContent, contains('benchmarks:'));

          final scenariosDir = Directory(
            p.join(tempDir.path, 'steward', 'scenarios'),
          );
          final scenarios = scenariosDir.listSync().whereType<File>().toList();
          expect(scenarios, hasLength(1));
          final scenarioContent = await scenarios.single.readAsString();
          expect(scenarioContent, contains('safe_first_probe: doctor.local'));
          expect(scenarioContent, contains('https://example.invalid'));
        } finally {
          Directory.current = originalCwd;
        }
      },
    );

    test(
      'steward uninstall removes skill directory and configuration',
      () async {
        final originalCwd = Directory.current;
        try {
          Directory.current = tempDir;

          // Setup config and local folder
          final skillsJson = File(p.join(tempDir.path, 'skills.json'));
          await skillsJson.writeAsString(
            jsonEncode({
              'skills': [
                {
                  'source': 'test-source',
                  'skills': ['skill-to-delete', 'skill-to-keep'],
                },
              ],
            }),
          );

          final skillDir = Directory(
            p.join(tempDir.path, '.agents', 'skills', 'skill-to-delete'),
          )..createSync(recursive: true);
          await File(
            p.join(skillDir.path, 'SKILL.md'),
          ).writeAsString('Skill info');

          final runner = CommandRunner<void>('steward', 'test')
            ..addCommand(UninstallCommand());
          await runner.run(['uninstall', 'skill-to-delete']);

          expect(skillDir.existsSync(), isFalse);

          final raw = await skillsJson.readAsString();
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final skillsArray = data['skills'] as List;
          final list = (skillsArray.first as Map)['skills'] as List;
          expect(list.contains('skill-to-delete'), isFalse);
          expect(list.contains('skill-to-keep'), isTrue);
        } finally {
          Directory.current = originalCwd;
        }
      },
    );

    test('steward map generates Markdown workspace overview', () async {
      final originalCwd = Directory.current;
      try {
        Directory.current = tempDir;

        // Adopt workspace to create skills.json and AGENTS.md
        final runnerAdopt = CommandRunner<void>('steward', 'test')
          ..addCommand(AdoptCommand());
        await runnerAdopt.run(['adopt']);

        // Create a local skill
        final skillDir = Directory(
          p.join(tempDir.path, '.agents', 'skills', 'skill-a'),
        )..createSync(recursive: true);
        await File(p.join(skillDir.path, 'SKILL.md')).writeAsString('''
---
name: skill-a
description: This is skill A.
type: developer
---
Body steps
''');

        // Create doc files
        final starFile = File(p.join(tempDir.path, 'NORTH_STAR.mdx'))
          ..createSync();
        await starFile.writeAsString('North Star content');

        // Execute MapCommand with StringBuffer output
        final buffer = StringBuffer();
        final mapCmd = MapCommand(buffer);
        final runnerMap = CommandRunner<void>('steward', 'test')
          ..addCommand(mapCmd);
        await runnerMap.run(['map']);

        final output = buffer.toString();
        expect(output, contains('Agent Map'));
        expect(output, contains('Archetype Source'));
        expect(output, contains('Confidence'));
        expect(output, contains('Native Quality Gate'));
        expect(output, contains('Evidence Route'));
        expect(output, contains('Configured Evidence Path'));
        expect(output, contains('steward evidence init --minimal'));
        expect(output, contains('skill-a'));
        expect(output, contains('developer'));
        expect(output, contains('This is skill A.'));
        expect(output, isNot(contains('skill-authoring-lifecycle')));
        expect(output, isNot(contains('skill-eval-improve')));
        expect(output, contains('NORTH_STAR.mdx'));
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('steward evidence init creates minimal current ledger', () async {
      final originalCwd = Directory.current;
      try {
        Directory.current = tempDir;
        final runner = CommandRunner<void>('steward', 'test')
          ..addCommand(AdoptCommand())
          ..addCommand(EvidenceCommand());
        await runner.run(['adopt']);

        final output = StringBuffer();
        final evidenceRunner = CommandRunner<void>('steward', 'test')
          ..addCommand(EvidenceCommand(output, tempDir));
        await evidenceRunner.run(['evidence', 'init', '--minimal', '--json']);

        final result = jsonDecode(output.toString()) as Map<String, dynamic>;
        expect(result['created'], isTrue);
        expect(result['path'], 'docs/evidence/current-status.mdx');

        final ledger = File(
          p.join(tempDir.path, 'docs', 'evidence', 'current-status.mdx'),
        );
        expect(ledger.existsSync(), isTrue);
        final ledgerContent = await ledger.readAsString();
        final localDate = DateTime.now().toIso8601String().split('T').first;
        expect(ledgerContent, contains('status: current'));
        expect(ledgerContent, contains('evidence_type: ledger'));
        expect(ledgerContent, contains('date: $localDate'));
        expect(ledgerContent, contains('Does not prove readiness'));

        final secondOutput = StringBuffer();
        final secondRunner = CommandRunner<void>('steward', 'test')
          ..addCommand(EvidenceCommand(secondOutput, tempDir));
        await secondRunner.run(['evidence', 'init', '--minimal', '--json']);
        final second = jsonDecode(secondOutput.toString()) as Map;
        expect(second['created'], isFalse);
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('steward.yaml parses and runs custom validations', () async {
      // 1. Create a dummy skills.json
      final skillsJson = File(p.join(tempDir.path, 'skills.json'));
      await skillsJson.writeAsString(jsonEncode({'skills': []}));

      // 2. Create steward.yaml defining custom linter
      final stewardYaml = File(p.join(tempDir.path, 'steward.yaml'));
      await stewardYaml.writeAsString('''
validators:
  - type: disallowed-substrings
    files:
      - "**/pubspec.yaml"
    exclude:
      - "**/.dart_tool/**"
    substrings:
      - forbidden-override
    message: "FAIL: No forbidden overrides allowed!"
''');

      // 3. Create pubspec.yaml with the forbidden word
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspec.writeAsString(
        'dependency_overrides:\n  some_pkg:\n    path: forbidden-override',
      );

      final report = await validateLocalSkills(tempDir.path);
      expect(report.ok, isFalse);
      expect(
        report.registryWarnings.any(
          (final w) => w.contains('FAIL: No forbidden overrides allowed!'),
        ),
        isTrue,
        reason: 'Report warnings should contain custom linter failure message',
      );

      // Fix pubspec.yaml and test it passes
      await pubspec.writeAsString('dependency_overrides:\n  some_pkg: ^1.0.0');
      final cleanReport = await validateLocalSkills(tempDir.path);
      expect(cleanReport.ok, isTrue);

      // Clean up files
      await stewardYaml.delete();
      await pubspec.delete();
    });

    test(
      'steward.yaml custom docs mapping and validator directory pruning',
      () async {
        final originalCwd = Directory.current;
        try {
          Directory.current = tempDir;

          // 1. Create a dummy skills.json
          final skillsJson = File(p.join(tempDir.path, 'skills.json'));
          await skillsJson.writeAsString(jsonEncode({'skills': []}));

          // 2. Create steward.yaml defining custom docs, custom harness name, and a linter
          final stewardYaml = File(p.join(tempDir.path, 'steward.yaml'));
          await stewardYaml.writeAsString('''
harness:
  name: "custom-harness"
  description: "A custom harness description."
docs:
  "Custom Guide": "docs/custom_guide.md"
validators:
  - type: disallowed-substrings
    files:
      - "**/source.dart"
    exclude:
      - "**/target/**"
    substrings:
      - forbidden-word
    message: "FAIL: No forbidden words!"
''');

          // 3. Create Custom Guide file
          final docsDir = Directory(p.join(tempDir.path, 'docs'))..createSync();
          final guideFile = File(p.join(docsDir.path, 'custom_guide.md'))
            ..createSync();
          await guideFile.writeAsString('Custom Guide Content');

          // 4. Create target directory that should be pruned/ignored
          final targetDir = Directory(p.join(tempDir.path, 'target'))
            ..createSync();
          final badTargetFile = File(p.join(targetDir.path, 'source.dart'))
            ..createSync();
          await badTargetFile.writeAsString(
            'forbidden-word inside target folder',
          );

          // 5. Create build directory that should be ignored by default
          final buildDir = Directory(p.join(tempDir.path, 'build'))
            ..createSync();
          final badBuildFile = File(p.join(buildDir.path, 'source.dart'))
            ..createSync();
          await badBuildFile.writeAsString(
            'forbidden-word inside build folder',
          );

          // 6. Create a real file at the root containing the forbidden word to verify it triggers
          final badFile = File(p.join(tempDir.path, 'source.dart'))
            ..createSync();
          await badFile.writeAsString('forbidden-word at root');

          // Test validate fails because of badFile
          var report = await validateLocalSkills(tempDir.path);
          expect(report.ok, isFalse);
          expect(
            report.registryWarnings.any(
              (final w) => w.contains('FAIL: No forbidden words!'),
            ),
            isTrue,
          );
          // Clean badFile, it should now pass because badTargetFile (in target/) and badBuildFile (in build/) are pruned
          await badFile.writeAsString('clean content');
          report = await validateLocalSkills(tempDir.path);
          expect(report.ok, isTrue);

          // Verify steward map prints custom harness name and custom docs
          final buffer = StringBuffer();
          final mapCmd = MapCommand(buffer);
          final runnerMap = CommandRunner<void>('steward', 'test')
            ..addCommand(mapCmd);
          await runnerMap.run(['map']);

          final output = buffer.toString();
          expect(output, contains('# 🧭 custom-harness Agent Map'));
          expect(output, contains('docs/custom_guide.md'));
          expect(output, contains('Custom Guide'));

          // Clean up
          await stewardYaml.delete();
          await guideFile.delete();
          await docsDir.delete();
          await badTargetFile.delete();
          await targetDir.delete();
          await badBuildFile.delete();
          await buildDir.delete();
          await badFile.delete();
        } finally {
          Directory.current = originalCwd;
        }
      },
    );
  });
}

Future<String> _runGitAt(
  final Directory directory,
  final List<String> arguments,
) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: directory.path,
  );
  expect(
    result.exitCode,
    0,
    reason: 'git ${arguments.join(' ')} failed: ${result.stderr}',
  );
  return '${result.stdout}'.trim();
}

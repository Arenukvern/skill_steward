// ignore_for_file: avoid_print
// Deterministic description-based routing check for AX baseline prompts.
// Not an agent router — see evals/ax-routing-baseline/README.md.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/validation/skill_frontmatter.dart';
import 'package:yaml/yaml.dart';

const _guildSkills = [
  'repo-quality-system-lifecycle',
  'repository-governance-lifecycle',
  'multi-agent-handoff',
  'skill-authoring-lifecycle',
  'release-changelog-harness',
  'harness-engineering-lifecycle',
];

void main(final List<String> args) async {
  String? promptsPath;
  String? scenariosPath;
  String skillsDir = 'skills';
  String? outputPath;
  String? gitRef;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--prompts':
        promptsPath = args[++i];
      case '--scenarios':
        scenariosPath = args[++i];
      case '--skills-dir':
        skillsDir = args[++i];
      case '--output':
        outputPath = args[++i];
      case '--git-ref':
        gitRef = args[++i];
      default:
        if (args[i].startsWith('-')) {
          stderr.writeln('Unknown flag: ${args[i]}');
          exit(2);
        }
    }
  }

  if (promptsPath == null || scenariosPath == null) {
    stderr.writeln(
      'Usage: ax_description_routing.dart --prompts <yaml> --scenarios <yaml> '
      '[--skills-dir skills] [--output path] [--git-ref sha]',
    );
    exit(2);
  }

  final repoRoot = _findRepoRoot(Directory.current);
  final skillsRoot = _resolvePath(skillsDir, repoRoot);

  final descriptions = await _loadSkillCorpora(skillsRoot);

  final promptsFile = File(_resolvePath(promptsPath, repoRoot));
  final scenariosFile = File(_resolvePath(scenariosPath, repoRoot));

  final promptDoc = loadYaml(await promptsFile.readAsString());
  final scenarioDoc = loadYaml(await scenariosFile.readAsString());

  final routingResults = <Map<String, Object?>>[];
  var routingPass = 0;
  var routingTotal = 0;

  final prompts = (promptDoc as YamlMap)['prompts'] as YamlList;
  for (final item in prompts) {
    final map = item as YamlMap;
    final id = map['id'] as String;
    final input = map['input'] as String;
    final expected = map['expected_skill'] as String;
    final ranked = _rank(input, descriptions);
    final predicted = ranked.isEmpty ? '' : ranked.first.skill;
    final ok = _routingMatch(expected, predicted, ranked);
    routingTotal++;
    if (ok) routingPass++;
    routingResults.add({
      'id': id,
      'expected_skill': expected,
      'predicted_skill': predicted == '' ? 'none' : predicted,
      'top_scores': ranked
          .take(3)
          .map((final r) => {'skill': r.skill, 'score': r.score})
          .toList(),
      'pass': ok,
    });
  }

  final scenarioResults = <Map<String, Object?>>[];
  var scenarioPass = 0;
  var scenarioTotal = 0;
  var mustNotPass = 0;
  var mustNotTotal = 0;

  final scenarios = (scenarioDoc as YamlMap)['scenarios'] as YamlList;
  for (final item in scenarios) {
    final map = item as YamlMap;
    final id = map['id'] as String;
    final input = map['user_prompt'] as String;
    final expected = map['expected_skill'] as String;
    final mustNot = map['must_not_primary'] as String?;
    final ranked = _rank(input, descriptions);
    final predicted = ranked.isEmpty ? '' : ranked.first.skill;
    final ok = _routingMatch(expected, predicted, ranked);
    scenarioTotal++;
    if (ok) scenarioPass++;

    var mustNotOk = true;
    if (mustNot != null && mustNot.isNotEmpty) {
      mustNotTotal++;
      mustNotOk = predicted != mustNot;
      if (mustNotOk) mustNotPass++;
    }

    scenarioResults.add({
      'id': id,
      'expected_skill': expected,
      'predicted_skill': predicted == '' ? 'none' : predicted,
      'must_not_primary': mustNot,
      'must_not_respected': mustNot == null ? null : mustNotOk,
      'pass': ok,
    });
  }

  final report = <String, Object?>{
    'method': 'description_token_overlap_v1',
    'non_claim': 'Not live agent sessions; deterministic weak router only.',
    'git_ref': gitRef ?? await _gitHead(repoRoot),
    'signals': {
      'routing_accuracy': {
        'prompts_pass': routingPass,
        'prompts_total': routingTotal,
        'prompts_rate': routingTotal == 0 ? 0 : routingPass / routingTotal,
        'scenarios_pass': scenarioPass,
        'scenarios_total': scenarioTotal,
        'scenarios_rate': scenarioTotal == 0 ? 0 : scenarioPass / scenarioTotal,
        'combined_pass': routingPass + scenarioPass,
        'combined_total': routingTotal + scenarioTotal,
        'combined_rate': (routingTotal + scenarioTotal) == 0
            ? 0
            : (routingPass + scenarioPass) / (routingTotal + scenarioTotal),
      },
      'must_not_primary': {
        'pass': mustNotPass,
        'total': mustNotTotal,
        'rate': mustNotTotal == 0 ? null : mustNotPass / mustNotTotal,
      },
      'missed_blockers': 'not_measured',
      'context_kb_before_acting': 'not_measured',
      'loops_past_two': 'not_measured',
    },
    'routing_prompts': routingResults,
    'behavior_scenarios': scenarioResults,
  };

  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (outputPath != null) {
    final out = File(_resolvePath(outputPath, repoRoot));
    out.parent.createSync(recursive: true);
    await out.writeAsString('$encoded\n');
  }
  print(encoded);
}

bool _routingMatch(
  final String expected,
  final String predicted,
  final List<_Rank> ranked,
) {
  final exp = expected == 'none' ? '' : expected;
  final pred = predicted;
  if (exp == pred) return true;
  if (expected == 'none') {
    final top = ranked.isEmpty ? 0 : ranked.first.score;
    // Weak "none": no strong description match.
    return top < 2;
  }
  return false;
}

List<_Rank> _rank(
  final String input,
  final Map<String, _Corpus> descriptions,
) {
  final tokens = _inputTokens(input);
  final scores = <_Rank>[];
  for (final skill in _guildSkills) {
    final corpus = descriptions[skill];
    if (corpus == null) continue;
    var score = 0;
    for (final t in tokens) {
      if (corpus.descriptionLower.contains(t)) score += 2;
      if (corpus.whenLower.contains(t)) score += 1;
    }
    scores.add(_Rank(skill, score));
  }
  scores.sort((final a, final b) => b.score.compareTo(a.score));
  return scores;
}

List<String> _inputTokens(final String input) => input
    .toLowerCase()
    .split(RegExp(r'\W+'))
    .where((final w) => w.length > 4)
    .toSet()
    .toList();

Future<Map<String, _Corpus>> _loadSkillCorpora(final String skillsRoot) async {
  final out = <String, _Corpus>{};
  for (final name in _guildSkills) {
    final file = File(p.join(skillsRoot, name, 'SKILL.md'));
    final content = await file.readAsString();
    final parsed = parseFrontmatter(content);
    final desc = (parsed['description'] ?? '').toLowerCase();
    final when = _extractWhenSection(parsed.body).toLowerCase();
    out[name] = _Corpus(desc, when);
  }
  return out;
}

String _extractWhenSection(final String body) {
  final start = body.toLowerCase().indexOf('## when to use');
  if (start < 0) return '';
  final rest = body.substring(start);
  final end = rest.indexOf(RegExp(r'\n## ', multiLine: true), 1);
  return end < 0 ? rest : rest.substring(0, end);
}

String _resolvePath(final String path, final String repoRoot) {
  if (p.isAbsolute(path)) return p.normalize(path);
  final fromCwd = p.normalize(p.join(Directory.current.path, path));
  if (File(fromCwd).existsSync() || Directory(fromCwd).existsSync()) {
    return fromCwd;
  }
  return p.normalize(p.join(repoRoot, path));
}

String _findRepoRoot(final Directory start) {
  var dir = start;
  while (true) {
    if (File(p.join(dir.path, 'skills.sh.json')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return start.path;
    dir = parent;
  }
}

Future<String> _gitHead(final String repoRoot) async {
  final result = await Process.run(
    'git',
    ['rev-parse', 'HEAD'],
    workingDirectory: repoRoot,
  );
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  return 'unknown';
}

class _Corpus {
  const _Corpus(this.descriptionLower, this.whenLower);
  final String descriptionLower;
  final String whenLower;
}

class _Rank {
  const _Rank(this.skill, this.score);
  final String skill;
  final int score;
}

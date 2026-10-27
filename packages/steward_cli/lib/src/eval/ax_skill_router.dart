/// Deterministic description-based skill router (AX baseline substitute).
///
/// Not production agent routing — scores user prompts against guild skill
/// descriptions and When to / When not sections from SKILL.md.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../validation/skill_frontmatter.dart';

class SkillRoutingProfile {
  const SkillRoutingProfile({
    required this.name,
    required this.description,
    required this.whenToUse,
    required this.whenNotUse,
    required this.skillBodyBytes,
  });

  final String name;
  final String description;
  final String whenToUse;
  final String whenNotUse;
  final int skillBodyBytes;
}

class RoutingDecision {
  const RoutingDecision({
    required this.skill,
    required this.score,
    required this.runnerUp,
    required this.runnerUpScore,
  });

  /// Skill directory name, or `none` when below threshold / ambiguous.
  final String skill;
  final double score;
  final String? runnerUp;
  final double runnerUpScore;

  bool get ambiguous =>
      runnerUp != null && (score - runnerUpScore) < 1.5 && score > 0;
}

/// Loads routing profiles for all installable guild skills under [skillsDir].
Future<List<SkillRoutingProfile>> loadSkillRoutingProfiles(
  final String skillsDir,
) async {
  final dir = Directory(skillsDir);
  if (!dir.existsSync()) return [];

  final profiles = <SkillRoutingProfile>[];
  for (final entry in dir.listSync().whereType<Directory>()) {
    final skillMd = File(p.join(entry.path, 'SKILL.md'));
    if (!skillMd.existsSync()) continue;
    final content = await skillMd.readAsString();
    final parsed = parseFrontmatter(content);
    if (parsed.error != null) continue;
    final name = parsed['name'] ?? p.basename(entry.path);
    final body = parsed.body;
    profiles.add(
      SkillRoutingProfile(
        name: name,
        description: parsed['description'] ?? '',
        whenToUse: _extractSection(body, 'When to use'),
        whenNotUse: _extractSection(body, 'When not to use'),
        skillBodyBytes: skillMd.lengthSync(),
      ),
    );
  }
  profiles.sort((final a, final b) => a.name.compareTo(b.name));
  return profiles;
}

String _extractSection(final String body, final String heading) {
  final pattern = RegExp(
    r'##\s+' + RegExp.escape(heading) + r'\s*\n(.*?)(?=\n##\s+|\Z)',
    dotAll: true,
    caseSensitive: false,
  );
  final match = pattern.firstMatch(body);
  return match?.group(1)?.trim() ?? '';
}

const _routingStopWords = {
  'skill',
  'skills',
  'steward',
  'repository',
  'repo',
  'agent',
  'lifecycle',
  'this',
  'with',
  'that',
  'need',
  'walk',
  'using',
};

List<String> _tokens(final String text) => text
    .toLowerCase()
    .split(RegExp(r'\W+'))
    .where((final w) => w.length > 3 && !_routingStopWords.contains(w))
    .toSet()
    .toList();

double _overlapScore(final List<String> promptTokens, final String corpus) {
  if (promptTokens.isEmpty || corpus.isEmpty) return 0;
  final corpusTokens = _tokens(corpus).toSet();
  final hits = promptTokens.where(corpusTokens.contains).length;
  return hits / promptTokens.length;
}

/// Routes [input] to one skill name or `none`.
RoutingDecision routePrompt(
  final String input,
  final List<SkillRoutingProfile> profiles, {
  final double noneThreshold = 0.12,
}) {
  final promptTokens = _tokens(input);
  final inputLower = input.toLowerCase();

  final scores = <String, double>{};
  for (final profile in profiles) {
    var score = 0.0;
    score += _overlapScore(promptTokens, profile.description) * 3.0;
    score += _overlapScore(promptTokens, profile.whenToUse) * 2.0;
    score -= _overlapScore(promptTokens, profile.whenNotUse) * 2.5;
    // Skill name tokens (e.g. handoff, harness) — weak signal only.
    score += _overlapScore(promptTokens, profile.name.replaceAll('-', ' ')) *
        0.5;
    scores[profile.name] = score;
  }

  final stewardshipCue = RegExp(
    r'\b(steward\.yaml|adr|faq|ecology|governance|harness contract|quality contract|changeset|handoff|baton|north star|mixture.of.experts|dogfood|marketplace skill|disposition|claim audit)\b',
    caseSensitive: false,
  );
  final productNative = RegExp(
    r'\b(implement|build|fix|ship|add)\b.{0,60}\b(feature|component|react|dashboard|button|oauth|formatter|unit test)\b',
    caseSensitive: false,
  );
  if (productNative.hasMatch(input) && !stewardshipCue.hasMatch(inputLower)) {
    return const RoutingDecision(
      skill: 'none',
      score: 0,
      runnerUp: null,
      runnerUpScore: 0,
    );
  }

  String? bestSkill;
  double bestScore = -1;
  String? secondSkill;
  double secondScore = -1;

  for (final entry in scores.entries) {
    if (entry.value > bestScore) {
      secondSkill = bestSkill;
      secondScore = bestScore;
      bestSkill = entry.key;
      bestScore = entry.value;
    } else if (entry.value > secondScore) {
      secondSkill = entry.key;
      secondScore = entry.value;
    }
  }

  if (bestSkill == null || bestScore < noneThreshold) {
    return const RoutingDecision(
      skill: 'none',
      score: 0,
      runnerUp: null,
      runnerUpScore: 0,
    );
  }

  return RoutingDecision(
    skill: bestSkill,
    score: bestScore,
    runnerUp: secondSkill,
    runnerUpScore: secondScore,
  );
}

int skillKbForProfile(
  final List<SkillRoutingProfile> profiles,
  final String skillName,
) {
  if (skillName == 'none') return 0;
  final match = profiles.where((final p) => p.name == skillName);
  if (match.isEmpty) return 0;
  return (match.first.skillBodyBytes / 1024).ceil();
}

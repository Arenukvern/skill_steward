import 'dart:io';

import 'skill_frontmatter.dart';

final RegExp _nameRegex = RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$');

/// Validates the `name` field according to Agent Skills conventions.
///
/// Exact error strings and early-exit behavior are preserved for parity with
/// the reference implementation.
///
/// References:
/// - original Node validateName
/// - evals/fixtures/validate/bad-name-mismatch/SKILL.md
/// - evals/fixtures/validate/invalid-name-format/SKILL.md
List<String> validateName(final String? name, final String dirName) {
  final errors = <String>[];

  if (name == null || name.isEmpty) {
    errors.add('Missing required frontmatter field: name');
    return errors;
  }

  if (name.length > 64) {
    errors.add('name exceeds 64 characters (${name.length})');
  }

  if (!_nameRegex.hasMatch(name)) {
    errors.add(
      'name "$name" invalid: use lowercase a-z, 0-9, hyphens; '
      'no leading/trailing hyphen; no --',
    );
  }

  if (name != dirName) {
    errors.add('name "$name" must match directory "$dirName"');
  }

  return errors;
}

/// Validates the `description` field.
///
/// Exact messages and length limits match the Node version.
///
/// References:
/// - original Node validateDescription
/// - evals/fixtures/validate/good-skill/SKILL.md (valid example)
List<String> validateDescription(final String? description) {
  final errors = <String>[];

  if (description == null || description.isEmpty) {
    errors.add('Missing required frontmatter field: description');
    return errors;
  }

  if (description.length > 1024) {
    errors.add('description exceeds 1024 characters (${description.length})');
  }

  if (description.length < 20) {
    errors.add(
      'description too short; include what the skill does and when to use it',
    );
  }

  return errors;
}

/// Runs all structural checks (frontmatter, name/desc, length, sources, README presence)
/// for a single skill directory.
///
/// This is the core of the Dart port of the original Node validateSkill.
/// It deliberately returns early with only a parse error (plus any pre-parse warnings
/// such as README) to match observable warning behavior on bad frontmatter.
///
/// Improvements over initial port:
/// - Proper [ParsedFrontmatter.lineCount] (direct, not rough formula)
/// - README warning is collected even when frontmatter is missing (but SKILL.md exists)
/// - All messages are byte-for-byte faithful to the JS original.
///
/// See evals/fixtures/validate/* for all exercising cases (has-readme, missing-sources,
/// too-long-body, missing-frontmatter, etc.).
Future<({List<String> errors, List<String> warnings})> validateSkillStructure(
  final String skillPath,
  final String dirName,
) async {
  final warnings = <String>[];
  final errors = <String>[];

  // README check is performed as soon as we know SKILL.md exists (before parse error
  // handling). This matches the placement in the Node script so that a file with
  // present README + bad/missing frontmatter still emits the README warning.
  final skillMdFile = File('$skillPath/SKILL.md');
  if (skillMdFile.existsSync()) {
    final readmeFile = File('$skillPath/README.md');
    if (readmeFile.existsSync()) {
      warnings.add(
        'README.md in skill folder is ignored by agents; use references/ instead',
      );
    }
  }

  // Frontmatter (name + description validation only on success path)
  final parsed = await readAndParseSkill(skillPath);
  if (parsed.error != null) {
    errors.add(parsed.error!);
    return (errors: errors, warnings: warnings);
  }

  errors
    ..addAll(validateName(parsed['name'], dirName))
    ..addAll(validateDescription(parsed['description']));

  // Proper line count using the value computed in parseFrontmatter.
  // This replaces the previous rough (body + raw splits + 2) formula and is more
  // accurate + robust across line endings. The warning text (with ~) is identical.
  if (parsed.lineCount > 500) {
    warnings.add(
      'SKILL.md is ~${parsed.lineCount} lines; '
      'consider moving content to references/ (<500 recommended)',
    );
  }

  if (parsed.body.length < 50) {
    warnings.add('SKILL.md body is very short; add step-by-step instructions');
  }

  // sources.md check (warning only) — performed only on successful frontmatter parse
  // (parity with Node ordering and early returns).
  final sourcesFile = File('$skillPath/references/sources.md');
  if (!sourcesFile.existsSync()) {
    warnings.add(
      'Missing references/sources.md — add curated links (see skill-source-citations)',
    );
  }

  return (errors: errors, warnings: warnings);
}

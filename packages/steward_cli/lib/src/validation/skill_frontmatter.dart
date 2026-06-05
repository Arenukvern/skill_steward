import 'dart:io';
import 'package:yaml/yaml.dart';

/// Very lightweight YAML-ish frontmatter parser (matches the Node behavior exactly).
///
/// Only supports simple `key: value` lines inside the first `--- ... ---` block.
/// Indented continuation lines (e.g. under a `metadata:` map) are ignored because
/// the key regex is anchored with `^` (no leading whitespace), exactly like the
/// implementation in the original Node validator.
///
/// Quote stripping replicates Node's `.replace(/^["']|["']$/g, "").trim()` so that
/// unpaired leading/trailing quotes are removed and final ws trimmed.
///
/// Cross-platform newlines (\r?\n) are handled for splits and delimiters.
///
/// See:
/// - original Node parseFrontmatter + validateSkill
/// - evals/fixtures/validate/good-skill/SKILL.md (exercises extra keys + nesting)
/// - evals/fixtures/validate/invalid-name-format/SKILL.md
ParsedFrontmatter parseFrontmatter(final String content) {
  // Direct line count for the "proper" >500 line warning (improved over rough formula).
  final lineCount = content.split(RegExp(r'\r?\n')).length;

  final match = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---').firstMatch(content);

  if (match == null) {
    return ParsedFrontmatter(
      fields: const {},
      body: '',
      raw: '',
      error: 'Missing YAML frontmatter (--- ... ---)',
      lineCount: lineCount,
    );
  }

  final raw = match.group(1)!;
  final body = content.substring(match.end).trim();

  final fields = <String, String>{};

  // IMPORTANT: do NOT trim lines before matching. Use ^ anchor so that
  // indented keys (under maps) are skipped — matching Node's regex ^ behavior.
  final keyValueRe = RegExp(r'^([a-zA-Z0-9_-]+):\s*(.*)$');
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final m = keyValueRe.firstMatch(line);
    if (m == null) continue;

    final key = m.group(1)!;
    // Replicate Node quote-strip + final trim exactly.
    final value = m.group(2)!.replaceAll(RegExp(r'''^["']|["']$'''), '').trim();

    fields[key] = value;
  }

  // Supplement/override with YAML parser to support block scalars (e.g. >-)
  try {
    final doc = loadYaml(raw);
    if (doc is Map) {
      doc.forEach((final key, final value) {
        if (value is! Map && value is! List && value != null) {
          // Standardize and flatten description fields to single line if multi-line
          var parsedValue = value.toString();
          if (key.toString() == 'description') {
            parsedValue = parsedValue.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          fields[key.toString()] = parsedValue;
        }
      });
    }
  } catch (_) {}

  return ParsedFrontmatter(
    fields: fields,
    body: body,
    raw: raw,
    lineCount: lineCount,
  );
}

/// Reads and parses SKILL.md from the given skill directory.
///
/// Returns a synthetic error result (with lineCount=0) when the file is absent.
/// Otherwise delegates to [parseFrontmatter] (which always provides accurate [lineCount]).
///
/// Mirrors the early-exit in the original Node validateSkill for missing SKILL.md.
Future<ParsedFrontmatter> readAndParseSkill(final String skillPath) async {
  final file = File('$skillPath/SKILL.md');
  if (!file.existsSync()) {
    return const ParsedFrontmatter(
      fields: {},
      body: '',
      raw: '',
      error: 'Missing required file SKILL.md',
    );
  }

  final content = await file.readAsString();
  return parseFrontmatter(content);
}

/// Parsed frontmatter + body from a SKILL.md file.
///
/// Includes [lineCount] (computed with cross-platform splitting) used for the
/// long-file warning in skill_rules.dart.
///
/// This structure + parser behavior is ported from:
///   original Node parseFrontmatter (from validate-skills.mjs)
///
/// See also the golden cases:
///   evals/fixtures/validate/good-skill/SKILL.md (has nested `metadata:` and extra keys)
///   evals/fixtures/validate/missing-frontmatter/SKILL.md
class ParsedFrontmatter {
  const ParsedFrontmatter({
    required this.fields,
    required this.body,
    required this.raw,
    this.error,
    this.lineCount = 0,
  });
  final Map<String, String> fields;
  final String body;
  final String raw;

  final String? error;

  /// Total lines in the original file content (split on \r?\n).
  /// 0 for the synthetic "missing SKILL.md file" error case.
  final int lineCount;

  String? operator [](final String key) => fields[key];
}

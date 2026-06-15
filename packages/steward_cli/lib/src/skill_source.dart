import 'dart:io';

import 'package:path/path.dart' as p;

enum SkillSourceKind {
  githubShorthand,
  httpsGit,
  sshUrl,
  scpLikeSsh,
  localPath,
  fileUrl,
}

class SkillSource {
  const SkillSource({
    required this.original,
    required this.cloneTarget,
    required this.kind,
    this.canonicalLocalPath,
  });

  final String original;
  final String cloneTarget;
  final SkillSourceKind kind;
  final String? canonicalLocalPath;

  bool get isLocal =>
      kind == SkillSourceKind.localPath || kind == SkillSourceKind.fileUrl;

  String get description {
    if (canonicalLocalPath != null) {
      return '$cloneTarget (local: $canonicalLocalPath)';
    }
    return cloneTarget;
  }
}

final _githubShorthandPattern = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');

final _skillNamePattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$');

SkillSource resolveSkillSource(
  final String source,
  final String root, {
  required final bool allowLocalSource,
}) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Skill source must not be empty.');
  }

  if (trimmed.startsWith('http://')) {
    throw ArgumentError(
      'Plain http:// skill sources are not allowed. Use https://, ssh://, git@, or an explicit --allow-local-source path/file:// source for maintainer-only development.',
    );
  }

  if (trimmed.startsWith('https://')) {
    return SkillSource(
      original: source,
      cloneTarget: trimmed,
      kind: SkillSourceKind.httpsGit,
    );
  }

  if (trimmed.startsWith('ssh://')) {
    return SkillSource(
      original: source,
      cloneTarget: trimmed,
      kind: SkillSourceKind.sshUrl,
    );
  }

  if (trimmed.startsWith('git@')) {
    return SkillSource(
      original: source,
      cloneTarget: trimmed,
      kind: SkillSourceKind.scpLikeSsh,
    );
  }

  if (trimmed.startsWith('file://')) {
    _requireLocalSourceAllowed(trimmed, allowLocalSource);
    final filePath = Uri.parse(trimmed).toFilePath();
    final canonicalPath = _canonicalExistingDirectory(filePath);
    return SkillSource(
      original: source,
      cloneTarget: Uri.file(canonicalPath).toString(),
      kind: SkillSourceKind.fileUrl,
      canonicalLocalPath: canonicalPath,
    );
  }

  final localPath = p.isAbsolute(trimmed)
      ? trimmed
      : p.normalize(p.join(root, trimmed));
  if (Directory(localPath).existsSync()) {
    _requireLocalSourceAllowed(trimmed, allowLocalSource);
    final canonicalPath = _canonicalExistingDirectory(localPath);
    return SkillSource(
      original: source,
      cloneTarget: canonicalPath,
      kind: SkillSourceKind.localPath,
      canonicalLocalPath: canonicalPath,
    );
  }

  if (_githubShorthandPattern.hasMatch(trimmed)) {
    return SkillSource(
      original: source,
      cloneTarget: 'https://github.com/$trimmed.git',
      kind: SkillSourceKind.githubShorthand,
    );
  }

  throw ArgumentError(
    'Invalid skill source "$source". Use owner/repo, https://, ssh://, git@, or pass --allow-local-source for an existing local path or file:// source.',
  );
}

void validateSkillName(final String skillName) {
  if (skillName.length > 64) {
    throw ArgumentError(
      'Invalid skill name "$skillName". Maximum length is 64 characters.',
    );
  }

  if (!_skillNamePattern.hasMatch(skillName)) {
    throw ArgumentError(
      'Invalid skill name "$skillName". Skill names must match ${_skillNamePattern.pattern}.',
    );
  }
}

void validateSkillNames(final Iterable<String> skillNames) {
  skillNames.forEach(validateSkillName);
}

String _canonicalExistingDirectory(final String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    throw ArgumentError('Local skill source does not exist: $path');
  }
  return dir.resolveSymbolicLinksSync();
}

void _requireLocalSourceAllowed(
  final String source,
  final bool allowLocalSource,
) {
  if (!allowLocalSource) {
    throw ArgumentError(
      'Local skill source "$source" requires --allow-local-source. Local and file:// sources are maintainer-only development paths, not consumer defaults.',
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/repo_root.dart';
import 'package:test/test.dart';

void main() {
  late final String repoRoot;
  late final String docsDir;
  late final File docsJsonFile;

  setUpAll(() {
    String findRootForTest() {
      try {
        return findRepoRoot(Directory.current);
      } on Object {
        final scriptPath = Platform.script.toFilePath();
        final scriptStart = File(scriptPath).parent;
        return findRepoRoot(scriptStart);
      }
    }

    repoRoot = findRootForTest();
    docsDir = p.join(repoRoot, 'docs');
    docsJsonFile = File(p.join(repoRoot, 'docs.json'));
  });

  group('Documentation Validation Tests', () {
    test('docs.json exists and is valid JSON', () {
      expect(docsJsonFile.existsSync(), isTrue, reason: 'docs.json must exist at repo root');
      final content = docsJsonFile.readAsStringSync();
      expect(() => jsonDecode(content), returnsNormally, reason: 'docs.json must be valid JSON');
    });

    test('docs.json sidebar pages point to existing files', () {
      final content = docsJsonFile.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final sidebar = data['sidebar'] as List?;
      expect(sidebar, isNotNull, reason: 'docs.json must contain a sidebar array');

      final List<String> localHrefs = [];
      for (final group in sidebar!) {
        if (group is Map<String, dynamic>) {
          final pages = group['pages'] as List?;
          if (pages != null) {
            for (final page in pages) {
              if (page is Map<String, dynamic>) {
                final href = page['href'] as String?;
                if (href != null && href.startsWith('/') && !href.startsWith('http')) {
                  localHrefs.add(href);
                }
              }
            }
          }
        }
      }

      for (final href in localHrefs) {
        // Resolve href against docs/ directory
        // E.g., "/NORTH_STAR" -> docs/NORTH_STAR.mdx or docs/NORTH_STAR.md
        // "/decisions/README" -> docs/decisions/README.mdx etc.
        final relativePath = href.substring(1); // remove leading '/'
        
        final List<String> candidatePaths = [];
        if (relativePath.isEmpty) {
          // "/" points to docs/index.mdx or docs/index.md
          candidatePaths.addAll([
            p.join(docsDir, 'index.mdx'),
            p.join(docsDir, 'index.md'),
          ]);
        } else {
          candidatePaths.addAll([
            p.join(docsDir, '$relativePath.mdx'),
            p.join(docsDir, '$relativePath.md'),
            p.join(docsDir, relativePath, 'index.mdx'),
            p.join(docsDir, relativePath, 'index.md'),
          ]);
        }

        final exists = candidatePaths.any((final path) => File(path).existsSync());
        expect(
          exists,
          isTrue,
          reason: 'docs.json links to "$href", but no matching file exists on disk. '
              'Checked paths: $candidatePaths',
        );
      }
    });

    test('All ADR decision files are referenced in docs.json sidebar', () {
      final content = docsJsonFile.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final sidebar = data['sidebar'] as List?;
      expect(sidebar, isNotNull);

      // Collect all hrefs from docs.json
      final Set<String> sidebarHrefs = {};
      for (final group in sidebar!) {
        if (group is Map<String, dynamic>) {
          final pages = group['pages'] as List?;
          if (pages != null) {
            for (final page in pages) {
              if (page is Map<String, dynamic>) {
                final href = page['href'] as String?;
                if (href != null) {
                  sidebarHrefs.add(href);
                }
              }
            }
          }
        }
      }

      // Collect all ADR files under docs/decisions/
      final decisionsDir = Directory(p.join(docsDir, 'decisions'));
      expect(decisionsDir.existsSync(), isTrue, reason: 'docs/decisions/ directory must exist');

      final List<String> missingAdrs = [];
      final files = decisionsDir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          final filename = p.basename(file.path);
          if (filename.startsWith('0') && (filename.endsWith('.mdx') || filename.endsWith('.md'))) {
            // E.g., docs/decisions/0000-use-markdown-architectural-decision-records.mdx
            // maps to /decisions/0000-use-markdown-architectural-decision-records
            final nameWithoutExtension = p.withoutExtension(filename);
            final expectedHref = '/decisions/$nameWithoutExtension';
            if (!sidebarHrefs.contains(expectedHref)) {
              missingAdrs.add(file.path);
            }
          }
        }
      }

      expect(
        missingAdrs,
        isEmpty,
        reason: 'The following ADR files are present on disk but not referenced in docs.json sidebar: '
            '${missingAdrs.map((final path) => p.relative(path, from: repoRoot)).toList()}',
      );
    });

    test('All markdown links in docs/ and root markdown files are valid', () {
      final List<File> filesToCheck = [];

      // 1. Collect all .md and .mdx files under docs/
      if (Directory(docsDir).existsSync()) {
        final docFiles = Directory(docsDir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((final file) => file.path.endsWith('.md') || file.path.endsWith('.mdx'));
        filesToCheck.addAll(docFiles);
      }

      // 2. Add root AGENTS.md and README.md
      final rootAgents = File(p.join(repoRoot, 'AGENTS.md'));
      if (rootAgents.existsSync()) filesToCheck.add(rootAgents);

      final rootReadme = File(p.join(repoRoot, 'README.md'));
      if (rootReadme.existsSync()) filesToCheck.add(rootReadme);

      final rootLicense = File(p.join(repoRoot, 'LICENSE'));
      if (rootLicense.existsSync()) filesToCheck.add(rootLicense);

      final rootContributing = File(p.join(repoRoot, 'CONTRIBUTING.md'));
      if (rootContributing.existsSync()) filesToCheck.add(rootContributing);

      final linkRegex = RegExp(r'!?\[[^\]]*\]\(([^)]+)\)');

      for (final file in filesToCheck) {
        final content = file.readAsStringSync();
        final matches = linkRegex.allMatches(content);

        for (final match in matches) {
          final fullTarget = match.group(1)!;

          // Ignore external links, mailto links, etc.
          if (fullTarget.startsWith('http://') ||
              fullTarget.startsWith('https://') ||
              fullTarget.startsWith('mailto:') ||
              fullTarget.startsWith('tel:') ||
              fullTarget.startsWith('data:')) {
            continue;
          }

          // Ignore self-anchors
          if (fullTarget.startsWith('#')) {
            continue;
          }

          // Strip anchors or query parameters from link target
          // E.g., "DX_FAQ.mdx#🧭-router" -> "DX_FAQ.mdx"
          // E.g., "/decisions/0012-adopt-visual-brand-identity-system?some-param" -> "/decisions/0012-adopt-visual-brand-identity-system"
          var targetPath = fullTarget;
          if (targetPath.contains('#')) {
            targetPath = targetPath.split('#').first;
          }
          if (targetPath.contains('?')) {
            targetPath = targetPath.split('?').first;
          }

          if (targetPath.isEmpty) {
            continue; // link to "#anchor" in same file after stripping anchor
          }

          // Resolve the path depending on if it is absolute-style (starts with /) or relative
          final File resolvedFile;
          if (targetPath.startsWith('/')) {
            // Check both:
            // 1. relative to docs/ folder (e.g. /decisions/README -> docs/decisions/README)
            // 2. relative to repo root (e.g. /CONTRIBUTING.md -> CONTRIBUTING.md)
            final option1 = File(p.join(docsDir, targetPath.substring(1)));
            final option2 = File(p.join(repoRoot, targetPath.substring(1)));
            
            if (option1.existsSync() || _checkFileWithSuffixes(option1)) {
              resolvedFile = option1;
            } else {
              resolvedFile = option2;
            }
          } else {
            // Resolve relative to the directory of the file containing the link
            resolvedFile = File(p.normalize(p.join(p.dirname(file.path), targetPath)));
          }

          final exists = resolvedFile.existsSync() ||
              Directory(resolvedFile.path).existsSync() ||
              _checkFileWithSuffixes(resolvedFile);
          
          expect(
            exists,
            isTrue,
            reason: 'Broken link found in file: ${p.relative(file.path, from: repoRoot)}\n'
                'Link text target: "$fullTarget" (resolved to: "${p.relative(resolvedFile.path, from: repoRoot)}")\n'
                'The resolved file/directory does not exist on disk.',
          );
        }
      }
    });
  });
}

/// Helper that checks if a file exists when common markdown extensions/index files are appended.
bool _checkFileWithSuffixes(final File file) {
  final path = file.path;
  final suffixes = [
    '.mdx',
    '.md',
    '/index.mdx',
    '/index.md',
  ];
  for (final suffix in suffixes) {
    if (File('$path$suffix').existsSync()) {
      return true;
    }
  }
  return false;
}

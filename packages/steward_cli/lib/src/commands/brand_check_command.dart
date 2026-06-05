import 'dart:io';
import 'package:args/command_runner.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

class BrandCheckCommand extends Command {

  BrandCheckCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'The file to check against brand guidelines.',
    );
    argParser.addOption(
      'text',
      abbr: 't',
      help: 'Inline text to check against brand guidelines.',
    );
  }
  @override
  final name = 'brand-check';

  @override
  final description =
      'Static linter to enforce brand tone and prevent banned jargon usage.';

  @override
  Future<void> run() async {
    final fileArg = argResults?['file'] as String?;
    final textArg = argResults?['text'] as String?;

    if (fileArg == null && textArg == null) {
      stdout.writeln('Error: Must provide either --file or --text.');
      exitCode = 1;
      return;
    }

    final root = findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);

    final bannedWordsDynamic =
        config.branding['banned_words'] as List<dynamic>? ?? [];
    final bannedWords = bannedWordsDynamic.map((final e) => e.toString()).toList();

    if (bannedWords.isEmpty) {
      stdout.writeln(
        'No banned_words configured in steward.yaml branding block.',
      );
      return;
    }

    String contentToCheck = '';
    if (fileArg != null) {
      final file = File(fileArg);
      if (!file.existsSync()) {
        stdout.writeln('Error: File not found: $fileArg');
        exitCode = 1;
        return;
      }

      final ignoredPaths =
          config.branding['ignored_paths'] as List<dynamic>? ?? [];
      final isIgnored = ignoredPaths.any((final p) => fileArg.contains(p.toString()));
      if (isIgnored) {
        stdout.writeln('✓ Brand identity check passed (ignored path).');
        return;
      }

      contentToCheck = await file.readAsString();
    } else if (textArg != null) {
      contentToCheck = textArg;
    }

    final violations = <String>[];
    for (final word in bannedWords) {
      if (contentToCheck.toLowerCase().contains(word.toLowerCase())) {
        violations.add(word);
      }
    }

    if (violations.isNotEmpty) {
      stdout.writeln('Validation failed: Brand identity banned words used.');
      stdout.writeln(
        r'Please remove the following jargon: ${violations.join(", ")}',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('✓ Brand identity check passed.');
  }
}

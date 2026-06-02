import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  // Resolve the script location to find package roots relative to it
  final scriptPath = File(Platform.script.toFilePath()).canonicalize().path;
  final toolDir = Directory(p.dirname(scriptPath));
  final stewardCliDir = toolDir.parent;
  final rootDir = stewardCliDir.parent.parent;

  final pkgFile = File(p.join(rootDir.path, 'package.json'));
  final pubspecFile = File(p.join(stewardCliDir.path, 'pubspec.yaml'));

  if (!pkgFile.existsSync()) {
    stderr.writeln('Error: package.json not found at ${pkgFile.path}');
    exit(1);
  }

  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found at ${pubspecFile.path}');
    exit(1);
  }

  final pkgJson = jsonDecode(pkgFile.readAsStringSync()) as Map<String, dynamic>;
  final version = pkgJson['version'] as String?;

  if (version == null) {
    stderr.writeln('Error: No version found in package.json');
    exit(1);
  }

  var pubspec = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'^version:\s*[^\r\n]+', multiLine: true);

  if (!versionRegex.hasMatch(pubspec)) {
    stderr.writeln('Error: Could not find version line in pubspec.yaml');
    exit(1);
  }

  pubspec = pubspec.replaceFirst(versionRegex, 'version: $version');
  pubspecFile.writeAsStringSync(pubspec);

  stdout.writeln('Synced version: packages/steward_cli/pubspec.yaml is now at $version');
}

extension on File {
  File canonicalize() => File(p.canonicalize(path));
}

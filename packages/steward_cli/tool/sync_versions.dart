import 'dart:convert';
import 'dart:io';

void main() {
  // Resolve the script location to find package roots relative to it
  final scriptPath = File(Platform.script.toFilePath()).resolveSymbolicLinksSync();
  final pathSeparator = Platform.pathSeparator;

  // scriptPath is: .../packages/steward_cli/tool/sync_versions.dart
  // dirname of scriptPath is .../packages/steward_cli/tool
  final toolDirPath = scriptPath.substring(0, scriptPath.lastIndexOf(pathSeparator));
  // dirname of toolDir is .../packages/steward_cli
  final stewardCliDirPath = toolDirPath.substring(0, toolDirPath.lastIndexOf(pathSeparator));
  // dirname of stewardCliDir is .../packages
  final packagesDirPath = stewardCliDirPath.substring(0, stewardCliDirPath.lastIndexOf(pathSeparator));
  // dirname of packages is ... (root)
  final rootDirPath = packagesDirPath.substring(0, packagesDirPath.lastIndexOf(pathSeparator));

  final pkgFile = File('$rootDirPath${pathSeparator}package.json');
  final pubspecFile = File('$stewardCliDirPath${pathSeparator}pubspec.yaml');

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

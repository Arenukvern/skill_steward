import 'dart:io';

/// Resolves pnpm (preferred) or npm for running package.json scripts.
class PackageRunner {
  PackageRunner({required this.executable, required this.kind});

  final String executable;
  final String kind; // `pnpm` | `npm`

  List<String> runArgs(String script) => ['run', script];

  static Future<PackageRunner?> resolve() async {
    for (final kind in ['pnpm', 'npm']) {
      final which = await Process.run('which', [kind]);
      if (which.exitCode == 0) {
        final path = (which.stdout as String).trim().split('\n').first;
        if (path.isNotEmpty) return PackageRunner(executable: path, kind: kind);
      }
    }
    return null;
  }
}

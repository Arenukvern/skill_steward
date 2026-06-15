import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/skill_source.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_skill_source_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('accepts durable git source forms by default', () {
    expect(
      resolveSkillSource(
        'arenukvern/skill_steward',
        tempDir.path,
        allowLocalSource: false,
      ).cloneTarget,
      'https://github.com/arenukvern/skill_steward.git',
    );
    expect(
      resolveSkillSource(
        'https://github.com/arenukvern/skill_steward.git',
        tempDir.path,
        allowLocalSource: false,
      ).kind,
      SkillSourceKind.httpsGit,
    );
    expect(
      resolveSkillSource(
        'ssh://git@github.com/arenukvern/skill_steward.git',
        tempDir.path,
        allowLocalSource: false,
      ).kind,
      SkillSourceKind.sshUrl,
    );
    expect(
      resolveSkillSource(
        'git@github.com:arenukvern/skill_steward.git',
        tempDir.path,
        allowLocalSource: false,
      ).kind,
      SkillSourceKind.scpLikeSsh,
    );
  });

  test('rejects plain http sources', () {
    expect(
      () => resolveSkillSource(
        'http://example.invalid/repo.git',
        tempDir.path,
        allowLocalSource: false,
      ),
      throwsArgumentError,
    );
  });

  test('requires explicit opt-in for local path and file sources', () {
    final repoDir = Directory(p.join(tempDir.path, 'source-repo'))
      ..createSync();

    expect(
      () => resolveSkillSource(
        repoDir.path,
        tempDir.path,
        allowLocalSource: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => resolveSkillSource(
        repoDir.uri.toString(),
        tempDir.path,
        allowLocalSource: false,
      ),
      throwsArgumentError,
    );

    final localSource = resolveSkillSource(
      repoDir.path,
      tempDir.path,
      allowLocalSource: true,
    );
    expect(localSource.kind, SkillSourceKind.localPath);
    expect(localSource.canonicalLocalPath, repoDir.resolveSymbolicLinksSync());

    final fileSource = resolveSkillSource(
      repoDir.uri.toString(),
      tempDir.path,
      allowLocalSource: true,
    );
    expect(fileSource.kind, SkillSourceKind.fileUrl);
    expect(fileSource.canonicalLocalPath, repoDir.resolveSymbolicLinksSync());
  });

  test('rejects path-shaped skill names', () {
    expect(() => validateSkillName('../escape'), throwsArgumentError);
    expect(() => validateSkillName('nested/skill'), throwsArgumentError);
    expect(() => validateSkillName('valid-skill'), returnsNormally);
    expect(() => validateSkillName('valid-skill-1'), returnsNormally);
    expect(() => validateSkillName('valid-skill_1'), throwsArgumentError);
  });
}

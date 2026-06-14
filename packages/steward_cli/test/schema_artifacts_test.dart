import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('steward v1 schema matches baseline and harness action policy', () {
    final schemaFile = File(
      p.normalize(
        p.join(
          Directory.current.path,
          '..',
          '..',
          'docs',
          'schemas',
          'steward-v1.schema.json',
        ),
      ),
    );
    final schema = jsonDecode(schemaFile.readAsStringSync()) as Map;
    final required = schema['required'] as List;
    final properties = schema['properties'] as Map;
    final stewardship = properties['stewardship'] as Map;
    final stewardshipRequired = stewardship['required'] as List;
    final actions = properties['actions'] as Map;
    final probes = properties['probes'] as Map;
    final allOf = schema['allOf'] as List;

    expect(required, containsAll(['actions', 'probes']));
    expect(actions.containsKey('minProperties'), isFalse);
    expect(probes.containsKey('minProperties'), isFalse);
    expect(stewardshipRequired, contains('repo_quality'));

    final repo = properties['repo'] as Map;
    final repoProperties = repo['properties'] as Map;
    final archetype = repoProperties['archetype'] as Map;
    expect(
      archetype['enum'],
      containsAll([
        'app',
        'library',
        'cli_tool',
        'plugin',
        'harness',
        'meta_governance',
      ]),
    );

    final harnessConditional =
        allOf.singleWhere((final item) => (item as Map).containsKey('if'))
            as Map;
    final then = harnessConditional['then'] as Map;
    final thenProperties = then['properties'] as Map;
    expect(thenProperties['actions'], containsPair('minProperties', 1));
    expect(thenProperties['probes'], containsPair('minProperties', 1));
  });
}

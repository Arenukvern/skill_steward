import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/mcp_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_mcp_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('telemetry trace file escapes disable logging target', () async {
    final outside = Directory.systemTemp.createTempSync('steward_mcp_outside_');
    addTearDown(() {
      if (outside.existsSync()) {
        outside.deleteSync(recursive: true);
      }
    });
    await Link(p.join(tempDir.path, 'linked-out')).create(outside.path);

    expect(
      mcpTelemetryTraceFile(tempDir.path, 'linked-out/trace.json'),
      isNull,
    );
  });

  test('document resource paths fail closed on symlink escapes', () async {
    final outside = Directory.systemTemp.createTempSync('steward_mcp_outside_');
    addTearDown(() {
      if (outside.existsSync()) {
        outside.deleteSync(recursive: true);
      }
    });
    await Link(p.join(tempDir.path, 'linked-out')).create(outside.path);

    expect(mcpDocumentPath(tempDir.path, 'linked-out/doc.md'), isNull);
    expect(
      mcpDocumentPath(tempDir.path, 'docs/doc.md'),
      p.join(tempDir.resolveSymbolicLinksSync(), 'docs', 'doc.md'),
    );
  });
}

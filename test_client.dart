import 'dart:convert';
import 'dart:io';

void main() async {
  final process = await Process.start('dart', [
    '/Users/anton/mcp/agent_guild/packages/steward_cli/bin/steward.dart',
    'mcp',
  ]);

  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
    if (data.contains('"id":2')) {
      exit(0);
    }
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    print('STDERR: $data');
  });

  process.stdin.writeln(
    '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}',
  );

  await Future.delayed(Duration(seconds: 1));

  process.stdin.writeln(
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"steward_run_pipeline_validate","arguments":{}},"id":2}',
  );
}

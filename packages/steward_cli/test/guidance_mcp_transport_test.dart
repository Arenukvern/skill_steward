import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/blocked_command.dart';
import 'package:test/test.dart';

import 'action_discovery_commands_test.dart' show validStewardV1;

void main() {
  test(
    'stdio guidance, explicit prompts and resources stay read-only',
    () async {
      final root = Directory.systemTemp.createTempSync('guidance_mcp_');
      File(p.join(root.path, 'skills.json')).writeAsStringSync('{"skills":[]}');
      File(
        p.join(root.path, 'steward.yaml'),
      ).writeAsStringSync(validStewardV1());
      final sourceRoot = Directory.current.path;
      final process = await Process.start(Platform.resolvedExecutable, [
        '--packages=${p.join(sourceRoot, '.dart_tool/package_config.json')}',
        p.join(sourceRoot, 'bin/steward.dart'),
        'mcp',
      ], workingDirectory: root.path);
      final replies = <int, Completer<Map<String, dynamic>>>{};
      final errors = StringBuffer();
      final stderr = process.stderr
          .transform(utf8.decoder)
          .listen(errors.write);
      final stdout = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((final line) {
            final decoded = jsonDecode(line) as Map<String, dynamic>;
            final id = decoded['id'];
            if (id is int && replies[id] != null) {
              replies[id]!.complete(decoded);
            }
          });
      var nextId = 0;
      Future<Map<String, dynamic>> call(
        final String method,
        final Map<String, dynamic> params,
      ) async {
        final id = ++nextId;
        final pending = Completer<Map<String, dynamic>>();
        replies[id] = pending;
        process.stdin.writeln(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': params,
          }),
        );
        final response = await pending.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw StateError('MCP did not respond: $errors'),
        );
        expect(response['error'], isNull);
        return response['result'] as Map<String, dynamic>;
      }

      try {
        final initialized = await call('initialize', {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'guidance-test', 'version': '1'},
        });
        expect(initialized['capabilities'], contains('prompts'));
        final menu = await call('tools/list', {});
        final tools = (menu['tools'] as List).cast<Map<String, dynamic>>();
        expect(
          tools.map((final t) => t['name']),
          contains('steward_explain_result'),
        );
        expect(
          tools.map((final t) => t['name']),
          isNot(contains('steward_run_pipeline')),
        );
        final doctor = await call('tools/call', {'name': 'steward_doctor'});
        expect(doctor['isError'], isNot(true));
        final doctorFacts =
            jsonDecode(
                  ((doctor['content'] as List).single as Map)['text'] as String,
                )
                as Map;
        expect(doctorFacts, isNot(contains('guidance')));
        final advisedDoctor = await call('tools/call', {
          'name': 'steward_doctor',
          'arguments': {'guidance': true},
        });
        final doctorAdvice =
            jsonDecode(
                  ((advisedDoctor['content'] as List).single as Map)['text']
                      as String,
                )
                as Map;
        expect(doctorAdvice.remove('guidance'), isA<Map>());
        expect(doctorAdvice, doctorFacts);

        final oversized = await call('tools/call', {
          'name': 'steward_explain_result',
          'arguments': {
            'result': {'raw': 'x' * 16001},
          },
        });
        expect(oversized['isError'], isTrue);
        const observed = {'status': 'blocked_invalid_config'};
        final direct = await explainBlockedPayload(
          root.path,
          inputJson: jsonEncode(observed),
          goal: 'Preserve the original goal',
        );
        final explained = await call('tools/call', {
          'name': 'steward_explain_result',
          'arguments': {
            'result': observed,
            'goal': 'Preserve the original goal',
          },
        });
        final text =
            ((explained['content'] as List).single as Map)['text'] as String;
        final payload = jsonDecode(text) as Map<String, dynamic>;
        expect(payload['guidance'], direct['guidance']);
        final prompts = await call('prompts/list', {});
        expect((prompts['prompts'] as List).length, 2);
        final prompt = await call('prompts/get', {
          'name': 'explain-result',
          'arguments': {
            'result': jsonEncode(observed),
            'goal': 'Preserve the original goal',
          },
        });
        expect(prompt['messages'], isNotEmpty);
        final method = await call('resources/read', {
          'uri': 'steward://guidance/method',
        });
        expect(method['contents'], isNotEmpty);
        expect(
          File(p.join(root.path, 'steward.yaml')).readAsStringSync(),
          validStewardV1(),
        );
      } finally {
        process.kill();
        await process.exitCode.timeout(const Duration(seconds: 5));
        await stdout.cancel();
        await stderr.cancel();
        root.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

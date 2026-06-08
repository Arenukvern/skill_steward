import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';

import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Starts the `steward` MCP server over stdio.
///
/// NOTE: This uses a simplified JSON-per-line transport for testing.
/// Real MCP clients (Claude, Cursor) use Content-Length framing.
/// For production use, integrate with `dart_mcp`'s built-in transport.
class McpCommand extends Command<void> {
  @override
  final name = 'mcp';

  @override
  final description = 'Starts the Steward MCP server (stdio transport).';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);

    final server = json_rpc.Server(
      StreamChannel.withGuarantees(
        stdin.transform(utf8.decoder).transform(const LineSplitter()),
        StreamController<String>(sync: true, onListen: () {})
          ..stream.listen((final msg) {
            stdout.writeln(msg);
          }),
      ),
    );
    void registerRpc(final String method, final Function callback) {
      server.registerMethod(method, callback);
    }

    // Register Initialize
    registerRpc(
      'initialize',
      (final json_rpc.Parameters params) => {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}, 'resources': {}},
        'serverInfo': {'name': 'steward-mcp', 'version': '0.3.4'},
        'instructions':
            'You are operating in a repository governed by Skill Steward. '
            'This MCP surface is experimental. '
            'For steward/v1 repositories it exposes read-only action discovery only. '
            'Do not permanently mutate steward.yaml through MCP. '
            'If you discover a new automation or complex fix, capture an unknown case or propose a typed action candidate for review.',
      },
    );

    registerRpc('notifications/initialized', (
      final json_rpc.Parameters params,
    ) {
      // Just ack
    });

    // Register Tools List
    registerRpc('tools/list', (final json_rpc.Parameters params) {
      final tools = <Map<String, dynamic>>[];

      if (config.isV1) {
        tools
          ..add({
            'name': 'steward_list_actions',
            'description':
                'List typed Steward actions without executing repository commands.',
            'inputSchema': {'type': 'object', 'properties': {}},
          })
          ..add({
            'name': 'steward_inspect_action',
            'description':
                'Inspect one typed Steward action by exact id without executing it.',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': 'string',
                  'description': 'The exact action id from steward.yaml.',
                },
              },
              'required': ['id'],
            },
          });
      } else {
        // Thin Router approach: expose a single native tool for legacy pipelines.
        tools.add({
          'name': 'steward_run_pipeline',
          'description':
              'Execute a legacy pipeline by precise name. Experimental unsafe path: use only after explicit human approval.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'name': {
                'type': 'string',
                'description':
                    'The exact name of the pipeline from steward.yaml to execute.',
              },
              'confirm_legacy_unsafe': {
                'type': 'boolean',
                'description':
                    'Must be true to acknowledge legacy bash execution without typed action policy.',
              },
            },
            'required': ['name', 'confirm_legacy_unsafe'],
          },
        });
      }

      return {'tools': tools};
    });

    // Register Tools Call
    registerRpc('tools/call', (final json_rpc.Parameters params) async {
      final name = params['name'].asString;

      // Start tracing logic
      final telemetryEnabled =
          !config.isV1 && config.telemetry['enabled'] == true;
      final traceFile =
          config.telemetry['trace_file'] as String? ?? '.steward_trace.json';

      void logTelemetry({
        required final bool isError,
        required final String resultOrError,
      }) {
        if (!telemetryEnabled) return;
        try {
          final file = File(p.join(root, traceFile));
          final rawArgs = params.value;
          final entry = {
            'timestamp': DateTime.now().toIso8601String(),
            'tool': name,
            'arguments': rawArgs is Map
                ? (rawArgs['arguments'] as Map?) ?? {}
                : {},
            'isError': isError,
            'result': resultOrError,
          };
          file.writeAsStringSync(
            '${jsonEncode(entry)}\n',
            mode: FileMode.append,
          );
        } on Exception catch (_) {
          // Telemetry should never crash the server.
        }
      }

      String capOutput(final String output) {
        const maxOutputChars = 200000;
        if (output.length <= maxOutputChars) return output;
        return '${output.substring(0, maxOutputChars)}\n[steward: output truncated at $maxOutputChars characters]';
      }

      if (name == 'steward_declare_pipeline' ||
          name == 'steward_update_pipeline' ||
          name == 'steward_delete_pipeline') {
        const message =
            'Permanent steward.yaml mutation through MCP is disabled. Capture an unknown case or propose a typed action candidate for review.';
        logTelemetry(isError: true, resultOrError: message);
        return {
          'isError': true,
          'content': [
            {'type': 'text', 'text': message},
          ],
        };
      }

      if (name == 'steward_list_actions') {
        if (!config.isV1) {
          const message = 'Typed action discovery requires schema: steward/v1.';
          logTelemetry(isError: true, resultOrError: message);
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': message},
            ],
          };
        }
        final payload = {
          'schema_version': 'steward.actions.v1',
          'actions': config.typedActions
              .map((final action) => action.summaryJson())
              .toList(),
        };
        final out = const JsonEncoder.withIndent('  ').convert(payload);
        logTelemetry(isError: false, resultOrError: out);
        return {
          'content': [
            {'type': 'text', 'text': out},
          ],
        };
      }

      if (name == 'steward_inspect_action') {
        if (!config.isV1) {
          const message =
              'Typed action inspection requires schema: steward/v1.';
          logTelemetry(isError: true, resultOrError: message);
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': message},
            ],
          };
        }
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final actionId = arguments['id'] as String?;
        StewardAction? action;
        for (final candidate in config.typedActions) {
          if (candidate.id == actionId) {
            action = candidate;
            break;
          }
        }
        if (action == null) {
          final message = 'Typed action "$actionId" not found.';
          logTelemetry(isError: true, resultOrError: message);
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': message},
            ],
          };
        }
        final out = const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'steward.action.v1',
          'action': action.toJson(),
        });
        logTelemetry(isError: false, resultOrError: out);
        return {
          'content': [
            {'type': 'text', 'text': out},
          ],
        };
      }

      if (name == 'steward_run_pipeline') {
        if (config.isV1) {
          const message =
              'Legacy pipeline execution is disabled for schema: steward/v1. Use typed action discovery instead.';
          logTelemetry(isError: true, resultOrError: message);
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': message},
            ],
          };
        }
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final pipelineName = arguments['name'] as String?;
        final confirmed = arguments['confirm_legacy_unsafe'] == true;
        if (pipelineName == null) {
          logTelemetry(isError: true, resultOrError: 'Missing pipeline name.');
          return {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text': 'Error: Missing pipeline name argument.',
              },
            ],
          };
        }
        if (!confirmed) {
          const message =
              'Legacy pipeline execution requires confirm_legacy_unsafe: true after explicit human approval.';
          logTelemetry(isError: true, resultOrError: message);
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': message},
            ],
          };
        }

        final pipelineConfig = config.pipelines[pipelineName];
        if (pipelineConfig is Map) {
          final cmd = pipelineConfig['cmd'] as String?;
          if (cmd == null) {
            logTelemetry(
              isError: true,
              resultOrError: 'Pipeline "$pipelineName" has no cmd field.',
            );
            return {
              'isError': true,
              'content': [
                {
                  'type': 'text',
                  'text': 'Error: Pipeline "$pipelineName" has no cmd field.',
                },
              ],
            };
          }

          try {
            final result =
                await Process.run('bash', [
                  '-c',
                  cmd,
                ], workingDirectory: root).timeout(
                  const Duration(seconds: 120),
                  onTimeout: () =>
                      ProcessResult(0, 124, '', 'Timed out after 120 seconds.'),
                );
            final out = capOutput('${result.stdout}\n${result.stderr}'.trim());
            logTelemetry(isError: result.exitCode != 0, resultOrError: out);
            return {
              'content': [
                {
                  'type': 'text',
                  'text': out.isEmpty ? 'Pipeline executed successfully.' : out,
                },
              ],
              if (result.exitCode != 0) 'isError': true,
            };
          } on Exception catch (e) {
            logTelemetry(isError: true, resultOrError: e.toString());
            return {
              'isError': true,
              'content': [
                {'type': 'text', 'text': 'Error: $e'},
              ],
            };
          }
        } else {
          logTelemetry(
            isError: true,
            resultOrError:
                'Pipeline "$pipelineName" not found in steward.yaml.',
          );
          return {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text':
                    'Error: Pipeline "$pipelineName" not found in steward.yaml. Please read the file first.',
              },
            ],
          };
        }
      }

      logTelemetry(isError: true, resultOrError: 'Method not found');
      throw json_rpc.RpcException.methodNotFound(name);
    });

    // Register Resources List
    registerRpc('resources/list', (final json_rpc.Parameters params) {
      final resources = <Map<String, dynamic>>[];
      if (config.docs.isNotEmpty) {
        for (final entry in config.docs.entries) {
          final docName = entry.key;
          resources.add({
            'uri': 'steward://docs/$docName',
            'name': docName,
            'description': 'Repository governance document: $docName',
            'mimeType': 'text/markdown',
          });
        }
      }
      return {'resources': resources};
    });

    // Register Resources Read
    registerRpc('resources/read', (final json_rpc.Parameters params) async {
      final uri = params['uri'].asString;
      if (uri.startsWith('steward://docs/')) {
        final docName = uri.replaceFirst('steward://docs/', '');
        final docPath = config.docs[docName];
        if (docPath != null) {
          final resolvedPath = p.normalize(p.join(root, docPath));
          final rootPath = p.normalize(root);
          if (resolvedPath != rootPath && !p.isWithin(rootPath, resolvedPath)) {
            return {
              'contents': [
                {
                  'uri': uri,
                  'mimeType': 'text/plain',
                  'text': 'Document path is outside the repository root.',
                },
              ],
            };
          }
          final file = File(resolvedPath);
          if (file.existsSync()) {
            final content = await file.readAsString();
            return {
              'contents': [
                {'uri': uri, 'mimeType': 'text/markdown', 'text': content},
              ],
            };
          } else {
            return {
              'contents': [
                {
                  'uri': uri,
                  'mimeType': 'text/plain',
                  'text': 'Document not found.',
                },
              ],
            };
          }
        }
      }

      throw json_rpc.RpcException.invalidParams('Resource not found: $uri');
    });

    await server.listen();
  }
}

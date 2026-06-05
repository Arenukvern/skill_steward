import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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

    // Register Initialize
    server.registerMethod('initialize', (final json_rpc.Parameters params) => {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}, 'resources': {}},
        'serverInfo': {'name': 'steward-mcp', 'version': '0.3.4'},
        'instructions':
            'You are operating in a repository governed by Skill Steward. '
            'Do not run complex bash scripts manually. '
            'Use the provided steward_run_pipeline_* tools. '
            'If you discover a new automation or complex fix, use the steward_declare_pipeline tool to permanently save it.',
      });

    server.registerMethod('notifications/initialized', (
      final json_rpc.Parameters params,
    ) {
      // Just ack
    });

    // Register Tools List
    server.registerMethod('tools/list', (final json_rpc.Parameters params) {
      final tools = <Map<String, dynamic>>[];

      // Thin Router approach: Expose a single native tool for pipelines
      tools.add({
        'name': 'steward_run_pipeline',
        'description':
            'Execute a pipeline by its precise name. You must first read steward.yaml to find the exact pipeline name you want to run.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description':
                  'The exact name of the pipeline from steward.yaml to execute.',
            },
          },
          'required': ['name'],
        },
      });

      tools.add({
        'name': 'steward_declare_pipeline',
        'description':
            'Declare a new pipeline permanently in steward.yaml so that all future agents can access it.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description':
                  'A short identifier for the pipeline (e.g. fix_gltf_splat)',
            },
            'cmd': {
              'type': 'string',
              'description': 'The exact bash command to execute.',
            },
            'desc': {
              'type': 'string',
              'description':
                  'A human-readable description of what this automation does.',
            },
          },
          'required': ['name', 'cmd', 'desc'],
        },
      });

      tools.add({
        'name': 'steward_update_pipeline',
        'description': 'Update an existing pipeline in steward.yaml.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The exact name of the pipeline to update.',
            },
            'cmd': {'type': 'string', 'description': 'The new bash command.'},
            'desc': {'type': 'string', 'description': 'The new description.'},
          },
          'required': ['name', 'cmd', 'desc'],
        },
      });

      tools.add({
        'name': 'steward_delete_pipeline',
        'description': 'Delete an existing pipeline from steward.yaml.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The exact name of the pipeline to delete.',
            },
          },
          'required': ['name'],
        },
      });

      return {'tools': tools};
    });

    // Register Tools Call
    server.registerMethod('tools/call', (
      final json_rpc.Parameters params,
    ) async {
      final name = params['name'].asString;

      // Start tracing logic
      final telemetryEnabled = config.telemetry['enabled'] == true;
      final traceFile =
          config.telemetry['trace_file'] as String? ?? '.steward_trace.json';

      void logTelemetry(final bool isError, final String resultOrError) {
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

      if (name == 'steward_run_pipeline') {
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final pipelineName = arguments['name'] as String?;
        if (pipelineName == null) {
          logTelemetry(true, 'Missing pipeline name.');
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

        final pipelineConfig = config.pipelines[pipelineName];
        if (pipelineConfig is Map) {
          final cmd = pipelineConfig['cmd'] as String?;
          if (cmd == null) {
            logTelemetry(true, 'Pipeline "$pipelineName" has no cmd field.');
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
            final result = await Process.run('bash', [
              '-c',
              cmd,
            ], workingDirectory: root);
            final out = '${result.stdout}\n${result.stderr}'.trim();
            logTelemetry(result.exitCode != 0, out);
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
            logTelemetry(true, e.toString());
            return {
              'isError': true,
              'content': [
                {'type': 'text', 'text': 'Error: $e'},
              ],
            };
          }
        } else {
          logTelemetry(
            true,
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

      if (name == 'steward_declare_pipeline') {
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final pipelineName = arguments['name'] as String;
        final cmd = arguments['cmd'] as String;
        final desc = arguments['desc'] as String;

        final file = File(p.join(root, 'steward.yaml'));
        if (!file.existsSync()) {
          logTelemetry(true, 'steward.yaml not found at root.');
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': 'steward.yaml not found at root.'},
            ],
          };
        }

        final content = await file.readAsString();
        final yamlEditor = YamlEditor(content);

        // Check for duplicates
        final doc = loadYaml(content);
        if (doc is Map &&
            doc['pipelines'] is Map &&
            (doc['pipelines'] as Map).containsKey(pipelineName)) {
          logTelemetry(
            true,
            'Pipeline "$pipelineName" already exists. Use steward_update_pipeline instead.',
          );
          return {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text':
                    'Pipeline "$pipelineName" already exists in steward.yaml. Use steward_update_pipeline to modify it.',
              },
            ],
          };
        }

        yamlEditor.update(
          ['pipelines', pipelineName],
          {'cmd': cmd, 'desc': desc},
        );
        await file.writeAsString(yamlEditor.toString());

        final msg =
            'Pipeline "$pipelineName" successfully declared and saved to steward.yaml.';
        logTelemetry(false, msg);
        return {
          'content': [
            {'type': 'text', 'text': msg},
          ],
        };
      }

      if (name == 'steward_update_pipeline') {
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final pipelineName = arguments['name'] as String;
        final cmd = arguments['cmd'] as String;
        final desc = arguments['desc'] as String;

        final file = File(p.join(root, 'steward.yaml'));
        if (!file.existsSync()) {
          logTelemetry(true, 'steward.yaml not found at root.');
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': 'steward.yaml not found at root.'},
            ],
          };
        }

        final content = await file.readAsString();
        final doc = loadYaml(content);

        if (doc is! Map ||
            doc['pipelines'] is! Map ||
            !(doc['pipelines'] as Map).containsKey(pipelineName)) {
          logTelemetry(
            true,
            'Pipeline "$pipelineName" not found in steward.yaml.',
          );
          return {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text':
                    'Pipeline "$pipelineName" not found in steward.yaml to update.',
              },
            ],
          };
        }

        final yamlEditor = YamlEditor(content);
        yamlEditor.update(
          ['pipelines', pipelineName],
          {'cmd': cmd, 'desc': desc},
        );
        await file.writeAsString(yamlEditor.toString());

        final msg =
            'Pipeline "$pipelineName" successfully updated in steward.yaml.';
        logTelemetry(false, msg);
        return {
          'content': [
            {'type': 'text', 'text': msg},
          ],
        };
      }

      if (name == 'steward_delete_pipeline') {
        final arguments = params['arguments'].asMap as Map<String, dynamic>;
        final pipelineName = arguments['name'] as String;

        final file = File(p.join(root, 'steward.yaml'));
        if (!file.existsSync()) {
          logTelemetry(true, 'steward.yaml not found at root.');
          return {
            'isError': true,
            'content': [
              {'type': 'text', 'text': 'steward.yaml not found at root.'},
            ],
          };
        }

        final content = await file.readAsString();
        final doc = loadYaml(content);

        if (doc is! Map ||
            doc['pipelines'] is! Map ||
            !(doc['pipelines'] as Map).containsKey(pipelineName)) {
          logTelemetry(
            true,
            'Pipeline "$pipelineName" not found in steward.yaml.',
          );
          return {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text':
                    'Pipeline "$pipelineName" not found in steward.yaml to delete.',
              },
            ],
          };
        }

        final yamlEditor = YamlEditor(content);
        yamlEditor.remove(['pipelines', pipelineName]);
        await file.writeAsString(yamlEditor.toString());

        final msg =
            'Pipeline "$pipelineName" successfully deleted from steward.yaml.';
        logTelemetry(false, msg);
        return {
          'content': [
            {'type': 'text', 'text': msg},
          ],
        };
      }

      logTelemetry(true, 'Method not found');
      throw json_rpc.RpcException.methodNotFound(name);
    });

    // Register Resources List
    server.registerMethod('resources/list', (final json_rpc.Parameters params) {
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
    server.registerMethod('resources/read', (
      final json_rpc.Parameters params,
    ) async {
      final uri = params['uri'].asString;
      if (uri.startsWith('steward://docs/')) {
        final docName = uri.replaceFirst('steward://docs/', '');
        final docPath = config.docs[docName];
        if (docPath != null) {
          final file = File(p.join(root, docPath));
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

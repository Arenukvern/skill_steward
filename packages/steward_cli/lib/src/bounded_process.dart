import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Runs a child process and ensures timeout means the child is stopped.
Future<ProcessResult> runBoundedProcess(
  final String executable,
  final List<String> arguments, {
  required final String workingDirectory,
  required final Duration timeout,
  final String? timeoutMessage,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  var timedOut = false;

  final exit = await process.exitCode.timeout(
    timeout,
    onTimeout: () async {
      timedOut = true;
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
      }
      return 124;
    },
  );

  final stdoutText = await stdoutFuture;
  var stderrText = await stderrFuture;
  if (timedOut) {
    final message =
        timeoutMessage ?? 'Timed out after ${timeout.inMilliseconds}ms.';
    stderrText = stderrText.trim().isEmpty
        ? message
        : '${stderrText.trimRight()}\n$message';
  }

  return ProcessResult(
    process.pid,
    timedOut ? 124 : exit,
    stdoutText,
    stderrText,
  );
}

#!/usr/bin/env dart

import 'package:steward_cli/steward_cli.dart';

Future<void> main(final List<String> arguments) async {
  await StewardCli().run(arguments);
}

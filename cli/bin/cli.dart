import "dart:io";

import "package:args/command_runner.dart";

import "../commands/build/build.dart";
import "../commands/codegen.dart";
import "../commands/publish.dart";
import "../commands/update.dart";
import "../mixins/package_info.dart";

Future<void> main(List<String> args) async {
  final CommandRunner<int> runner = CommandRunner(
    "package",
    "A tool to help with maintaining the package.",
  );

  PackageInfo.init();

  runner
    ..addCommand(BuildCommand())
    ..addCommand(CodegenCommand())
    ..addCommand(UpdateCommand())
    ..addCommand(PublishCommand());

  // Propagate the command's exit code so CI fails when a build fails.
  // (Previously `runner.run` was neither awaited nor assigned, so every
  // invocation exited 0 — e.g. a broken Android build still showed green.)
  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    print(e.usage);
    exitCode = 64;
  }
}

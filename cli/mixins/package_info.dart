import "dart:io";

import "package:yaml_edit/yaml_edit.dart";

import "../cli_command.dart";

mixin PackageInfo on CliCommand {
  String get frbVersion => "2.13.0";

  String get packageName => _packageName;
  static final String _packageName = "haudiotagger_fingerprint";

  String get packageVersion => _packageVersion;
  static String _packageVersion = "";

  String get projectRootDirectory => _projectRootDirectory;
  static String _projectRootDirectory = "";

  static void init() {
    if (_projectRootDirectory.isNotEmpty) return;

    _projectRootDirectory = _getProjectRootDirectory();
    _packageVersion = _getPackageVersion();
  }

  static String _getProjectRootDirectory() {
    Directory directory = Directory.current;

    // Starts from the current directory and goes up until it finds the
    // package root (a directory holding both pubspec.yaml and rust/Cargo.toml).
    while (true) {
      if (File("${directory.path}/pubspec.yaml").existsSync() &&
          File("${directory.path}/rust/Cargo.toml").existsSync()) {
        return directory.path;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) {
        throw StateError("Could not find project root directory.");
      }
      directory = parent;
    }
  }

  static String _getPackageVersion() {
    final File pubspec = File(
      "$_projectRootDirectory/pubspec.yaml",
    );

    final YamlEditor yamlEditor = YamlEditor(pubspec.readAsStringSync());
    return yamlEditor.parseAt(["version"]).value;
  }
}

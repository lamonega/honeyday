import 'dart:io';

/// Run from the project root after updating Drift or the Dart SDK.
Future<void> main() async {
  final output = Directory('.dart_tool/drift_worker');
  await output.create(recursive: true);
  final javascript = File('${output.path}/drift_worker.js');
  final result = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O4',
    '--no-source-maps',
    '-o',
    javascript.path,
    'tool/drift_worker.dart',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    return;
  }

  // dart2js also emits .js.deps with absolute paths. Flutter copies everything
  // in web/, regardless of .gitignore, so publish only the JavaScript itself.
  await javascript.copy('web/drift_worker.js');
  for (final path in [
    'web/drift_worker.js.deps',
    'build/web/drift_worker.js.deps',
  ]) {
    final legacy = File(path);
    if (legacy.existsSync()) {
      await legacy.delete();
    }
  }
}

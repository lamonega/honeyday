import 'dart:async';
import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(),
    run: () async => await testMain(),
  );
}

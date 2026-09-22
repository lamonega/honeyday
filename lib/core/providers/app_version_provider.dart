import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Application version string resolved from platform package metadata.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isNotEmpty && info.buildNumber != '0'
        ? '${info.version}+${info.buildNumber}'
        : info.version;
  } on Object {
    return '0.1.7+1';
  }
});

import 'package:flutter/material.dart';

/// Helper class that manages the common lifecycle of catalog widgets
/// that deserialize JSON config and sync state with parent.
///
/// Usage in State class:
/// ```dart
/// late CatalogConfigHelper<MyConfig> _configHelper;
///
/// @override
/// void initState() {
///   super.initState();
///   _configHelper = CatalogConfigHelper<MyConfig>(
///     parseConfig: (json) => MyConfig.fromJsonString(json),
///     configToJson: (config) => config.toJsonString(),
///     onConfigChanged: widget.onConfigChanged,
///     initialJson: widget.configJson,
///   );
/// }
///
/// MyConfig get _config => _configHelper.config;
/// ```
class CatalogConfigHelper<C> {
  CatalogConfigHelper({
    required this.parseConfig,
    required this.configToJson,
    required this.onConfigChanged,
    required String initialJson,
  }) : config = parseConfig(initialJson);

  final C Function(String jsonStr) parseConfig;
  final String Function(C config) configToJson;
  final ValueChanged<String> onConfigChanged;

  C config;

  void updateFromJson(String jsonStr) {
    config = parseConfig(jsonStr);
  }

  void updateConfig(C newConfig) {
    config = newConfig;
    onConfigChanged(configToJson(newConfig));
  }
}

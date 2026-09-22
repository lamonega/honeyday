import 'package:flutter/material.dart';

/// Helper class that manages the common lifecycle of catalog widgets
/// that deserialize JSON config and sync state with parent.
///
/// The notify callback is stored as a mutable field because parents build it
/// as a closure over the element snapshot: a stale callback would persist
/// outdated geometry alongside the new config. Always refresh it on every
/// parent rebuild by assigning `onConfigChanged` from the State's
/// `didUpdateWidget`.
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
///     initialJson: widget.configJson,
///   )..onConfigChanged = widget.onConfigChanged;
/// }
///
/// @override
/// void didUpdateWidget(MyWidget oldWidget) {
///   super.didUpdateWidget(oldWidget);
///   _configHelper.onConfigChanged = widget.onConfigChanged;
///   if (oldWidget.configJson != widget.configJson) {
///     _configHelper.updateFromJson(widget.configJson);
///   }
/// }
///
/// MyConfig get _config => _configHelper.config;
/// ```
class CatalogConfigHelper<C> {
  CatalogConfigHelper({
    required this.parseConfig,
    required this.configToJson,
    required String initialJson,
  }) : config = parseConfig(initialJson);

  final C Function(String jsonStr) parseConfig;
  final String Function(C config) configToJson;

  late ValueChanged<String> onConfigChanged;

  C config;

  void updateFromJson(String jsonStr) {
    config = parseConfig(jsonStr);
  }

  void updateConfig(C newConfig) {
    config = newConfig;
    onConfigChanged(configToJson(newConfig));
  }
}

import 'dart:async';

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
/// Writes are debounced: [config] updates immediately so the UI reacts on
/// every keystroke, while the persisted JSON is emitted only after
/// [debounceDuration] of quiet. Call [dispose] from the State's `dispose`
/// so a pending write is flushed instead of dropped.
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
/// @override
/// void dispose() {
///   _configHelper.dispose();
///   super.dispose();
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

  /// Quiet period required before a config change is written downstream.
  static const Duration debounceDuration = Duration(milliseconds: 400);

  final C Function(String jsonStr) parseConfig;
  final String Function(C config) configToJson;

  late ValueChanged<String> onConfigChanged;

  C config;

  Timer? _debounce;
  String? _pendingJson;

  void updateFromJson(String jsonStr) {
    config = parseConfig(jsonStr);
  }

  void updateConfig(C newConfig) {
    config = newConfig;
    _pendingJson = configToJson(newConfig);
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, _emitPending);
  }

  /// Emits a pending debounced write right away, if any.
  void flush() {
    _debounce?.cancel();
    _debounce = null;
    _emitPending();
  }

  /// Flushes pending work and cancels the timer. Call from `dispose`.
  void dispose() {
    flush();
  }

  void _emitPending() {
    final json = _pendingJson;
    if (json == null) return;
    _pendingJson = null;
    onConfigChanged(json);
  }
}

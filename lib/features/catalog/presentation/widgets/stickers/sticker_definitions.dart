import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// An icon that scales with the canvas element's finite bounds.
class ScalableStickerIcon extends StatelessWidget {
  const ScalableStickerIcon({
    required this.icon,
    required this.color,
    this.angle = 0,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.8;
        return Center(
          child: Transform.rotate(
            angle: angle,
            child: Icon(icon, color: color, size: size),
          ),
        );
      },
    );
  }
}

/// Definition for a heart sticker.
class StickerHeartDefinition extends AgendaWidgetDefinition {
  const StickerHeartDefinition();

  @override
  String get id => 'sticker_heart';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerHeart;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerHeartDesc;

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.favorite_border_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFE4E6', // Rose 100
    borderColorHex: '#E11D48',
  ).toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return ScalableStickerIcon(
      icon: Icons.favorite_rounded,
      color: config.borderColor,
    );
  }
}

/// Definition for a star sticker.
class StickerStarDefinition extends AgendaWidgetDefinition {
  const StickerStarDefinition();

  @override
  String get id => 'sticker_star';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerStar;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerStarDesc;

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.star_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

  @override
  String get initialConfigJson => const ElementConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return ScalableStickerIcon(
      icon: Icons.star_rounded,
      color: config.borderColor,
    );
  }
}

/// Definition for a coffee mug sticker.
class StickerCoffeeDefinition extends AgendaWidgetDefinition {
  const StickerCoffeeDefinition();

  @override
  String get id => 'sticker_coffee';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerCoffee;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerCoffeeDesc;

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.coffee_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFEDD5',
    borderColorHex: '#9A3412',
  ).toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return ScalableStickerIcon(
      icon: Icons.coffee_rounded,
      color: config.borderColor,
    );
  }
}

/// Definition for a push-pin sticker.
class StickerPinDefinition extends AgendaWidgetDefinition {
  const StickerPinDefinition();

  @override
  String get id => 'sticker_pin';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerPin;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogStickerPinDesc;

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.push_pin_outlined;

  @override
  Size get defaultSize => const Size(70, 70);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#EDE9FE',
    borderColorHex: '#7C3AED',
  ).toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return ScalableStickerIcon(
      icon: Icons.push_pin_rounded,
      color: config.borderColor,
      angle: 0.3,
    );
  }
}

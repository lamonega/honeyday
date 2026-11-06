# Bundled typography

Honeyday ships Fraunces, Plus Jakarta Sans and Flutter's Roboto fallback in
`assets/fonts/`. App typography loads locally with `google_fonts` runtime fetching
disabled. The Web build serves the initial fonts from its own assets, including
Roboto, which Flutter otherwise downloads **before Dart's `main()` runs**.

This is not a promise that an entire hosted Web app works offline: CanvasKit,
hosting and browser caches also matter. Flutter Web may still request additional
fallback fonts for characters outside the bundled fonts' glyph coverage (for
example some scripts/emoji). `GoogleFonts.config` controls that package, not the
engine's separate glyph-fallback mechanism.

## Variants and provenance

| Family | Normal weights |
|---|---|
| Fraunces | 400, 600, 700 |
| Plus Jakarta Sans | 400, 500, 600, 700, 800 |
| Roboto (engine fallback) | 100, 300, 400, 500, 700, 900 |

The first eight unmodified static TTF files match `google_fonts` 8.2.1's metadata
and total **531,468 bytes**. The six Roboto files match Flutter's pinned material
font archive `3012db47f3130e62f7cc0beabff968a33cbec8d8`, and are byte-identical to
Alchemist's existing Roboto files. Keeping that fallback range avoids introducing
a different native/golden typography while fixing the engine's startup request.

All 14 fonts total **1,559,772 bytes** (about 1.49 MiB), plus 20,151 bytes of
licenses. `assets/fonts/manifest.json` records original HTTPS URLs, archive member
names where applicable, byte lengths and SHA-256 checksums. Font/license sources
are pinned to hashes or a repository commit, not moving branches.

Fraunces and Plus Jakarta Sans use the **SIL Open Font License 1.1**; this pinned
Roboto distribution uses **Apache License 2.0**, independently of the app's GPL.
Original notices/terms are preserved in `OFL-Fraunces.txt`,
`OFL-PlusJakartaSans.txt` and `LICENSE-Roboto.txt`, bundled and registered with
Flutter's `LicenseRegistry`. Keep license files with LF endings so their pinned
checksums are consistent on Windows.

## Loading and export

`AppFonts.load()` disables runtime fetching, registers licenses once and waits
for every bundled variant before `runApp`. `google_fonts` resolves the original
family/variant filenames directly from the asset manifest; do not rename them.
Fraunces/Plus Jakarta Sans are listed as **assets**, not in the pubspec's `fonts`
section, as required by that package's integration. Roboto is additionally
registered as a `Roboto` family in `fonts`, so the engine sees it in
`FontManifest.json` before starting Dart and does not fetch its default from
`fonts.gstatic.com`.

PDF offscreen capture uses the same theme and loaded fonts, and still waits for
any pending font loads before rasterizing. PDFs embed rasterized page imagery,
not selectable text/font resources. Saved handwriting is included by default
and can be disabled independently in the [PDF export options](pdf-export.md).

Only the normal variants above are bundled. Before introducing a new family,
weight or italic variant, include its file, license/provenance and preload it;
otherwise a new `GoogleFonts` request for an unbundled variant will fail with
runtime fetching disabled. Existing `TextStyle.copyWith` emphasis can be
synthesized by Flutter without requesting a new variant.

## Verification and updates

Run:

```bash
flutter test test/core/theme/app_fonts_test.dart
flutter test test/features/export/data/offscreen_capture_test.dart
flutter test test/golden
```

Tests preload the same real assets as the application with runtime fetching
disabled. They check all files and license checksums, unique license registration,
actual font metrics versus Ahem fallback, both themes and PDF capture's real font
wait. A separate assertion checks that the engine manifest declares Roboto and
all six fallback weights. No device font cache is needed because assets take
precedence.

A local Chrome headless smoke check also blocked `fonts.googleapis.com` and
`fonts.gstatic.com`, disabled the HTTP cache and opened onboarding/home from a
fresh origin. All 14 initial TTFs returned HTTP 200 from localhost, with no
external font requests or JavaScript exceptions, including after a reload.
All Windows/CI goldens passed unchanged when adding Roboto.

When updating a file, download its recorded URL (extracting `archiveMember` when
present), or deliberately choose a new upstream version. Verify checksum and
length and update the manifest when appropriate. Keep file names compatible with `google_fonts`. Include licenses
for new families and update `AppFonts`' preload list and this document.

Review Windows **and** CI golden differences before accepting reference changes.
With real font metrics, even CI's obscured text rectangles can change size. The
initial bundling changes only the cover-title regions in `agenda_card_covers`;
canvas, static page and catalog references remain unchanged.

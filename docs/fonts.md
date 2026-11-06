# Bundled typography

Honeyday ships Fraunces and Plus Jakarta Sans in `assets/fonts/`. No font request
is sent to Google at runtime, including on the first native launch. The Web
build serves these files from the application's own assets; opening an installed
or hosted Web app fully offline additionally depends on browser caching/hosting
and is not guaranteed merely by bundling fonts.

## Variants and provenance

| Family | Normal weights |
|---|---|
| Fraunces | 400, 600, 700 |
| Plus Jakarta Sans | 400, 500, 600, 700, 800 |

The eight unmodified static TTF files match `google_fonts` 8.2.1's font metadata.
The font files total **531,468 bytes** (about 519 KiB); their two licenses add
8,793 bytes. `assets/fonts/manifest.json` records the original HTTPS URLs,
byte lengths and SHA-256 checksums for reproducible verification/downloads.
The licenses are pinned to a Google Fonts repository commit, not a moving branch.

Both families are distributed under the **SIL Open Font License 1.1**, independent
of the application's GPL license. Original copyright notices and license terms
are preserved in `OFL-Fraunces.txt` and `OFL-PlusJakartaSans.txt`, bundled as
assets and registered with Flutter's `LicenseRegistry`. Keep license files with
LF endings so their pinned checksums are consistent on Windows.

## Loading and export

`AppFonts.load()` disables runtime fetching, registers licenses once and waits
for every bundled variant before `runApp`. `google_fonts` resolves the original
family/variant filenames directly from the asset manifest; do not rename them.
They are listed as **assets**, not in the pubspec's `fonts` section, as required
by that package's asset-loading integration.

PDF offscreen capture uses the same theme and loaded fonts, and still waits for
any pending font loads before rasterizing. PDFs embed rasterized page imagery,
not selectable text/font resources. This change does not add handwriting to PDF.

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
wait. No device font cache is needed because bundled assets take precedence.

When updating a file, download its recorded URL (or deliberately choose a new
upstream version), verify its checksum and length, and update the manifest when
appropriate. Keep file names compatible with `google_fonts`. Include licenses
for new families and update `AppFonts`' preload list and this document.

Review Windows **and** CI golden differences before accepting reference changes.
With real font metrics, even CI's obscured text rectangles can change size. The
initial bundling changes only the cover-title regions in `agenda_card_covers`;
canvas, static page and catalog references remain unchanged.

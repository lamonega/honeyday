import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// Builds an RGBA raster from `[r, g, b, a]` quads, row-major.
CapturedPage pageOf(int width, int height, List<int> quads) {
  return CapturedPage(
    rgba: Uint8List.fromList(quads),
    width: width,
    height: height,
  );
}

/// Inflates a PDF image stream and undoes the PNG row filter, the way a
/// conforming reader would — deliberately written independently of
/// `filterPageRows`, so the round trip is a real check and not a tautology.
Uint8List readRgb(Uint8List flateStream, int width, int height) {
  final inflated = ZLibCodec().decode(flateStream);
  final rowBytes = width * 3;
  expect(
    inflated.length,
    height * (rowBytes + 1),
    reason: 'one filter byte plus RGB per row',
  );

  final rgb = Uint8List(height * rowBytes);
  for (var y = 0; y < height; y++) {
    final src = y * (rowBytes + 1);
    expect(
      inflated[src],
      0,
      reason: 'row $y must use the None filter: prediction was measured to '
          'inflate a pen-on-paper page, see encodePageImage',
    );
    rgb.setRange(
      y * rowBytes,
      (y + 1) * rowBytes,
      inflated,
      src + 1,
    );
  }
  return rgb;
}

void main() {
  group('encodePageImage', () {
    test('round-trips known pixels byte for byte', () {
      // 2×2: a red and a green pixel on top, two blue ones below.
      final page = pageOf(2, 2, [
        0xFF, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, //
        0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF,
      ]);

      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);
      final rgb = readRgb(stream, 2, 2);

      expect(rgb, [
        0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, //
        0x00, 0x00, 0xFF, 0x00, 0x00, 0xFF,
      ]);
    });

    test('emits a zlib container, not raw deflate', () {
      final stream = encodePageImage(
        pageOf(1, 1, [0x12, 0x34, 0x56, 0xFF]),
        backgroundArgb: kExportCreamArgb,
      );

      // RFC 1950: a 32 KiB window, the deflate method, and an FCHECK that
      // makes (cmf * 256 + flg) a multiple of 31. Raw RFC 1951 deflate would
      // start with the first literal byte instead and no reader would open
      // the file.
      final cmf = stream[0];
      final flg = stream[1];
      expect(cmf & 0x0F, 8, reason: 'compression method must be deflate');
      expect(cmf >> 4, 7, reason: '32 KiB window');
      expect(((cmf * 256) + flg) % 31, 0, reason: 'FCHECK must validate');
      expect(stream.length, greaterThan(6), reason: 'header + data + Adler-32');
    });

    test('uses the None filter on every row', () {
      final page = pageOf(2, 3, List<int>.filled(3 * 2 * 4, 0x7F));
      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);
      final inflated = ZLibCodec().decode(stream);
      const stride = 2 * 3 + 1;

      // Not just the first row: an "Up" filter on a flat page would make
      // every row after the first all zeros, which is the variant measured
      // to be 60% *larger*. See encodePageImage.
      expect(inflated[0], 0);
      expect(inflated[stride], 0);
      expect(inflated[2 * stride], 0);
      expect(
        inflated.sublist(stride + 1, 2 * stride),
        isNot(everyElement(0)),
        reason: 'rows carry their own pixels, they are not differences',
      );
    });

    test('drops the alpha channel of a fully opaque page untouched', () {
      // Premultiplied vs straight alpha is unobservable here, and that is the
      // point: PageSurface paints an opaque sheet, so alpha is always 0xFF.
      final page = pageOf(1, 1, [0x12, 0x34, 0x56, 0xFF]);

      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);

      expect(readRgb(stream, 1, 1), [0x12, 0x34, 0x56]);
    });

    test('composites a fully transparent page over the background', () {
      final page = pageOf(1, 1, [0x00, 0x00, 0x00, 0x00]);

      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);

      expect(readRgb(stream, 1, 1), [0xFF, 0xFD, 0xF7]);
    });

    test('blends a half-transparent pixel halfway to the background', () {
      // Premultiplied source: 50% grey over cream.
      final page = pageOf(1, 1, [0x80, 0x80, 0x80, 0x80]);

      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);
      final rgb = readRgb(stream, 1, 1);

      expect(rgb[0], 0x80 + ((0xFF * 0x80) >> 8));
      expect(rgb[1], 0x80 + ((0xFD * 0x80) >> 8));
      expect(rgb[2], 0x80 + ((0xF7 * 0x80) >> 8));
    });

    test('the explicit compositing variant leaves opaque pixels alone', () {
      final opaque = pageOf(1, 1, [0x10, 0x20, 0x30, 0xFF]);

      final stream = encodePageImageWithCompositing(
        opaque,
        creamR: 0xFF,
        creamG: 0xFD,
        creamB: 0xF7,
      );

      expect(readRgb(stream, 1, 1), [0x10, 0x20, 0x30]);
    });
  });

  group('filterPageRows', () {
    test('reports transparency only when a pixel is not fully opaque', () {
      expect(
        filterPageRows(pageOf(1, 1, [1, 2, 3, 0xFF])).hadTransparency,
        isFalse,
      );
      expect(
        filterPageRows(pageOf(1, 1, [1, 2, 3, 0xFE])).hadTransparency,
        isTrue,
      );
      expect(
        filterPageRows(pageOf(1, 1, [0, 0, 0, 0])).hadTransparency,
        isTrue,
      );
    });

    test('a 1×1 page is a single None row', () {
      final filtered = filterPageRows(pageOf(1, 1, [9, 8, 7, 0xFF]));

      expect(filtered.rows, [0, 9, 8, 7]);
    });

    test('a one-row page keeps the channel order', () {
      final filtered = filterPageRows(
        pageOf(2, 1, [
          10, 20, 30, 0xFF, //
          12, 18, 35, 0xFF,
        ]),
      );

      expect(filtered.rows, [0, 10, 20, 30, 12, 18, 35]);
    });

    test('a second row is not filtered against the first', () {
      // Pinned deliberately: the Up filter (row minus previous row) was
      // measured at 996 KiB per A4 page against 617 KiB unfiltered, because
      // it destroys the horizontal runs of pen strokes. If this test ever
      // needs to change, the measurement in `encodePageImage` has to be redone
      // first — restoring the predictor on theory is what broke the size.
      final filtered = filterPageRows(
        pageOf(1, 2, [
          10, 10, 10, 0xFF, //
          1, 1, 1, 0xFF,
        ]),
      );

      expect(filtered.rows, [0, 10, 10, 10, 0, 1, 1, 1]);
    });

    test('a mixed-brightness page round-trips every channel', () {
      const width = 4;
      const height = 4;
      final quads = <int>[];
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          quads
            ..add((x * 37 + y * 11) % 256)
            ..add((x * 91 + y * 5) % 256)
            ..add((x * 13 + y * 67) % 256)
            ..add(0xFF);
        }
      }
      final expected = <int>[];
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final base = (y * width + x) * 4;
          expected
            ..add(quads[base])
            ..add(quads[base + 1])
            ..add(quads[base + 2]);
        }
      }

      final stream = encodePageImage(
        pageOf(width, height, quads),
        backgroundArgb: kExportCreamArgb,
      );

      expect(readRgb(stream, width, height), expected);
    });

    test('sized rows match the declared layout', () {
      expect(filteredRowByteLength(1, 1), 4);
      expect(filteredRowByteLength(2480, 3410), 3410 * (2480 * 3 + 1));
      expect(
        filterPageRows(pageOf(3, 2, List<int>.filled(2 * 3 * 4, 0xFF))).rows
            .length,
        filteredRowByteLength(3, 2),
      );
    });
  });
}

self.onmessage = async (event) => {
  const { pageIndex, width, height, rgba } = event.data;

  try {
    if (typeof CompressionStream === "undefined") {
      throw new Error("This browser does not support CompressionStream.");
    }
    if (!(rgba instanceof Uint8Array)) {
      throw new Error("Expected RGBA Uint8Array.");
    }
    if (rgba.length !== width * height * 4) {
      throw new Error("Invalid RGBA dimensions.");
    }

    const rowStride = width * 3 + 1;
    const rows = new Uint8Array(height * rowStride);
    const background = [255, 253, 247];
    let source = 0;
    let target = 0;

    for (let y = 0; y < height; y++) {
      rows[target++] = 0; // PNG filter: None.
      for (let x = 0; x < width; x++) {
        const alpha = rgba[source + 3];
        for (let channel = 0; channel < 3; channel++) {
          const value = rgba[source + channel] +
              Math.floor(background[channel] * (255 - alpha) / 255);
          rows[target++] = Math.min(255, value);
        }
        source += 4;
      }
    }

    // "deflate" emits the zlib wrapper required by PDF /FlateDecode.
    const compressedStream = new Blob([rows])
        .stream()
        .pipeThrough(new CompressionStream("deflate"));
    const buffer = await new Response(compressedStream).arrayBuffer();

    self.postMessage(
      { pageIndex, bytes: new Uint8Array(buffer) },
      [buffer],
    );
  } catch (error) {
    self.postMessage({ pageIndex, error: String(error) });
  }
};

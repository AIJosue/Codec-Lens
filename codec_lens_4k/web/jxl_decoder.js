async function loadJxlWithFallback(jxlPath, fallbackPath) {
  try {
    if (!('ImageDecoder' in window)) {
      return fallbackPath;
    }

    const response = await fetch(jxlPath);
    if (!response.ok) {
      return fallbackPath;
    }

    const data = await response.arrayBuffer();
    try {
      const decoder = new ImageDecoder({ data, type: 'image/jxl' });
      const frame = await decoder.decode({ frameIndex: 0 });
      const bitmap = frame.image;
      const canvas = document.createElement('canvas');
      canvas.width = bitmap.width;
      canvas.height = bitmap.height;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(bitmap, 0, 0);
      return canvas.toDataURL('image/png');
    } catch (_) {
      return fallbackPath;
    }
  } catch (_) {
    return fallbackPath;
  }
}

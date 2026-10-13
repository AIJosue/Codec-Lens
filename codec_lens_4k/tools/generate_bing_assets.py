#!/usr/bin/env python3
import json
import time
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

import imagecodecs
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

WIDTH = 3840
HEIGHT = 2160
OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "wallpapers"
BING_META_URL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"


def _fetch_json(url: str):
    with urlopen(url, timeout=30) as response:
        return json.load(response)


def _fetch_bytes(url: str) -> bytes:
    with urlopen(url, timeout=60) as response:
        return response.read()


def _fit_4k(img: Image.Image) -> Image.Image:
    img = img.convert("RGB")
    return ImageOps.fit(img, (WIDTH, HEIGHT), method=Image.Resampling.LANCZOS)


def _offline_image() -> Image.Image:
    x = np.linspace(0, 1, WIDTH, dtype=np.float32)
    y = np.linspace(0, 1, HEIGHT, dtype=np.float32)
    xx, yy = np.meshgrid(x, y)
    r = (35 + 180 * xx).astype(np.uint8)
    g = (55 + 160 * (1 - yy)).astype(np.uint8)
    b = (95 + 140 * np.sin(xx * np.pi)).clip(0, 255).astype(np.uint8)
    arr = np.dstack([r, g, b])
    img = Image.fromarray(arr, mode="RGB")
    draw = ImageDraw.Draw(img)
    draw.ellipse((300, 220, 1700, 1620), outline=(245, 248, 255), width=10)
    draw.ellipse((2100, 500, 3550, 1950), outline=(180, 220, 255), width=8)
    return img.filter(ImageFilter.GaussianBlur(radius=0.5))


def _save_formats(img: Image.Image):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    paths = {
        "jpg": OUT_DIR / "bing_latest.jpg",
        "png": OUT_DIR / "bing_latest.png",
        "webp": OUT_DIR / "bing_latest.webp",
        "avif": OUT_DIR / "bing_latest.avif",
        "jxl": OUT_DIR / "bing_latest.jxl",
    }

    img.save(paths["jpg"], format="JPEG", quality=95, optimize=True)
    img.save(paths["png"], format="PNG", optimize=True)
    img.save(paths["webp"], format="WEBP", quality=92, method=6)

    arr = np.array(img, dtype=np.uint8)
    paths["avif"].write_bytes(imagecodecs.avif_encode(arr, level=45))
    paths["jxl"].write_bytes(imagecodecs.jpegxl_encode(arr, level=80))

    return {fmt: str(path) for fmt, path in paths.items()}


def _decode_timing(path: Path, fmt: str) -> float:
    start = time.perf_counter()
    if fmt == "jxl":
        _ = imagecodecs.jpegxl_decode(path.read_bytes())
    elif fmt == "avif":
        _ = imagecodecs.avif_decode(path.read_bytes())
    else:
        with Image.open(path) as im:
            im.load()
    return (time.perf_counter() - start) * 1000


def main():
    title = "Bing Daily Wallpaper"
    copyright_text = "Generated fallback wallpaper"
    source_image_url = "offline-generated"

    try:
      data = _fetch_json(BING_META_URL)
      image = data["images"][0]
      original_url = f'https://www.bing.com{image["url"]}'
      uhd_url = f'{original_url}&w={WIDTH}&h={HEIGHT}&rs=1&c=4'
      raw = _fetch_bytes(uhd_url)
      source_img = Image.open(BytesIO(raw))
      img4k = _fit_4k(source_img)
      title = image.get("title") or image.get("copyright", "Bing Daily Wallpaper")
      copyright_text = image.get("copyright", "")
      source_image_url = uhd_url
    except (URLError, TimeoutError, KeyError, OSError, ValueError):
      img4k = _offline_image()

    saved = _save_formats(img4k)

    formats = {}
    baseline = Path(saved["png"]).stat().st_size
    for fmt, path_str in saved.items():
      path = Path(path_str)
      size = path.stat().st_size
      formats[fmt] = {
        "asset": str(path.relative_to(OUT_DIR.parent.parent)).replace("\\", "/"),
        "bytes": size,
        "compressionSavingsPercent": round(((baseline - size) / baseline) * 100, 2),
        "decodeMs": round(_decode_timing(path, fmt), 2),
        "resolution": f"{WIDTH}x{HEIGHT}",
      }

    metadata = {
      "title": title,
      "copyright": copyright_text,
      "source": {
        "api": BING_META_URL,
        "image": source_image_url,
        "fetchedAt": datetime.now(timezone.utc).isoformat(),
      },
      "formats": formats,
    }

    (OUT_DIR / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print("Generated:", OUT_DIR)


if __name__ == "__main__":
    main()

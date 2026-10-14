# CodecLens 4K 🔍

> **High-Fidelity Visual Codec Comparator: AVIF vs. JPEG, PNG, GIF, and JPEG XL**
> Crafted with Flutter Web, visionOS/macOS glassmorphic bento design, and smooth 60fps molded liquid split comparator.

🌐 **Live Demo**: [https://aijosue.github.io/Codec-Lens-/](https://aijosue.github.io/Codec-Lens-/)

---

## 🌟 Highlights

- **Multi-Format Visual Benchmark**: Real-time side-by-side comparison of **AVIF** against **JPEG**, **PNG**, **GIF**, and **JPEG XL (JXL)**.
- **Curated 4K & Real-World Test Suite**:
  1. **Scarlet Macaw** (`aomedia_parrot`) — *Default scene*: Ultra-sharp feather texture and micro-contrasts from [AOMedia](https://aomedia.org).
  2. **Cable-Stayed Bridge** (`aomedia_bridge`) — Geometric line integrity and fine architectural wires from [AOMedia](https://aomedia.org).
  3. **Cosmos SDR 01000** — Netflix AVIF test set.
  4. **Cosmos SDR 01650** — High-motion / high-detail cinematic SDR frame.
  5. **Cosmos SDR 07296** — Complex natural lighting and color gradients.
  6. **Cosmos SDR 12920** — High dynamic range compression stress test.
  7. **Cosmos HDR 01650** — 10-bit Rec.2020 BT.2100 PQ HDR showcase.
- **Liquid Split Comparator**: Interactive touch and drag slider with 60fps `MoldedWaveClipper` curve physics.
- **Glassmorphic Bento UI**: Apple visionOS / macOS inspired backdrop blur, specular borders, and real-time codec efficiency telemetry (file size, delta savings %, and quality parameters).
- **Web Build Included**: Ready-to-serve production artifacts under `codec_lens_4k/build/web`.

---

## 🚀 Running the Web Build

The production web build is pre-compiled and bundled inside this repository:

```bash
cd codec_lens_4k/build/web
python3 -m http.server 8080
```
Then open `http://localhost:8080` in any modern web browser.

---

## 🛠️ Development Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev) (>= 3.2.0)
- [Pixi](https://pixi.sh) (for asset conversion environment)

### Running Locally
```bash
cd codec_lens_4k
flutter pub get
flutter run -d chrome
```

### Running Unit & Asset Tests
```bash
flutter test test/metadata_and_assets_test.dart
```

### Asset Conversion Pipeline
The test assets are generated and converted using Pixi:
```bash
cd codec_lens_4k
pixi run convert
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).

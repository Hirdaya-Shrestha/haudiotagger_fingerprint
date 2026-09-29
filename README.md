<p align="center">
  <img src="https://raw.githubusercontent.com/Hirdaya-Shrestha/haudiotagger_fingerprint/main/logo.png" alt="haudiotagger_fingerprint" width="140">
</p>

<h1 align="center">haudiotagger_fingerprint</h1>

<p align="center">
  <strong>Perceptual audio fingerprinting for Flutter.</strong>
</p>

<p align="center">
  Duplicates · Renames · Re-encodes — matched by content, not filenames
</p>

<p align="center">
  <a href="https://pub.dev/packages/haudiotagger_fingerprint"><img src="https://img.shields.io/pub/v/haudiotagger_fingerprint.svg?label=pub.dev&color=0175C2" alt="pub.dev"></a>
  <a href="https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/actions"><img src="https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-4285F4.svg" alt="MIT License"></a>
  <a href="https://pub.dev/packages/haudiotagger_fingerprint"><img src="https://img.shields.io/pub/dm/haudiotagger_fingerprint?label=Downloads&logo=dart" alt="Downloads"></a>
  <a href="https://haudiotagger.hirdaya-shrestha.com.np/"><img src="https://img.shields.io/badge/Web-Demo-448cf3" alt="Live Demo"></a>
</p>

<p align="center">
  <a href="https://haudiotagger.hirdaya-shrestha.com.np/docs/fingerprint"><strong>Documentation</strong></a>
  ·
  <a href="https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint"><strong>GitHub</strong></a>
  ·
  <a href="https://pub.dev/packages/haudiotagger_fingerprint"><strong>pub.dev</strong></a>
</p>

---

## Why haudiotagger_fingerprint?

Filenames lie and tags go missing — but the audio doesn't. This package
fingerprints **what a recording sounds like**, so this:

```text
Song A.mp3
song_copy.mp3
01 - Song A.mp3
Song A (Remastered).mp3
```

can be compared by content instead of by name.

### Highlights

- 🧬 Chromaprint-compatible perceptual fingerprints (same algorithm as fpcalc/AcoustID)
- 🎵 MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC
- 🌍 Android, iOS, Linux, macOS, Windows & Web
- 🦀 100% pure Rust — no C dependencies, builds everywhere including WASM
- 📦 Separate lightweight package — zero cost unless you depend on it

---

## Live Demo

Try fingerprinting directly in your browser, integrated in the hAudiotagger demo app.

**No installation. No server-side processing. Everything runs locally in your browser.**

<p>
  <a href="https://haudiotagger.hirdaya-shrestha.com.np/">
    <img src="https://img.shields.io/badge/▶_Try_the_Live_Demo-448cf3?style=for-the-badge" alt="Try Live Demo">
  </a>
</p>

> [!NOTE]
> Web applications should use the `*FromBytes` APIs such as `fingerprintFromBytes`.

---

## Installation

Add haudiotagger_fingerprint to your `pubspec.yaml`:

```yaml
dependencies:
  haudiotagger_fingerprint: ^0.1.4
```

Or install it from the command line:

```bash
flutter pub add haudiotagger_fingerprint
```

---

## Quick Start

### Fingerprint a file

```dart
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

// Decodes the full stream; tags, filenames, and containers are ignored.
final a = await HaudioFingerprint.fingerprint('Song A.mp3');
final b = await HaudioFingerprint.fingerprint('song_copy.mp3');

print(a.durationSecs);
```

### Compare two fingerprints

```dart
// 1.0 is (near-)identical audio, 0.0 is unrelated.
final score = await HaudioFingerprint.similarity(a, b);
print(score); // 1.0

// Or as a method:
print(await a.similarityTo(b));
```

### Fingerprint bytes (Web)

```dart
final fp = await HaudioFingerprint.fingerprintFromBytes(bytes);
```

### Unified API with haudiotagger

With both packages installed, fingerprinting is also available through
`Haudiotagger` — no extra imports or init calls. This package
self-registers as the backend at app startup:

```dart
import 'package:haudiotagger/haudiotagger.dart';

final fp = await Haudiotagger.fingerprint('Song A.mp3');
final score = await Haudiotagger.similarity(a, b);
```

Without this package installed, those calls throw a `StateError` telling
you to add it. Requires `haudiotagger ^2.2.0`.

### Finding duplicates

Group files with `similarity >= 0.8` as the same recording, then use each
file's metadata (title/artist/duration) to pick which copy to keep.

### Cancelling long scans

Fingerprinting never blocks your UI: native runs on background threads, web
yields cooperatively between decode chunks. For library scans, create one
token per file and cancel when the work goes stale (e.g. the user changed
track). Abandoned calls abort with `FingerprintError.cancelled`; also drop
their results via a generation counter, since an already-finished call can't
be un-computed.

```dart
final token = await CancellationToken.create();
final future = HaudioFingerprint.fingerprintFromBytes(bytes,
    cancellationToken: token);

// Later, when the user moves on:
await token.cancel();
await token.dispose();
```

---

## Score interpretation

| Score | Meaning |
|:-----:|---------|
| `1.0` | Identical audio (copies, renames) |
| `> 0.8` | Same recording, different encode/container |
| `~0.0` | Unrelated audio |

---

## Supported formats (decoding)

| Format | Fingerprint |
|:------:|:-----------:|
| **MP3** | ✅ |
| **FLAC** | ✅ |
| **Ogg Vorbis** | ✅ |
| **WAV** | ✅ |
| **AIFF** | ✅ |
| **M4A / AAC / ALAC** | ✅ |
| **Opus, APE, WavPack, Musepack** | ❌ (no pure-Rust decoder) |

---

## Platform support

| Platform | Support |
|:--------:|:-------:|
| Android | ✅ |
| iOS | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Web | ✅ |

The Web implementation decodes and fingerprints fully in-browser via
WebAssembly. Large files are CPU-heavy; prefer short clips or native
for bulk library scans.

---

## Documentation

- [Fingerprint Guide](https://haudiotagger.hirdaya-shrestha.com.np/docs/fingerprint)
- [API Reference](https://pub.dev/documentation/haudiotagger_fingerprint/latest/)

**→ [Read the full documentation](https://haudiotagger.hirdaya-shrestha.com.np/docs)**

---

## Requirements

- Flutter `>= 3.0.0`
- Dart SDK `>= 3.6.0`

---

## Contributing

Contributions are welcome! 🎉

If you find a bug, have an idea, or want to improve haudiotagger_fingerprint:

- ⭐ [Star the repository](https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint)
- 🐛 [Report a bug](https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/issues)
- 💡 [Request a feature](https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/issues)
- 🤝 Submit a pull request

---

## License

haudiotagger_fingerprint is open-source software licensed under the [MIT License](LICENSE).

---

<p align="center">
  Made with ❤️ and 🦀 by
  <a href="https://hirdaya-shrestha.com.np">Hirdaya Shrestha</a>
</p>

<p align="center">
  <img src="logo.png" alt="haudiotagger_fingerprint" width="140">
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
</p>

<p align="center">
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

It is the sibling of [`haudiotagger`](https://github.com/Hirdaya-Shrestha/haudiotagger):
haudiotagger reads metadata, this package fingerprints audio. Use them together
or separately — they are independent packages with no shared native symbols.

### Highlights

- 🧬 Chromaprint-compatible perceptual fingerprints (same algorithm as fpcalc/AcoustID)
- 🎵 MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC
- 🌍 Android, iOS, Linux, macOS, Windows & Web
- 🦀 100% pure Rust — no C dependencies, builds everywhere including WASM
- 📦 Separate lightweight package — zero cost unless you depend on it

---

## Installation

Add haudiotagger_fingerprint to your `pubspec.yaml`:

```yaml
dependencies:
  haudiotagger_fingerprint: ^0.1.0
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

### Duplicate detection with haudiotagger

```dart
import 'package:haudiotagger/haudiotagger.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

final tag = await Haudiotagger.read(path);            // metadata for display
final fp = await HaudioFingerprint.fingerprint(path); // content for matching
```

Group files with `similarity >= 0.8` as the same recording, then use the tag
(title/artist/duration) to pick which copy to keep.

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

## Compatibility with haudiotagger

- Separate Dart package, Rust crate (`haudiotagger_fingerprint`), native
  libraries (`libhaudiotagger_fingerprint.*`), and plugin classes — verified
  zero overlapping exported native symbols.
- Both plugins pin the same `flutter_rust_bridge` version (`=2.13.0`);
  keep them in sync when upgrading.
- Known upstream limitation: two flutter_rust_bridge plugins in one app can
  hit duplicate `frb_*` runtime symbols on iOS **static** linking
  ([FRB #2972](https://github.com/fzyzcjy/flutter_rust_bridge/issues/2972)).
  Dynamic linking (FRB v2's `DynamicLibrary.open` path) avoids it. This
  affects any pair of FRB plugins, not just these two.

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

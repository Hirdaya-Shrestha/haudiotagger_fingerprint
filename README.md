# haudiotagger_fingerprint

<p align="center">
  <img src="logo.png" alt="haudiotagger_fingerprint" width="140">
</p>

Perceptual audio fingerprinting for Flutter. Identify and compare recordings
by **content** — duplicate detection, library cleanup, song matching — powered
by Rust ([Symphonia](https://github.com/pdeljanov/Symphonia) decoding +
[Chromaprint](https://acoustid.org/chromaprint) fingerprinting, 100% pure Rust,
no C dependencies).

Sibling of [`haudiotagger`](https://github.com/Hirdaya-Shrestha/haudiotagger):
haudiotagger reads metadata, this package fingerprints audio. Use them together
or separately — they are independent packages with no shared native symbols.

## Installation

```yaml
dependencies:
  haudiotagger_fingerprint: ^0.1.0
```

```bash
flutter pub add haudiotagger_fingerprint
```

## Usage

```dart
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

// Fingerprint a file (decodes the full stream; tags and filenames ignored).
final a = await HaudioFingerprint.fingerprint('Song A.mp3');
final b = await HaudioFingerprint.fingerprint('song_copy.mp3');

// Compare: 1.0 is (near-)identical, 0.0 is unrelated.
final score = await HaudioFingerprint.similarity(a, b);
print(score); // 1.0

// Or as a method:
print(await a.similarityTo(b));

// Web / in-memory bytes:
final fp = await HaudioFingerprint.fingerprintFromBytes(bytes);
```

### Duplicate detection with haudiotagger

```dart
import 'package:haudiotagger/haudiotagger.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

final tag = await Haudiotagger.read(path);       // metadata for display
final fp = await HaudioFingerprint.fingerprint(path); // content for matching
```

Group files with `similarity >= 0.8` as the same recording; use the tag
(title/artist/duration) to pick which copy to keep.

## Score interpretation

| Score | Meaning |
|:-----:|---------|
| `1.0` | Identical audio (copies, renames) |
| `> 0.8` | Same recording, different encode/container |
| `~0.0` | Unrelated audio |

## Supported formats (decoding)

| Format | Fingerprint |
|:------:|:-----------:|
| MP3 | ✅ |
| FLAC | ✅ |
| Ogg Vorbis | ✅ |
| WAV | ✅ |
| AIFF | ✅ |
| M4A / AAC / ALAC | ✅ |
| Opus, APE, WavPack, Musepack | ❌ (no pure-Rust decoder) |

## Platform support

| Platform | Support |
|:--------:|:-------:|
| Android | ✅ |
| iOS | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Web (WASM) | ✅ |

Web decodes and fingerprints fully in-browser. Large files are CPU-heavy;
prefer short clips or native for bulk library scans.

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

## Requirements

- Flutter `>= 3.0.0`
- Dart SDK `>= 3.6.0`

## License

MIT — see [LICENSE](LICENSE).

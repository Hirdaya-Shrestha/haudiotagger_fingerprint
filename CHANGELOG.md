## 0.1.0

### Features

- New `HaudioFingerprint.fingerprint(path)` API for perceptual audio fingerprinting via file path
- New `HaudioFingerprint.fingerprintFromBytes(bytes)` API for web/WASM and in-memory audio
- New `HaudioFingerprint.similarity(a, b)` (plus `similarityTo`) returning a `0.0`–`1.0` content-match score
- Chromaprint-compatible fingerprints (`preset_test2`, same algorithm as fpcalc/AcoustID)
- Pure-Rust stack (Symphonia + rusty-chromaprint): no C dependencies, builds on all platforms including WASM
- Standalone by design: zero dependency on `haudiotagger` either way, yet composes with it conflict-free (proven by `test/addon_test.dart`, which uses `haudiotagger` as a dev-only dependency)

### Dependencies

- `symphonia 0.6` for audio decoding (MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC)
- `rusty-chromaprint 0.3` for fingerprint calculation and comparison
- `flutter_rust_bridge =2.13.0` for the Dart FFI bridge (same version as `haudiotagger` for side-by-side use)

### Platform Notes

- Decodable formats: MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC
- Not decodable: Opus, APE, WavPack, Musepack (no pure-Rust decoder)
- Independent sibling of `haudiotagger`: separate package, crate, native libraries, and plugin classes with zero overlapping exported native symbols

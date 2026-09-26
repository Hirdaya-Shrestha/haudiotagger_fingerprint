## 0.1.0

### Features

- New `HaudioFingerprint.fingerprint(path)` API for perceptual audio fingerprinting via file path
- New `HaudioFingerprint.fingerprintFromBytes(bytes)` API for web/WASM and in-memory audio
- New `HaudioFingerprint.similarity(a, b)` (plus `similarityTo`) returning a `0.0`–`1.0` content-match score
- Chromaprint-compatible fingerprints (`preset_test2`, same algorithm as fpcalc/AcoustID)
- Pure-Rust stack (Symphonia + rusty-chromaprint): no C dependencies, builds on all platforms including WASM
- Federated backend: `FingerprintBackendImpl` plus `HaudioFingerprintBackend.registerWith`, self-registering via `dartPluginClass` — installing this package wires `Haudiotagger.fingerprint()` with no imports or init calls

### Dependencies

- `symphonia 0.6` for audio decoding (MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC)
- `rusty-chromaprint 0.3` for fingerprint calculation and comparison
- `flutter_rust_bridge =2.13.0` for the Dart FFI bridge
- `haudiotagger_interface ^0.1.0` (pure-Dart contract, zero native weight)

### Platform Notes

- Decodable formats: MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC/ALAC
- Not decodable: Opus, APE, WavPack, Musepack (no pure-Rust decoder)
- Independent package: separate Dart package, Rust crate, native libraries, and plugin classes
- `Haudiotagger.fingerprint()` (requires `haudiotagger ^2.2.0`) throws a helpful `StateError` when this package is not installed

## 0.1.4

### Bug Fixes

- Fixed macOS/iOS Swift Package Manager resolution: the vended library product is now `haudiotagger-fingerprint` (hyphenated, as flutter_tool requires — underscores are illegal in the derived CFBundleIdentifier), while package and target names stay unchanged

## 0.1.3

### Bug Fixes

- Fixed web `DataCloneError` when used alongside `haudiotagger`: plain functions ran on FRB's worker pool, whose bootstrap hardcodes the `wasm_bindgen` JS global. All three API functions are now `#[frb(sync)]` — they execute on the calling thread with no pool, no workers, and no shared-memory hand-off. Public Dart API unchanged (still `Future`-based)

## 0.1.2

### Bug Fixes

- Fixed web content-hash mismatch when used alongside `haudiotagger`: both plugins' wasm-bindgen glue declared the same top-level `wasm_bindgen` global, so one plugin talked to the other's wasm. This package now uses a unique `wasm_bindgen_haudiotagger_fingerprint` global (`wasm_bindgen_name` + renamed glue; publish workflow applies the rename on every build)

## 0.1.1

### Bug Fixes

- Fixed Linux/Windows builds: native registrant headers and symbols now match what flutter_tool generates from `pluginClass` (`haudio_fingerprint_plugin.h`, `HaudioFingerprintPluginCApiRegisterWithRegistrar`)
- Fixed `Haudiotagger.fingerprint()` on web throwing "no backend registered": the web plugin registrant never calls `dartPluginClass`, so the web plugin class now registers the backend itself
- Fixed source builds resolving the wrong Rust output name in `apply_cargokit`

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

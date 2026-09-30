## 0.3.1

### Bug Fixes

- Fixed crashes (OOM-kill, no panic message) when fingerprinting very long files: the decoder streamed the entire PCM into one buffer (~12 GB for an 18-hour file). Decode now feeds the fingerprinter in ~1s chunks with O(chunk) memory; output is bit-identical (proven by test)
- Dependency panics inside fingerprint work now surface as clean errors instead of aborting the process on native
- `duration_secs` saturates instead of wrapping on absurdly long inputs

## 0.3.1

### Bug Fixes

- Fixed native crashes (`capacity overflow` in `Vec::with_capacity`) when the Dart bindings and the native library disagree on the wire format, e.g. a stale prebuilt `.so` after upgrading: the SSE decoder trusted a length prefix that could reinterpret to ~2⁶⁴ bytes. Dart now verifies a native API version on init and fails with a clear "run flutter clean and rebuild" error instead of corrupting memory. Bump `FINGERPRINT_API_VERSION` (Rust) together with `_apiVersion` (Dart) whenever an FRB signature changes

## 0.3.0

### Bug Fixes

- **Breaking:** the public `AudioFingerprint` type is now the shared DTO from `haudiotagger_interface` (converted internally) instead of the FRB-generated twin, so importing `haudiotagger` and `haudiotagger_fingerprint` together no longer collides with `ambiguous_import`. No behavior change; re-run `flutter pub get`, no code changes needed unless you referenced the FRB type directly

## 0.2.0

### Features

- Cooperative cancellation for long scans: `CancellationToken.create()` / `cancel()` / `dispose()`, passable to `fingerprint` and `fingerprintFromBytes`; tripped tokens abort with `FingerprintError.cancelled`. One token per scan; cancel/dispose are idempotent
- Non-blocking execution: fingerprint calls are now truly async — background threads on native, cooperative yields between decode chunks on web. Public Dart signatures unchanged (still `Future`-based)

### Platform Notes

- On web the calls share the main thread cooperatively (yields ~every second of audio); for bulk scans prefer short clips or native. No extra setup needed — no worker pool involved
- `similarity` stays synchronous: it compares small in-memory vectors in microseconds, no token needed

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

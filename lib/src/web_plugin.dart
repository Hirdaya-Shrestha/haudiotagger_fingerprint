import 'backend.dart' show HaudioFingerprintBackend;

// Web plugin registration target (referenced by pubspec `pluginClass`).
// The actual WASM implementation lives in `rust/frb_generated.web.dart` and
// is loaded by `RustLib.init()` (invoked automatically on the first API
// call).
//
// It also wires the fingerprint backend: unlike native platforms, the web
// plugin registrant never calls `dartPluginClass`, so without this,
// `Haudiotagger.fingerprint()` on web would throw "no backend registered"
// even with the package installed.
class HaudioFingerprintWeb {
  static void registerWith([dynamic _]) {
    HaudioFingerprintBackend.registerWith();
  }
}

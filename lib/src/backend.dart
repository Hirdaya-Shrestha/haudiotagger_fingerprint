import 'dart:typed_data';

import 'package:haudiotagger_interface/haudiotagger_interface.dart' as iface;

import 'fingerprint.dart' show HaudioFingerprint;
import 'rust/api/fingerprint.dart' as frb;

/// [iface.FingerprintBackend] implementation backed by this package's Rust
/// engine. Installed automatically — see [HaudioFingerprintBackend].
class FingerprintBackendImpl implements iface.FingerprintBackend {
  const FingerprintBackendImpl();

  static iface.AudioFingerprint _convert(frb.AudioFingerprint fp) =>
      iface.AudioFingerprint(values: fp.values, durationSecs: fp.durationSecs);

  static frb.AudioFingerprint _convertBack(iface.AudioFingerprint fp) =>
      frb.AudioFingerprint(values: fp.values, durationSecs: fp.durationSecs);

  @override
  Future<iface.AudioFingerprint> fingerprint(String path) async =>
      _convert(await HaudioFingerprint.fingerprint(path));

  @override
  Future<iface.AudioFingerprint> fingerprintFromBytes(Uint8List bytes) async =>
      _convert(await HaudioFingerprint.fingerprintFromBytes(bytes));

  @override
  Future<double> similarity(
          iface.AudioFingerprint a, iface.AudioFingerprint b) =>
      HaudioFingerprint.similarity(_convertBack(a), _convertBack(b));
}

/// Self-registration: the generated plugin registrant calls [registerWith]
/// at app startup, so merely installing this package wires the backend.
abstract final class HaudioFingerprintBackend {
  static void registerWith([dynamic _]) {
    iface.FingerprintRegistry.instance = const FingerprintBackendImpl();
  }
}

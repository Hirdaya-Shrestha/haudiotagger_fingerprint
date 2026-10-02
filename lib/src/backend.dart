import 'dart:typed_data';

import 'package:haudiotagger_interface/haudiotagger_interface.dart' as iface;

import 'fingerprint.dart'
    show AudioFingerprint, CancellationToken, HaudioFingerprint;

/// [iface.FingerprintBackend] implementation backed by this package's Rust
/// engine. Installed automatically - see [HaudioFingerprintBackend].
class FingerprintBackendImpl implements iface.FingerprintBackend {
  const FingerprintBackendImpl();

  /// Resolve a contract token to this engine's handle. Only tokens from
  /// [CancellationToken.create] carry one; anything else would silently run
  /// uncancelled, so reject it loudly instead.
  static CancellationToken? _resolve(iface.CancellationToken? token) {
    if (token == null) return null;
    if (token is CancellationToken) return token;
    throw ArgumentError.value(
        token, 'cancellationToken', 'must come from CancellationToken.create');
  }

  @override
  Future<AudioFingerprint> fingerprint(String path,
      {iface.CancellationToken? cancellationToken}) async {
    final token = _resolve(cancellationToken);
    return HaudioFingerprint.fingerprint(path, cancellationToken: token);
  }

  @override
  Future<AudioFingerprint> fingerprintFromBytes(Uint8List bytes,
      {iface.CancellationToken? cancellationToken}) async {
    final token = _resolve(cancellationToken);
    return HaudioFingerprint.fingerprintFromBytes(bytes,
        cancellationToken: token);
  }

  @override
  Future<double> similarity(AudioFingerprint a, AudioFingerprint b) async {
    return HaudioFingerprint.similarity(a, b);
  }

  @override
  Future<double> contains(
      AudioFingerprint haystack, AudioFingerprint clip) async {
    return HaudioFingerprint.contains(haystack, clip);
  }
}

/// Self-registration: the generated plugin registrant calls [registerWith]
/// at app startup, so merely installing this package wires the backend.
abstract final class HaudioFingerprintBackend {
  static void registerWith([dynamic _]) {
    iface.FingerprintRegistry.instance = const FingerprintBackendImpl();
  }
}

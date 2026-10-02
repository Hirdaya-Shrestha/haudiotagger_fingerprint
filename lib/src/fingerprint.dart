import 'dart:typed_data';

import 'package:haudiotagger_interface/haudiotagger_interface.dart'
    show AudioFingerprint;
import 'package:haudiotagger_interface/haudiotagger_interface.dart' as iface;

import 'rust/frb_generated.dart';
import 'rust/api/error.dart' show FingerprintError_Fingerprint;
import 'rust/api/fingerprint.dart' as fp;

export 'package:haudiotagger_interface/haudiotagger_interface.dart'
    show AudioFingerprint;
export 'rust/api/error.dart'
    show
        FingerprintError,
        FingerprintError_OpenFile,
        FingerprintError_Decode,
        FingerprintError_Unsupported,
        FingerprintError_Fingerprint,
        FingerprintError_Cancelled;

/// Cooperative cancellation handle for long fingerprint scans.
///
/// Create one token per scan, pass it to [HaudioFingerprint.fingerprint] or
/// [HaudioFingerprint.fingerprintFromBytes], and call [cancel] when the work
/// is no longer needed (e.g. the user changed track). In-flight Rust work
/// observing the trip aborts with `FingerprintError.cancelled`.
///
/// ```dart
/// final token = await CancellationToken.create();
/// final future = HaudioFingerprint.fingerprintFromBytes(bytes,
///     cancellationToken: token);
/// await token.cancel(); // abandon the scan
/// ```
class CancellationToken implements iface.CancellationToken {
  final BigInt _id;
  bool _disposed = false;

  CancellationToken._(this._id);

  /// Engine handle backing this token. Provider-side use only: the backend
  /// reads it when this token crosses the `haudiotagger_interface` contract.
  BigInt get id => _id;

  /// Create a token. One token per scan; [dispose] it when done.
  static Future<CancellationToken> create() async {
    await HaudioFingerprint._ensureInit();
    return CancellationToken._(fp.cancellationTokenNew());
  }

  /// Trip the token. In-flight work aborts with `FingerprintError.cancelled`.
  /// Safe to call multiple times or after [dispose].
  @override
  Future<void> cancel() async {
    await HaudioFingerprint._ensureInit();
    if (_disposed) return;
    fp.cancellationTokenCancel(id: _id);
  }

  /// Release the token id. Safe to call multiple times.
  Future<void> dispose() async {
    await HaudioFingerprint._ensureInit();
    if (_disposed) return;
    _disposed = true;
    fp.cancellationTokenFree(id: _id);
  }
}

/// Perceptual audio fingerprinting.
///
/// Fingerprint the *content* to find duplicates, renames, and re-encodes
/// regardless of tags or filenames.
///
/// ```dart
/// final a = await HaudioFingerprint.fingerprint('Song A.mp3');
/// final b = await HaudioFingerprint.fingerprint('song_copy.mp3');
/// final score = await HaudioFingerprint.similarity(a, b); // 1.0
/// ```
class HaudioFingerprint {
  static Future<void>? _initFuture;

  /// Must match `FINGERPRINT_API_VERSION` in rust/src/api/fingerprint.rs.
  /// Bump both together whenever an FRB signature changes.
  static const _apiVersion = 1;

  /// Largest input accepted by [fingerprintFromBytes].
  ///
  /// FRB transfers Dart→Rust through a doubling buffer addressed by signed
  /// 32-bit lengths: any message that would grow past 2³¹ bytes turns
  /// negative across FFI and aborts native code with `capacity overflow`.
  /// Capping the input below 2³⁰ keeps every growth step in range.
  static const maxBytesLength = 1073741824 - 65536;

  static Future<void> _ensureInit() => _initFuture ??= _initAndVerify();

  static Future<void> _initAndVerify() async {
    await RustLib.init();
    final native = fp.fingerprintApiVersion();
    if (native != _apiVersion) {
      throw StateError('haudiotagger_fingerprint native library out of sync '
          '(Dart $_apiVersion vs native $native). '
          'Run flutter clean and rebuild the app.');
    }
  }

  /// Fingerprint the audio file at `path`.
  ///
  /// Decodes the full stream, so tags, filenames, and containers do not
  /// affect the result. Supports MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC.
  ///
  /// Runs off the calling thread (native) or cooperatively (web). Pass a
  /// [cancellationToken] to abort long scans.
  static Future<AudioFingerprint> fingerprint(String path,
      {CancellationToken? cancellationToken}) async {
    await _ensureInit();
    final raw =
        await fp.fingerprint(path: path, cancelId: cancellationToken?._id);
    return AudioFingerprint(values: raw.values, durationSecs: raw.durationSecs);
  }

  /// Fingerprint in-memory audio `bytes` (for web/WASM).
  ///
  /// Pass a [cancellationToken] to abort long scans.
  ///
  /// Throws [FingerprintError] if `bytes` exceeds [maxBytesLength] — use
  /// [fingerprint] on native instead, which streams from disk.
  static Future<AudioFingerprint> fingerprintFromBytes(Uint8List bytes,
      {CancellationToken? cancellationToken}) async {
    await _ensureInit();
    if (bytes.length > maxBytesLength) {
      throw FingerprintError_Fingerprint(
          message: 'Audio data (${bytes.length} bytes) exceeds the '
              'in-memory transfer limit ($maxBytesLength bytes). '
              'On native, use fingerprint(path), which streams from disk.');
    }
    final raw = await fp.fingerprintFromBytes(
        bytes: bytes, cancelId: cancellationToken?._id);
    return AudioFingerprint(values: raw.values, durationSecs: raw.durationSecs);
  }

  /// Compare two fingerprints: `1.0` is (near-)identical audio, `0.0` is
  /// unrelated. Same recording in different encodings scores high.
  static Future<double> similarity(
      AudioFingerprint a, AudioFingerprint b) async {
    await _ensureInit();
    return fp.similarity(
        a: fp.AudioFingerprint(values: a.values, durationSecs: a.durationSecs),
        b: fp.AudioFingerprint(values: b.values, durationSecs: b.durationSecs));
  }
}

/// Convenience: `a.similarityTo(b)`.
extension AudioFingerprintX on AudioFingerprint {
  Future<double> similarityTo(AudioFingerprint other) =>
      HaudioFingerprint.similarity(this, other);
}

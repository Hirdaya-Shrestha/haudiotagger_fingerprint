import 'dart:typed_data';

import 'rust/frb_generated.dart';
import 'rust/api/fingerprint.dart' as fp;
import 'rust/api/fingerprint.dart' show AudioFingerprint;

export 'rust/api/fingerprint.dart' show AudioFingerprint;
export 'rust/api/error.dart' show FingerprintError;

/// Perceptual audio fingerprinting.
///
/// Works alongside `haudiotagger` (which reads metadata): fingerprint the
/// *content* to find duplicates, renames, and re-encodes regardless of
/// tags or filenames.
///
/// ```dart
/// final a = await HaudioFingerprint.fingerprint('Song A.mp3');
/// final b = await HaudioFingerprint.fingerprint('song_copy.mp3');
/// final score = await HaudioFingerprint.similarity(a, b); // 1.0
/// ```
class HaudioFingerprint {
  static Future<void>? _initFuture;

  static Future<void> _ensureInit() => _initFuture ??= RustLib.init();

  /// Fingerprint the audio file at `path`.
  ///
  /// Decodes the full stream, so tags, filenames, and containers do not
  /// affect the result. Supports MP3, FLAC, Ogg Vorbis, WAV, AIFF, M4A/AAC.
  static Future<AudioFingerprint> fingerprint(String path) async {
    await _ensureInit();
    return fp.fingerprint(path: path);
  }

  /// Fingerprint in-memory audio `bytes` (for web/WASM).
  static Future<AudioFingerprint> fingerprintFromBytes(Uint8List bytes) async {
    await _ensureInit();
    return fp.fingerprintFromBytes(bytes: bytes);
  }

  /// Compare two fingerprints: `1.0` is (near-)identical audio, `0.0` is
  /// unrelated. Same recording in different encodings scores high.
  static Future<double> similarity(
      AudioFingerprint a, AudioFingerprint b) async {
    await _ensureInit();
    return fp.similarity(a: a, b: b);
  }
}

/// Convenience: `a.similarityTo(b)`.
extension AudioFingerprintX on AudioFingerprint {
  Future<double> similarityTo(AudioFingerprint other) =>
      HaudioFingerprint.similarity(this, other);
}

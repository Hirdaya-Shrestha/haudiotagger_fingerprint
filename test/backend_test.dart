import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';
import 'package:haudiotagger_fingerprint/src/web_plugin.dart';
import 'package:haudiotagger_interface/haudiotagger_interface.dart' as iface;

// Proves the federated wiring: the dartPluginClass registration hooks the
// real Rust backend into the shared registry — the same path
// Haudiotagger.fingerprint() takes when both packages are installed.
void main() {
  test('dartPluginClass registration wires the real backend', () async {
    HaudioFingerprintBackend.registerWith();
    final fp = await iface.FingerprintRegistry.instance.fingerprintFromBytes(
      File('test/fixtures/chirp.mp3').readAsBytesSync(),
    );
    expect(fp.values, isNotEmpty);
    expect(fp.durationSecs, 5);
  });

  test('registry similarity scores identical audio 1.0', () async {
    HaudioFingerprintBackend.registerWith();
    final bytes = File('test/fixtures/chirp.flac').readAsBytesSync();
    final a =
        await iface.FingerprintRegistry.instance.fingerprintFromBytes(bytes);
    final b =
        await iface.FingerprintRegistry.instance.fingerprintFromBytes(bytes);
    expect(await iface.FingerprintRegistry.instance.similarity(a, b), 1.0);
  });

  test('web registrant path wires the real backend', () async {
    // The web plugin registrant never calls dartPluginClass, so the web
    // plugin class must register the backend itself. Regression test:
    // without it, Haudiotagger.fingerprint() on web throws "no backend
    // registered" even with the package installed.
    iface.FingerprintRegistry.instance = _UnregisteredProbe();
    HaudioFingerprintWeb.registerWith();
    final fp = await iface.FingerprintRegistry.instance.fingerprintFromBytes(
      File('test/fixtures/chirp.ogg').readAsBytesSync(),
    );
    expect(fp.values, isNotEmpty);
  });
}

class _UnregisteredProbe implements iface.FingerprintBackend {
  @override
  Future<iface.AudioFingerprint> fingerprint(String path) =>
      throw StateError('not wired');

  @override
  Future<iface.AudioFingerprint> fingerprintFromBytes(Uint8List bytes) =>
      throw StateError('not wired');

  @override
  Future<double> similarity(
          iface.AudioFingerprint a, iface.AudioFingerprint b) =>
      throw StateError('not wired');
}

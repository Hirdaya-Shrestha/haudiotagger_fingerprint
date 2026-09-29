import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';
import 'package:haudiotagger_fingerprint/src/web_plugin.dart';
import 'package:haudiotagger_interface/haudiotagger_interface.dart' as iface;
import 'dart:typed_data';

import 'test_utils.dart';

// Proves the federated wiring: the dartPluginClass registration hooks the
// real Rust backend into the shared registry — the same path
// Haudiotagger.fingerprint() takes when both packages are installed.
//
// Uses synthesized WAV bytes (no dart:io) so these tests also run in a real
// browser via `flutter test --platform chrome`.
void main() {
  test('dartPluginClass registration wires the real backend', () async {
    HaudioFingerprintBackend.registerWith();
    final fp = await iface.FingerprintRegistry.instance
        .fingerprintFromBytes(makeSweepWav());
    expect(fp.values, isNotEmpty);
    expect(fp.durationSecs, 3);
  });

  test('registry similarity scores identical audio 1.0', () async {
    HaudioFingerprintBackend.registerWith();
    final bytes = makeSweepWav(f0: 440.0, f1: 660.0);
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
    final fp = await iface.FingerprintRegistry.instance
        .fingerprintFromBytes(makeSweepWav(f0: 200.0, f1: 300.0));
    expect(fp.values, isNotEmpty);
  });

  test('interface-typed token flows through registry to engine', () async {
    HaudioFingerprintBackend.registerWith();
    final token = await CancellationToken.create();
    final fp = await iface.FingerprintRegistry.instance
        .fingerprintFromBytes(makeSweepWav(), cancellationToken: token);
    expect(fp.values, isNotEmpty);
    await token.dispose();
  });

  test('foreign token is rejected, never silently uncancelled', () async {
    HaudioFingerprintBackend.registerWith();
    expect(
      iface.FingerprintRegistry.instance.fingerprintFromBytes(makeSweepWav(),
          cancellationToken: _ForeignToken()),
      throwsA(isA<ArgumentError>()),
    );
  });
}

class _ForeignToken implements iface.CancellationToken {
  @override
  Future<void> cancel() async {}
}

class _UnregisteredProbe implements iface.FingerprintBackend {
  @override
  Future<iface.AudioFingerprint> fingerprint(String path,
          {iface.CancellationToken? cancellationToken}) =>
      throw StateError('not wired');

  @override
  Future<iface.AudioFingerprint> fingerprintFromBytes(Uint8List bytes,
          {iface.CancellationToken? cancellationToken}) =>
      throw StateError('not wired');

  @override
  Future<double> similarity(
          iface.AudioFingerprint a, iface.AudioFingerprint b) =>
      throw StateError('not wired');
}

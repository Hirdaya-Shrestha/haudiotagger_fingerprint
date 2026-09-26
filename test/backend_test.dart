import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';
import 'package:haudiotagger_interface/haudiotagger_interface.dart';

// Proves the federated wiring: the dartPluginClass registration hooks the
// real Rust backend into the shared registry — the same path
// Haudiotagger.fingerprint() takes when both packages are installed.
void main() {
  test('dartPluginClass registration wires the real backend', () async {
    HaudioFingerprintBackend.registerWith();
    final fp = await FingerprintRegistry.instance.fingerprintFromBytes(
      File('test/fixtures/chirp.mp3').readAsBytesSync(),
    );
    expect(fp.values, isNotEmpty);
    expect(fp.durationSecs, 5);
  });

  test('registry similarity scores identical audio 1.0', () async {
    HaudioFingerprintBackend.registerWith();
    final bytes = File('test/fixtures/chirp.flac').readAsBytesSync();
    final a = await FingerprintRegistry.instance.fingerprintFromBytes(bytes);
    final b = await FingerprintRegistry.instance.fingerprintFromBytes(bytes);
    expect(await FingerprintRegistry.instance.similarity(a, b), 1.0);
  });
}

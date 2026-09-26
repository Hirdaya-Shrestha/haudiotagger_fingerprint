import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

Uint8List fixture(String name) => File('test/fixtures/$name').readAsBytesSync();

void main() {
  group('fingerprintFromBytes', () {
    test('decodes wav, mp3, flac, ogg, m4a with matching durations', () async {
      for (final name in [
        'chirp.wav',
        'chirp.mp3',
        'chirp.flac',
        'chirp.ogg',
        'chirp.m4a',
      ]) {
        final fp = await HaudioFingerprint.fingerprintFromBytes(fixture(name));
        expect(fp.values, isNotEmpty, reason: name);
        expect(fp.durationSecs, 5, reason: name);
      }
    });

    test('identical bytes give identical fingerprints', () async {
      final bytes = fixture('chirp.mp3');
      final a = await HaudioFingerprint.fingerprintFromBytes(bytes);
      final b = await HaudioFingerprint.fingerprintFromBytes(bytes);
      expect(a.values, b.values);
    });

    test('rejects non-audio bytes', () async {
      expect(
        HaudioFingerprint.fingerprintFromBytes(
            Uint8List.fromList('not audio'.codeUnits)),
        throwsA(isA<FingerprintError>()),
      );
    });
  });

  group('similarity', () {
    test('identical fingerprints score 1.0', () async {
      final fp =
          await HaudioFingerprint.fingerprintFromBytes(fixture('chirp.flac'));
      expect(await HaudioFingerprint.similarity(fp, fp), 1.0);
    });

    test('same recording in different encodings scores high', () async {
      final mp3 =
          await HaudioFingerprint.fingerprintFromBytes(fixture('chirp.mp3'));
      final flac =
          await HaudioFingerprint.fingerprintFromBytes(fixture('chirp.flac'));
      expect(await mp3.similarityTo(flac), greaterThan(0.8));
    });

    test('renames and copies match: same bytes, different names', () async {
      final bytes = fixture('chirp.ogg');
      final original = await HaudioFingerprint.fingerprintFromBytes(bytes);
      final copy = await HaudioFingerprint.fingerprintFromBytes(
          Uint8List.fromList(bytes));
      expect(await original.similarityTo(copy), 1.0);
    });
  });
}

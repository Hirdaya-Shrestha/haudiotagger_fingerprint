import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';
import 'package:haudiotagger_interface/haudiotagger_interface.dart'
    show FingerprintRegistry;

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

  group('cancellation', () {
    test('pre-cancelled token aborts with cancelled error', () async {
      final token = await CancellationToken.create();
      await token.cancel();
      expect(
        HaudioFingerprint.fingerprintFromBytes(fixture('chirp.mp3'),
            cancellationToken: token),
        throwsA(isA<FingerprintError_Cancelled>()),
      );
      await token.dispose();
    });

    test('unused token changes nothing', () async {
      final token = await CancellationToken.create();
      final fp = await HaudioFingerprint.fingerprintFromBytes(
          fixture('chirp.mp3'),
          cancellationToken: token);
      expect(fp.values, isNotEmpty);
      await token.dispose();
    });

    test('double cancel and dispose are safe', () async {
      final token = await CancellationToken.create();
      await token.cancel();
      await token.cancel();
      await token.dispose();
      await token.dispose();
      await token.cancel();
    });
  });

  group('contains', () {
    test('finds clip cut from the song', () async {
      final song =
          await HaudioFingerprint.fingerprintFromBytes(fixture('song20.mp3'));
      final clip =
          await HaudioFingerprint.fingerprintFromBytes(fixture('clip3.mp3'));
      expect(await HaudioFingerprint.contains(song, clip), greaterThan(0.7));
    });

    test('identical fingerprints contain each other fully', () async {
      final fp =
          await HaudioFingerprint.fingerprintFromBytes(fixture('chirp.flac'));
      expect(await HaudioFingerprint.contains(fp, fp), 1.0);
    });

    test('works through the registry like Haudiotagger would', () async {
      HaudioFingerprintBackend.registerWith();
      final song =
          await HaudioFingerprint.fingerprintFromBytes(fixture('song20.mp3'));
      final clip =
          await HaudioFingerprint.fingerprintFromBytes(fixture('clip3.mp3'));
      expect(await FingerprintRegistry.instance.contains(song, clip),
          greaterThan(0.7));
    });
  });
}

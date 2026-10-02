import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart'
    show AudioFingerprint, FingerprintError, HaudioFingerprint;

// clip3.mp3 is seconds 8-13 of song20.mp3 - cut lossless, then encoded.
// (Cutting mp3->mp3 directly misplaces the audio; don't "regenerate" it
// that way.) chirp.mp3 is unrelated audio recorded under the same codec.
Future<AudioFingerprint> fixture(String name) =>
    HaudioFingerprint.fingerprintFromBytes(
        File('test/fixtures/$name').readAsBytesSync());

void main() {
  group('contains', () {
    test('finds an exact excerpt where similarity sees little', () async {
      final song = await fixture('song20.mp3');
      final clip = await fixture('clip3.mp3');
      expect(await HaudioFingerprint.contains(song, clip), greaterThan(0.7));
      // Same pair, global view: the clip is a small slice of the song.
      expect(await HaudioFingerprint.similarity(song, clip), lessThan(0.3));
    });

    test('rejects an unrelated clip', () async {
      final song = await fixture('song20.mp3');
      final unrelated = await fixture('chirp.mp3');
      expect(await HaudioFingerprint.contains(song, unrelated), lessThan(0.7));
    });

    test('rejects an empty clip', () async {
      final song = await fixture('song20.mp3');
      await expectLater(
        HaudioFingerprint.contains(
            song, AudioFingerprint(values: Uint32List(0), durationSecs: 0)),
        throwsA(isA<FingerprintError>()),
      );
    });
  });
}

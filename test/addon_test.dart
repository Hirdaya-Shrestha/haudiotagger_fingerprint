import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger/haudiotagger.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

// Proves the standalone-yet-seamless contract: both packages imported
// together, zero conflicts, and they compose.
void main() {
  test('metadata + fingerprint compose via single import', () async {
    final merged = Haudiotagger.mergeTags(
      Tag(title: 'Song A', pictures: []),
      Tag(trackArtist: 'Artist', pictures: []),
    );
    expect(merged.title, 'Song A');
    expect(merged.trackArtist, 'Artist');

    final bytes = File('test/fixtures/chirp.mp3').readAsBytesSync();
    final fp = await HaudioFingerprint.fingerprintFromBytes(bytes);
    expect(fp.values, isNotEmpty);

    // The documented duplicate-detection recipe, end to end.
    final copy = await HaudioFingerprint.fingerprintFromBytes(bytes);
    expect(await fp.similarityTo(copy), 1.0);
    expect(merged.title, 'Song A');
  });
}

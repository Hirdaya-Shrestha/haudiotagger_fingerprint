import 'package:flutter_test/flutter_test.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    // Just verify the library imports resolve
    expect(HaudioFingerprint, isNotNull);
    expect(AudioFingerprint, isNotNull);
  });
}

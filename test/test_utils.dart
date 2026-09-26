import 'dart:math';
import 'dart:typed_data';

/// Synthesizes a 16-bit PCM WAV (linear frequency sweep) in memory so the
/// same tests run on the VM and in the browser (no `dart:io`).
Uint8List makeSweepWav({
  double f0 = 440.0,
  double f1 = 880.0,
  int secs = 3,
  int sampleRate = 44100,
}) {
  final n = secs * sampleRate;
  final data = ByteData(44 + n * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final phase = 2 * pi * (f0 * t + (f1 - f0) * t * t / (2 * secs));
    data.setInt16(44 + i * 2, (sin(phase) * 20000).toInt(), Endian.little);
  }
  return data.buffer.asUint8List();
}

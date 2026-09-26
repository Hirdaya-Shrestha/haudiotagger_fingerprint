import 'package:flutter/material.dart';
import 'package:haudiotagger_fingerprint/haudiotagger_fingerprint.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _firstCtrl = TextEditingController();
  final _secondCtrl = TextEditingController();
  String _result = 'Enter two audio file paths to compare them.';

  Future<void> _compare() async {
    try {
      final a = await HaudioFingerprint.fingerprint(_firstCtrl.text.trim());
      final b = await HaudioFingerprint.fingerprint(_secondCtrl.text.trim());
      final score = await a.similarityTo(b);
      setState(() {
        _result = score >= 0.8
            ? 'Same recording (similarity ${score.toStringAsFixed(3)}).'
            : 'Different recordings (similarity ${score.toStringAsFixed(3)}).';
      });
    } on FingerprintError catch (e) {
      setState(() => _result = 'Error: $e');
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('haudiotagger_fingerprint demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _firstCtrl,
                decoration:
                    const InputDecoration(labelText: 'First audio file path'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _secondCtrl,
                decoration:
                    const InputDecoration(labelText: 'Second audio file path'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _compare,
                child: const Text('Compare'),
              ),
              const SizedBox(height: 16),
              Text(_result),
            ],
          ),
        ),
      ),
    );
  }
}

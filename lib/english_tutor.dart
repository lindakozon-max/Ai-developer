import 'package:flutter/material.dart';

import 'services/groq_tutor_service.dart';

class EnglishTutorScreen extends StatefulWidget {
  const EnglishTutorScreen({super.key, required this.onLessonCompleted});
  final VoidCallback onLessonCompleted;

  @override
  State<EnglishTutorScreen> createState() => _EnglishTutorScreenState();
}

class _EnglishTutorScreenState extends State<EnglishTutorScreen> {
  final _messageController = TextEditingController();
  final _tutor = GroqTutorService();
  final _messages = <String>[];
  final _levels = const [
    'Level 1 • Pre-A1', 'Level 2 • A1', 'Level 3 • A2',
    'Level 4 • B1', 'Level 5 • B2', 'Level 6 • C1',
    'Level 7 • C2', 'Level 8 • Fluent', 'Level 9 • Mastery',
  ];
  String _level = 'Level 1 • Pre-A1';
  String _language = 'Slovak';
  final _fishNames = <String>['Bubbles'];
  final _fishColors = <Color>[Colors.orange];
  int _lessons = 0;
  int _plants = 1;
  bool _busy = false;
  bool _lessonReady = false;

  @override
  void dispose() {
    _messageController.dispose();
    _tutor.close();
    super.dispose();
  }

  Future<void> _ask([String? prompt]) async {
    final text = (prompt ?? _messageController.text).trim();
    if (text.isEmpty || _busy) return;
    _messageController.clear();
    setState(() { _busy = true; _messages.add('You: $text'); });
    try {
      final answer = await _tutor.ask(message: text, level: _level, language: _language);
      if (mounted) setState(() {
        _messages.add('Finn: $answer');
        if (prompt != null && prompt.startsWith('Give me today')) _lessonReady = true;
      });
    } catch (_) {
      if (mounted) setState(() => _messages.add(
          'Finn: I cannot connect right now. Please check your internet and try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _completeLesson() {
    setState(() {
      _lessons++;
      _lessonReady = false;
      if (_lessons.isEven) {
        _fishNames.add('Fish ${_fishNames.length + 1}');
        _fishColors.add(Colors.primaries[_fishNames.length % Colors.primaries.length]);
      }
      if (_lessons % 3 == 0) _plants++;
    });
    widget.onLessonCompleted();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson complete! +10 coins and your tank grew.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Finn’s English Aquarium')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xffd9f3ff),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🐠 Your tiny fish tank', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('🐟 Fish: ${_fishNames.length}    🌿 Plants: $_plants    📚 Lessons: $_lessons'),
                  Wrap(spacing: 8, children: [
                    for (var i = 0; i < _fishNames.length; i++) Chip(
                      avatar: CircleAvatar(backgroundColor: _fishColors[i]),
                      label: Text(_fishNames[i]),
                    ),
                  ]),
                  const Text('Finish a lesson to grow the tank and earn 10 coins.'),
                ]),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Choose your English level'),
              items: _levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
              onChanged: (value) => setState(() => _level = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Help language'),
              items: const ['English', 'Slovak'].map((language) => DropdownMenuItem(value: language, child: Text(language))).toList(),
              onChanged: (value) => setState(() => _language = value!),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _ask('Give me today’s short English lesson for $_level. Include a tiny exercise.'),
              icon: const Icon(Icons.school), label: const Text('Start today’s lesson'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _ask('Give me a short English test for $_level. Ask 3 questions and grade my answers kindly.'),
              icon: const Icon(Icons.quiz), label: const Text('Take a tiny test'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _ask('Check my English level with a friendly mini assessment. Tell me if I am Pre-A1, A1, A2, B1, B2, C1 or C2 and explain why.'),
              icon: const Icon(Icons.insights), label: const Text('Check my English level'),
            ),
            OutlinedButton.icon(
              onPressed: _lessonReady ? _completeLesson : null,
              icon: const Icon(Icons.stars), label: const Text('Mark lesson complete (+10 coins)'),
            ),
            const SizedBox(height: 12),
            if (_messages.isNotEmpty) Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final message in _messages) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(message)),
                  if (_busy) const LinearProgressIndicator(),
                ]),
              ),
            ),
            TextField(
              controller: _messageController, minLines: 1, maxLines: 3,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                labelText: 'Talk to Finn in English or Slovak',
                suffixIcon: IconButton(onPressed: _busy ? null : _ask, icon: const Icon(Icons.send)),
              ),
            ),
          ],
        ),
      );
}

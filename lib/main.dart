import 'package:flutter/material.dart';

void main() {
  runApp(const FlappyBirdLectureApp());
}

class FlappyBirdLectureApp extends StatelessWidget {
  const FlappyBirdLectureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flappy Bird',
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Build your Flappy Bird game here')),
    );
  }
}

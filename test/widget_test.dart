import 'package:flappy_bird/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lecture starter builds', (tester) async {
    await tester.pumpWidget(const FlappyBirdLectureApp());

    expect(find.text('Build your Flappy Bird game here'), findsOneWidget);
  });
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/animal.dart';
import 'domain/game_state.dart';
import 'domain/inventory.dart';
import 'farm_game.dart';

void main() => runApp(const FarmApp());

class FarmApp extends StatelessWidget {
  const FarmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sunny Paws Farm',
        theme: ThemeData(colorSchemeSeed: const Color(0xffe8927e), useMaterial3: true),
        home: const MenuScreen(),
      );
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xffffe7b8),
        body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Sunny Paws Farm', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xff76506a))),
          const SizedBox(height: 12),
          const Text('A tiny happy farm', style: TextStyle(fontSize: 18, color: Color(0xff76506a))),
          const SizedBox(height: 30),
          FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmScreen())), icon: const Icon(Icons.grass), label: const Text('Open farm')),
        ]))),
      );
}

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});
  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  late GameState state;
  late final FarmGame game;
  @override
  void initState() {
    super.initState();
    state = GameState(animals: {'biscuit': const Animal(id: 'biscuit', name: 'Biscuit', needs: AnimalNeeds(hunger: 45, happiness: 70))}, inventory: const Inventory(food: 3));
    game = FarmGame(onAnimalTapped: _showAnimal);
  }

  void _showAnimal() {
    final animal = state.animals['biscuit']!;
    showModalBottomSheet<void>(context: context, builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(animal.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Hunger: ${animal.needs.hunger}%   Happiness: ${animal.needs.happiness}%'),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: state.inventory.food == 0 ? null : () { setState(() => state = feedAnimal(state, animal.id)); Navigator.pop(context); }, icon: const Icon(Icons.restaurant), label: Text('Feed (${state.inventory.food} left)')),
          ]),
        ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sunny Paws Farm'), backgroundColor: const Color(0xffffe7b8)),
        body: Column(children: [
          Expanded(child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              game.handleKeyEvent(event, HardwareKeyboard.instance.logicalKeysPressed);
              return KeyEventResult.handled;
            },
            child: GameWidget(game: game),
          )),
          const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Tap Biscuit • Move with WASD or arrow keys')),
        ]),
      );
}

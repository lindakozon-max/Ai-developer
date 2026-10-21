import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/animal.dart';
import 'domain/game_state.dart';
import 'domain/inventory.dart';
import 'domain/horse.dart';
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
    state = GameState(
      animals: {'biscuit': const Animal(id: 'biscuit', name: 'Biscuit', needs: AnimalNeeds(hunger: 45, happiness: 70))},
      inventory: const Inventory(food: 3),
      horses: {'horse-1': const Horse(id: 'horse-1', name: 'Chestnut', variant: HorseVariant.chestnut)},
    );
    game = FarmGame(onAnimalTapped: _showAnimal, onHorseTapped: _showHorse);
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

  void _showHorse(HorseComponent component) {
    final horse = state.horses[component.id];
    if (horse == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(horse.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('${horse.variant.name} horse  •  ${state.coins} coins'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() => state = petHorse(state, horse.id)),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet (+10 coins)'),
          ),
          FilledButton.icon(
            onPressed: horse.hasSaddle || state.coins < 30 ? null : () {
              setState(() {
                state = buySaddle(state, horse.id);
                component.hasSaddle = true;
              });
            },
            icon: const Icon(Icons.event_seat),
            label: Text(horse.hasSaddle ? 'Saddle fitted' : 'Buy saddle (30)'),
          ),
          FilledButton.icon(
            onPressed: horse.decorations.contains('flower') || state.coins < 20 ? null : () {
              setState(() {
                state = buyDecoration(state, horse.id, 'flower');
                component.decorations.add('flower');
              });
            },
            icon: const Icon(Icons.local_florist),
            label: Text(horse.decorations.contains('flower') ? 'Flower added' : 'Buy flower (20)'),
          ),
        ]),
      ),
    );
  }

  void _buyHorse() {
    if (state.coins < 50) return;
    final variants = HorseVariant.values;
    final horse = Horse(id: 'horse-${state.horses.length + 1}', name: 'Horse ${state.horses.length + 1}', variant: variants[state.horses.length % variants.length]);
    final nextState = buyHorse(state, horse);
    if (nextState.horses.length == state.horses.length) return;
    setState(() => state = nextState);
    game.addHorse(horse.variant);
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
            child: Stack(children: [
              GameWidget(game: game),
              Positioned(
                top: 16,
                right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(12)),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Coins: ${state.coins}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: state.coins < 50 ? null : _buyHorse, icon: const Icon(Icons.add), label: const Text('Buy horse (50)')),
                ]),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: Column(children: [
                  _MoveButton(icon: Icons.keyboard_arrow_up, label: 'Move up', onPressed: () => game.movePlayer(Vector2(0, -8))),
                  Row(children: [
                    _MoveButton(icon: Icons.keyboard_arrow_left, label: 'Move left', onPressed: () => game.movePlayer(Vector2(-8, 0))),
                    const SizedBox(width: 48),
                    _MoveButton(icon: Icons.keyboard_arrow_right, label: 'Move right', onPressed: () => game.movePlayer(Vector2(8, 0))),
                  ]),
                  _MoveButton(icon: Icons.keyboard_arrow_down, label: 'Move down', onPressed: () => game.movePlayer(Vector2(0, 8))),
                ]),
              ),
            ]),
          )),
          const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Tap Biscuit • Move with WASD or arrow keys')),
        ]),
      );
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        height: 48,
        child: IconButton.filled(
          onPressed: onPressed,
          tooltip: label,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xff76506a),
            foregroundColor: Colors.white,
          ),
        ),
      );
}

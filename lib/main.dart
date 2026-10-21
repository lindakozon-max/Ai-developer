import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/animal.dart';
import 'domain/game_state.dart';
import 'domain/horse.dart';
import 'farm_game.dart';

void main() => runApp(const FarmApp());
String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';

class FarmApp extends StatelessWidget {
  const FarmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sunny Paws Farm',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xffe8927e),
      useMaterial3: true,
    ),
    home: const MenuScreen(),
  );
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffffe7b8),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sunny Paws Farm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xff76506a),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A tiny happy farm',
              style: TextStyle(fontSize: 18, color: Color(0xff76506a)),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FarmScreen())),
              icon: const Icon(Icons.grass),
              label: const Text('Open farm'),
            ),
          ],
        ),
      ),
    ),
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
  final FocusNode _gameFocus = FocusNode();
  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    state = initialFarmState();
    game = FarmGame(
      onAnimalTapped: _showAnimal,
      onHorseTapped: _showHorse,
      initialAnimals: state.animals.values.toList(),
      initialHorses: state.horses.values.toList(),
    );
  }

  @override
  void dispose() {
    _gameFocus.dispose();
    super.dispose();
  }

  void _change(GameState next, StateSetter refresh) {
    setState(() => state = next);
    for (final horse in state.horses.values) {
      game.syncHorse(horse);
    }
    game.setRiddenHorse(state.riddenHorseId);
    refresh(() {});
  }

  Future<void> _showPanel(
    Widget Function(BuildContext, StateSetter) builder,
  ) async {
    if (_panelOpen) return;
    _panelOpen = true;
    game.clearMovement();
    game.pauseEngine();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: StatefulBuilder(builder: builder),
          ),
        ),
      );
    } finally {
      _panelOpen = false;
      if (mounted) {
        game.resumeEngine();
        _gameFocus.requestFocus();
      }
    }
  }

  void _showAnimal(AnimalComponent component) {
    _showPanel((context, refresh) {
      final animal = state.animals[component.id]!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            animal.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('${_title(animal.variant.name)} ${animal.kind.name}'),
          Text(
            'Hunger: ${animal.needs.hunger}%   Happiness: ${animal.needs.happiness}%',
          ),
          Text('${state.coins} coins'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.inventory.food <= 0
                ? null
                : () {
                    _change(feedAnimal(state, animal.id), refresh);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.restaurant),
            label: Text('Feed (${state.inventory.food} left)'),
          ),
          FilledButton.icon(
            onPressed: () => _change(petAnimal(state, animal.id), refresh),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet (+10 coins)'),
          ),
        ],
      );
    });
  }

  void _showHorse(HorseComponent component) {
    _showPanel((context, refresh) {
      final horse = state.horses[component.id]!;
      final riding = state.riddenHorseId == horse.id;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            horse.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('${_title(horse.variant.name)} horse • ${state.coins} coins'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _change(petHorse(state, horse.id), refresh),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet (+10 coins)'),
          ),
          FilledButton.icon(
            onPressed:
                !horse.hasSaddle || (!riding && state.riddenHorseId != null)
                ? null
                : () {
                    _change(
                      riding
                          ? dismountHorse(state)
                          : mountHorse(state, horse.id),
                      refresh,
                    );
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.directions_run),
            label: Text(riding ? 'Dismount' : 'Ride horse'),
          ),
          if (!horse.hasSaddle)
            const Text('Fit a saddle below to ride this horse.'),
          const SizedBox(height: 12),
          const Text(
            'Saddles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final saddle in SaddleType.values)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed:
                    horse.saddle == saddle ||
                        (!horse.ownedSaddles.contains(saddle) &&
                            state.coins < saddle.price)
                    ? null
                    : () {
                        _change(
                          horse.ownedSaddles.contains(saddle)
                              ? equipSaddle(state, horse.id, saddle)
                              : buySaddle(state, horse.id, saddle: saddle),
                          refresh,
                        );
                      },
                icon: Icon(
                  horse.saddle == saddle ? Icons.check : Icons.event_seat,
                ),
                label: Text(
                  '${_title(saddle.name)} saddle • ${horse.saddle == saddle
                      ? 'Fitted'
                      : horse.ownedSaddles.contains(saddle)
                      ? 'Equip'
                      : '${saddle.price} coins'}',
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: horse.decorations.contains('flower') || state.coins < 20
                ? null
                : () => _change(
                    buyDecoration(state, horse.id, 'flower'),
                    refresh,
                  ),
            icon: const Icon(Icons.local_florist),
            label: Text(
              horse.decorations.contains('flower')
                  ? 'Flower added'
                  : 'Buy flower (20)',
            ),
          ),
        ],
      );
    });
  }

  void _showMarket() {
    var kind = 'horse';
    var variantIndex = 0;
    _showPanel((context, refresh) {
      final animalKind = kind == 'horse'
          ? null
          : AnimalKind.values.byName(kind);
      final price = animalKind?.price ?? 50;
      final variants = kind == 'horse'
          ? HorseVariant.values.map((v) => v.name).toList()
          : AnimalVariant.values.map((v) => v.name).toList();
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Farm market',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('${state.coins} coins • Pet your animals to earn more.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const ValueKey('animal-kind'),
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Animal kind'),
            items: ['horse', ...AnimalKind.values.map((k) => k.name)]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_title(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => refresh(() {
              kind = value!;
              variantIndex = 0;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('variant-$kind'),
            initialValue: variantIndex,
            decoration: const InputDecoration(labelText: 'Coat variant'),
            items: List.generate(
              variants.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(_title(variants[index])),
              ),
            ),
            onChanged: (value) => refresh(() => variantIndex = value!),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.coins < price
                ? null
                : () {
                    if (animalKind == null) {
                      final horse = Horse(
                        id: 'horse-${state.horses.length + 1}',
                        name:
                            '${_title(variants[variantIndex])} horse ${state.horses.length + 1}',
                        variant: HorseVariant.values[variantIndex],
                      );
                      final next = buyHorse(state, horse);
                      if (identical(next, state)) return;
                      game.addHorse(horse);
                      _change(next, refresh);
                    } else {
                      final animal = Animal(
                        id: 'animal-${state.animals.length + 1}',
                        name:
                            '${_title(variants[variantIndex])} $kind ${state.animals.length + 1}',
                        kind: animalKind,
                        variant: AnimalVariant.values[variantIndex],
                        needs: const AnimalNeeds(hunger: 45, happiness: 70),
                      );
                      final next = buyAnimal(state, animal);
                      if (identical(next, state)) return;
                      game.addAnimal(animal);
                      _change(next, refresh);
                    }
                  },
            icon: const Icon(Icons.add),
            label: Text('Buy $kind ($price coins)'),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.animals.length + state.horses.length} animals on your farm',
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  void _dismount() {
    setState(() => state = dismountHorse(state));
    game.setRiddenHorse(null);
    game.clearMovement();
    _gameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sunny Paws Farm'),
      backgroundColor: const Color(0xffffe7b8),
    ),
    body: Column(
      children: [
        Expanded(
          child: Focus(
            focusNode: _gameFocus,
            autofocus: true,
            onFocusChange: (focused) {
              if (!focused) game.clearMovement();
            },
            onKeyEvent: (node, event) {
              if (_panelOpen) return KeyEventResult.ignored;
              game.handleKeyEvent(
                event,
                HardwareKeyboard.instance.logicalKeysPressed,
              );
              return KeyEventResult.handled;
            },
            child: Stack(
              children: [
                GameWidget(game: game),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'Coins: ${state.coins}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showMarket,
                        icon: const Icon(Icons.storefront),
                        label: const Text('Farm market'),
                      ),
                      if (state.riddenHorseId != null)
                        FilledButton.icon(
                          onPressed: _dismount,
                          icon: const Icon(Icons.stop),
                          label: const Text('Dismount'),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _MoveButton(
                        game: game,
                        icon: Icons.keyboard_arrow_up,
                        label: 'Move up',
                        direction: Vector2(0, -1),
                      ),
                      Row(
                        children: [
                          _MoveButton(
                            game: game,
                            icon: Icons.keyboard_arrow_left,
                            label: 'Move left',
                            direction: Vector2(-1, 0),
                          ),
                          const SizedBox(width: 48),
                          _MoveButton(
                            game: game,
                            icon: Icons.keyboard_arrow_right,
                            label: 'Move right',
                            direction: Vector2(1, 0),
                          ),
                        ],
                      ),
                      _MoveButton(
                        game: game,
                        icon: Icons.keyboard_arrow_down,
                        label: 'Move down',
                        direction: Vector2(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              state.riddenHorseId == null
                  ? 'Tap animals to care for them • Fit a saddle to ride\nMove with WASD, arrows, or hold the buttons'
                  : 'Riding • Move with WASD, arrows, or hold the buttons',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.game,
    required this.icon,
    required this.label,
    required this.direction,
  });
  final FarmGame game;
  final IconData icon;
  final String label;
  final Vector2 direction;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => game.setMoveDirection(direction),
    onPointerUp: (_) => game.setMoveDirection(Vector2.zero()),
    onPointerCancel: (_) => game.setMoveDirection(Vector2.zero()),
    child: SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        onPressed: () => game.movePlayer(direction * 8),
        tooltip: label,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xff76506a),
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );
}

import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/animal.dart';
import 'domain/dragon.dart';
import 'domain/game_state.dart';
import 'domain/horse.dart';
import 'domain/farm_item.dart';
import 'domain/inventory.dart';
import 'services/weather_service.dart';
import 'farm_game.dart';

part 'dragon_panels.dart';

void main() => runApp(const FarmApp());
String _title(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}'.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]!.toLowerCase()}',
    );

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
  final WeatherService _weatherService = WeatherService();
  Timer? _weatherTimer;
  String _weatherStatus = 'Bratislava–Rača • Loading weather…';

  Future<void> _refreshWeather() async {
    try {
      final weather = await _weatherService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        game.weather = weather;
        final time = weather.observedAt.toIso8601String().substring(11, 16);
        _weatherStatus =
            'Bratislava–Rača • ${weather.temperatureC.toStringAsFixed(1)}°C • ${weather.condition}\nOpen-Meteo • $time local';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _weatherStatus = game.weather == null
            ? 'Bratislava–Rača • Weather unavailable • Retry'
            : 'Bratislava–Rača • Last weather is stale • Retry',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    state = initialFarmState();
    game = FarmGame(
      onAnimalTapped: _showAnimal,
      onHorseTapped: _showHorse,
      onDragonTapped: (dragon) => showDragonPanel(dragon),
      initialAnimals: state.animals.values.toList(),
      initialHorses: state.horses.values.toList(),
      initialDragons: state.dragons.values.toList(),
    );
    _refreshWeather();
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _refreshWeather(),
    );
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _weatherService.close();
    _gameFocus.dispose();
    super.dispose();
  }

  void _change(GameState next, StateSetter refresh) {
    setState(() => state = next);
    for (final horse in state.horses.values) {
      game.addHorse(horse);
      game.syncHorse(horse);
    }
    for (final dragon in state.dragons.values) {
      game.addDragon(dragon);
      game.syncDragon(dragon);
    }
    game.ownedPurchases = state.ownedPurchases;
    game.setRiddenHorse(state.riddenHorseId);
    game.setRiddenDragon(state.riddenDragonId);
    for (final animal in game.animals.toList()) {
      if (!state.animals.containsKey(animal.id)) game.removeAnimal(animal.id);
    }
    for (final horse in game.horses.toList()) {
      if (!state.horses.containsKey(horse.id)) game.removeHorse(horse.id);
    }
    for (final dragon in game.dragons.toList()) {
      if (!state.dragons.containsKey(dragon.id)) game.removeDragon(dragon.id);
    }
    refresh(() {});
  }

  Future<void> _confirmRemoval(
    BuildContext panelContext,
    String name,
    VoidCallback remove,
  ) async {
    final confirmed = await showDialog<bool>(
      context: panelContext,
      builder: (context) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text(
          'This creature will leave your farm. Coins and equipment are not refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep animal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted && panelContext.mounted) remove();
  }

  Future<void> _showCreatures() async {
    String? selected;
    var kind = '';
    await _showPanel(
      (context, refresh) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your animals',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          for (final animal in state.animals.values)
            ListTile(
              title: Text(animal.name),
              subtitle: Text(animal.kind.name),
              onTap: () {
                selected = animal.id;
                kind = 'animal';
                Navigator.pop(context);
              },
            ),
          for (final horse in state.horses.values)
            ListTile(
              title: Text(horse.name),
              subtitle: Text('${horse.breed.name} horse'),
              onTap: () {
                selected = horse.id;
                kind = 'horse';
                Navigator.pop(context);
              },
            ),
          for (final dragon in state.dragons.values)
            ListTile(
              title: Text(dragon.name),
              subtitle: Text(
                '${dragon.elements.map((e) => e.name).join(' + ')} dragon',
              ),
              onTap: () {
                selected = dragon.id;
                kind = 'dragon';
                Navigator.pop(context);
              },
            ),
          if (state.animals.isEmpty &&
              state.horses.isEmpty &&
              state.dragons.isEmpty)
            const Text('Your farm is empty. Visit the market to add animals.'),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    if (kind == 'animal') {
      for (final animal in game.animals) {
        if (animal.id == selected) {
          _showAnimal(animal);
          return;
        }
      }
    } else if (kind == 'horse') {
      for (final horse in game.horses) {
        if (horse.id == selected) {
          _showHorse(horse);
          return;
        }
      }
    } else {
      for (final dragon in game.dragons) {
        if (dragon.id == selected) {
          showDragonPanel(dragon);
          return;
        }
      }
    }
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
    var food = FoodType.pellets;
    _showPanel((context, refresh) {
      final animal = state.animals[component.id];
      if (animal == null) return const SizedBox.shrink();
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
          Text('Favorite food: ${animal.kind.favoriteFood.name}'),
          DropdownButton<FoodType>(
            value: food,
            items: FoodType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      '${_title(type.name)} (${state.inventory.count(type)} left)',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => refresh(() => food = value!),
          ),
          FilledButton.icon(
            onPressed: state.inventory.count(food) <= 0
                ? null
                : () {
                    _change(feedAnimal(state, animal.id, food: food), refresh);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.restaurant),
            label: Text('Feed (${state.inventory.count(food)} left)'),
          ),
          FilledButton.icon(
            onPressed: () => _change(petAnimal(state, animal.id), refresh),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet (+10 coins)'),
          ),
          const Text('Enclosure toys'),
          Wrap(
            spacing: 8,
            children: [
              for (final toy in AnimalToy.values)
                OutlinedButton(
                  onPressed: () => _change(
                    playWithAnimal(state, animal.id, toy: toy),
                    refresh,
                  ),
                  child: Text('Play with ${toy.name}'),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: () => _confirmRemoval(context, animal.name, () {
              _change(removeAnimal(state, animal.id), refresh);
              Navigator.pop(context);
            }),
            icon: const Icon(Icons.pets),
            label: const Text('Remove animal'),
          ),
        ],
      );
    });
  }

  void _showHorse(HorseComponent component) {
    String? partnerId;
    String? breedingMessage;
    _showPanel((context, refresh) {
      final horse = state.horses[component.id];
      if (horse == null) return const SizedBox.shrink();
      final riding = state.riddenHorseId == horse.id;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            horse.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('${_title(horse.variant.name)} horse • ${state.coins} coins'),
          Text(
            '${_title(horse.breed.name)} breed • ${_title(horse.style.name)} style',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _change(petHorse(state, horse.id), refresh),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet (+10 coins)'),
          ),
          FilledButton.icon(
            onPressed:
                !horse.hasSaddle ||
                    (!riding &&
                        (state.riddenHorseId != null ||
                            state.riddenDragonId != null))
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
          const SizedBox(height: 16),
          Text(
            'Horse styles • ${state.unlockedHorseStyles.length}/${HorseStyle.values.length} unlocked',
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final style in HorseStyle.values)
                ChoiceChip(
                  label: Text(
                    '${_title(style.name)}${state.unlockedHorseStyles.contains(style) ? '' : ' 🔒'}',
                  ),
                  selected: horse.style == style,
                  onSelected: !state.unlockedHorseStyles.contains(style)
                      ? null
                      : (_) => _change(
                          equipHorseStyle(state, horse.id, style),
                          refresh,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Breed horses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Choose two different horses. Each foal unlocks the next style:\nSpotted → Golden → Midnight → Rainbow → Celestial.',
          ),
          if (state.horses.length < 2)
            const Text('Buy a second horse at the farm market first.'),
          DropdownButton<String>(
            key: const ValueKey('breeding-partner'),
            value: partnerId,
            hint: const Text('Choose another horse'),
            isExpanded: true,
            items: state.horses.values
                .where((h) => h.id != horse.id)
                .map((h) => DropdownMenuItem(value: h.id, child: Text(h.name)))
                .toList(),
            onChanged: (id) => refresh(() => partnerId = id),
          ),
          FilledButton.icon(
            onPressed:
                partnerId == null ||
                    state.coins < 40 ||
                    riding ||
                    state.riddenHorseId == partnerId
                ? null
                : () {
                    final next = breedHorses(
                      state,
                      horse.id,
                      partnerId!,
                      seed: state.breedCount + 1,
                    );
                    if (identical(next, state)) return;
                    final foal = next.horses.values.firstWhere(
                      (h) => !state.horses.containsKey(h.id),
                    );
                    breedingMessage =
                        '${foal.name} born! ${_title(foal.style.name)} style${next.unlockedHorseStyles.length > state.unlockedHorseStyles.length ? ' unlocked for all your horses' : ''}.';
                    _change(next, refresh);
                  },
            icon: const Icon(Icons.favorite),
            label: const Text('Breed a foal (40 coins)'),
          ),
          if (breedingMessage != null)
            Text(breedingMessage!, textAlign: TextAlign.center),
          if (horse.parentIds.isNotEmpty)
            Text(
              'Parents: ${horse.parentIds.map((id) => state.horses[id]?.name ?? id).join(' & ')}',
            ),
          TextButton.icon(
            onPressed: () => _confirmRemoval(context, horse.name, () {
              _change(removeHorse(state, horse.id), refresh);
              Navigator.pop(context);
            }),
            icon: const Icon(Icons.pets),
            label: const Text('Remove horse'),
          ),
        ],
      );
    });
  }

  void _showMarket() {
    var kind = 'horse';
    var variantIndex = 0;
    var breed = HorseBreed.farm;
    _showPanel((context, refresh) {
      final animalKind = kind == 'horse'
          ? null
          : AnimalKind.values.byName(kind);
      final price =
          animalKind?.price ?? (breed == HorseBreed.friesian ? 120 : 50);
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
          if (animalKind == null) ...[
            DropdownButtonFormField<HorseBreed>(
              initialValue: breed,
              key: const ValueKey('horse-breed'),
              decoration: const InputDecoration(labelText: 'Horse breed'),
              items: HorseBreed.values
                  .map(
                    (b) =>
                        DropdownMenuItem(value: b, child: Text(_title(b.name))),
                  )
                  .toList(),
              onChanged: (value) => refresh(() {
                breed = value!;
                if (breed == HorseBreed.friesian) {
                  variantIndex = HorseVariant.black.index;
                }
              }),
            ),
            if (breed == HorseBreed.friesian)
              const Text(
                'Friesian • black coat, flowing mane and feathered hooves',
              ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            key: ValueKey(
              'variant-${kind == 'horse' && breed == HorseBreed.friesian ? 'friesian' : kind}',
            ),
            initialValue: variantIndex,
            decoration: const InputDecoration(labelText: 'Coat variant'),
            items: List.generate(
              variants.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(_title(variants[index])),
              ),
            ),
            onChanged: animalKind == null && breed == HorseBreed.friesian
                ? null
                : (value) => refresh(() => variantIndex = value!),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.coins < price
                ? null
                : () {
                    if (animalKind == null) {
                      final horse = Horse(
                        id: nextHorseId(state),
                        name:
                            '${_title(variants[variantIndex])} horse ${nextHorseId(state).split('-').last}',
                        variant: HorseVariant.values[variantIndex],
                        breed: breed,
                      );
                      final next = buyHorse(state, horse);
                      if (identical(next, state)) return;
                      game.addHorse(horse);
                      _change(next, refresh);
                    } else {
                      final animal = Animal(
                        id: nextAnimalId(state),
                        name:
                            '${_title(variants[variantIndex])} $kind ${nextAnimalId(state).split('-').last}',
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
            '${state.animals.length + state.horses.length + state.dragons.length} animals on your farm',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Food supplies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final food in FoodType.values)
            OutlinedButton(
              onPressed: state.coins < food.price
                  ? null
                  : () => _change(buyFood(state, food), refresh),
              child: Text(
                'Buy ${food.name} (${food.price} coins) • ${state.inventory.count(food)} left',
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Creatures & farm treasures',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Pet your animals to earn coins. Purchases appear on your farm.',
          ),
          for (final item in FarmItem.values)
            OutlinedButton(
              onPressed:
                  state.ownedPurchases.contains(item) ||
                      state.coins < item.price
                  ? null
                  : () => _change(buyFarmItem(state, item), refresh),
              child: Text(
                '${_title(item.name)} • ${state.ownedPurchases.contains(item) ? 'Owned' : '${item.price} coins'}',
              ),
            ),
          const SizedBox(height: 16),
          dragonMarket(refresh),
        ],
      );
    });
  }

  void _dismount() {
    setState(() => state = dismountDragon(dismountHorse(state)));
    game.setRiddenHorse(null);
    game.setRiddenDragon(null);
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
        Material(
          color: const Color(0xffffe7b8),
          child: InkWell(
            onTap: _refreshWeather,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  _weatherStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
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
                      if (state.riddenHorseId != null ||
                          state.riddenDragonId != null)
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _showCreatures,
                icon: const Icon(Icons.pets),
                label: const Text('Your animals'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  state.riddenHorseId == null && state.riddenDragonId == null
                      ? 'Tap animals to care for them • Fit a saddle to ride\nMove with WASD, arrows, or hold the buttons'
                      : 'Riding • Move with WASD, arrows, or hold the buttons',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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

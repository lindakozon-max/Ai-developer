part of 'main.dart';

String _dragonElements(Dragon dragon) => DragonElement.values
    .where(dragon.elements.contains)
    .map((element) => _title(element.name))
    .join(' + ');

extension _DragonPanels on _FarmScreenState {
  void showDragonPanel(DragonComponent component) {
    String? partnerId;
    String? breedingMessage;
    _showPanel((context, refresh) {
      final dragon = state.dragons[component.id];
      if (dragon == null) return const SizedBox.shrink();
      final riding = state.riddenDragonId == dragon.id;
      final anotherMount =
          state.riddenHorseId != null ||
          (state.riddenDragonId != null && !riding);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dragon.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_dragonElements(dragon)} ${dragon.isHybrid ? 'hybrid' : 'dragon'} • ${state.coins} coins',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _change(petDragon(state, dragon.id), refresh),
            icon: const Icon(Icons.favorite),
            label: const Text('Pet dragon (+10 coins)'),
          ),
          FilledButton.icon(
            onPressed: !dragon.hasSaddle || anotherMount
                ? null
                : () {
                    _change(
                      riding
                          ? dismountDragon(state)
                          : mountDragon(state, dragon.id),
                      refresh,
                    );
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.flight),
            label: Text(riding ? 'Dismount dragon' : 'Ride dragon'),
          ),
          if (!dragon.hasSaddle)
            const Text('Fit a saddle below to ride your dragon.'),
          if (anotherMount)
            const Text(
              'Dismount your current animal before riding this dragon.',
            ),
          const SizedBox(height: 12),
          const Text(
            'Dragon saddles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final saddle in SaddleType.values)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed:
                    dragon.saddle == saddle ||
                        (!dragon.ownedSaddles.contains(saddle) &&
                            state.coins < saddle.price)
                    ? null
                    : () => _change(
                        dragon.ownedSaddles.contains(saddle)
                            ? equipDragonSaddle(state, dragon.id, saddle)
                            : buyDragonSaddle(state, dragon.id, saddle: saddle),
                        refresh,
                      ),
                icon: Icon(
                  dragon.saddle == saddle ? Icons.check : Icons.event_seat,
                ),
                label: Text(
                  '${_title(saddle.name)} dragon saddle • ${dragon.saddle == saddle
                      ? 'Fitted'
                      : dragon.ownedSaddles.contains(saddle)
                      ? 'Equip'
                      : '${saddle.price} coins'}',
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Breed dragons',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Each hatchling inherits an element from each parent. Breed two different pure elements to hatch a hybrid.',
          ),
          if (state.dragons.length < 2)
            const Text('Buy a second dragon at the farm market first.'),
          DropdownButton<String>(
            key: const ValueKey('dragon-partner'),
            value: partnerId,
            hint: const Text('Choose another dragon'),
            isExpanded: true,
            items: state.dragons.values
                .where((other) => other.id != dragon.id)
                .map(
                  (other) => DropdownMenuItem(
                    value: other.id,
                    child: Text('${other.name} • ${_dragonElements(other)}'),
                  ),
                )
                .toList(),
            onChanged: (id) => refresh(() => partnerId = id),
          ),
          FilledButton.icon(
            onPressed:
                partnerId == null ||
                    state.coins < 80 ||
                    riding ||
                    state.riddenDragonId == partnerId
                ? null
                : () {
                    final next = breedDragons(
                      state,
                      dragon.id,
                      partnerId!,
                      seed: state.dragonBreedCount + 1,
                    );
                    if (identical(next, state)) return;
                    final hatchling = next.dragons.values.firstWhere(
                      (child) => !state.dragons.containsKey(child.id),
                    );
                    breedingMessage =
                        '${hatchling.name} hatched! ${_dragonElements(hatchling)} ${hatchling.isHybrid ? 'hybrid' : 'dragon'}.';
                    _change(next, refresh);
                  },
            icon: const Icon(Icons.egg),
            label: const Text('Breed a dragon (80 coins)'),
          ),
          if (breedingMessage != null)
            Text(breedingMessage!, textAlign: TextAlign.center),
          if (dragon.parentIds.isNotEmpty)
            Text(
              'Parents: ${dragon.parentIds.map((id) => state.dragons[id]?.name ?? id).join(' & ')}',
            ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _confirmRemoval(context, dragon.name, () {
              _change(removeDragon(state, dragon.id), refresh);
              Navigator.pop(context);
            }),
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Remove dragon'),
          ),
        ],
      );
    });
  }

  Widget dragonMarket(StateSetter refresh) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      const Text(
        'Dragons & hybrids',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Dragons live in the dragon roost. Tap one to pet, saddle, ride or breed it. Pair different elements to hatch hybrids.',
      ),
      for (final element in DragonElement.values)
        OutlinedButton(
          onPressed: state.coins < 250
              ? null
              : () {
                  final id = nextDragonId(state);
                  final dragon = Dragon(
                    id: id,
                    name:
                        '${_title(element.name)} dragon ${id.split('-').last}',
                    elements: {element},
                  );
                  _change(buyDragon(state, dragon), refresh);
                },
          child: Text('Buy ${element.name} dragon (250 coins)'),
        ),
      Text(
        '${state.dragons.length} dragons in your roost',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

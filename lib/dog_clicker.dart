import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class DogBreed {
  const DogBreed({
    required this.name,
    required this.emoji,
    required this.price,
    required this.clickPower,
    required this.autoPower,
    required this.tagline,
    required this.color,
  });

  final String name;
  final String emoji;
  final BigInt price;
  final BigInt clickPower;
  final BigInt autoPower;
  final String tagline;
  final Color color;
}

final dogBreeds = [
  DogBreed(
    name: 'Papillon',
    emoji: '🐶',
    price: BigInt.from(0),
    clickPower: BigInt.from(1),
    autoPower: BigInt.from(0),
    tagline: 'Your first loyal coin collector',
    color: Color(0xffffdced),
  ),
  DogBreed(
    name: 'Corgi',
    emoji: '🐕',
    price: BigInt.from(100),
    clickPower: BigInt.from(2),
    autoPower: BigInt.from(1),
    tagline: 'Short legs, huge hustle',
    color: Color(0xffffe0b2),
  ),
  DogBreed(
    name: 'Husky',
    emoji: '🐺',
    price: BigInt.from(10000),
    clickPower: BigInt.from(20),
    autoPower: BigInt.from(10),
    tagline: 'Howls coins into existence',
    color: Color(0xffd7ecff),
  ),
  DogBreed(
    name: 'Golden Retriever',
    emoji: '🦮',
    price: BigInt.from(1000000),
    clickPower: BigInt.from(250),
    autoPower: BigInt.from(125),
    tagline: 'Always brings back a bonus',
    color: Color(0xfffff0b3),
  ),
  DogBreed(
    name: 'Poodle',
    emoji: '🐩',
    price: BigInt.from(10000000),
    clickPower: BigInt.from(500),
    autoPower: BigInt.from(250),
    tagline: 'Fancy fur, fancy fortune',
    color: Color(0xffeadcff),
  ),
  DogBreed(
    name: 'Dalmatian',
    emoji: '🐕',
    price: BigInt.from(100000000),
    clickPower: BigInt.from(1000),
    autoPower: BigInt.from(500),
    tagline: 'Spotted with lucky coins',
    color: Color(0xffe4f4f0),
  ),
  DogBreed(
    name: 'Cosmic Shiba',
    emoji: '🚀',
    price: BigInt.from(10000000000),
    clickPower: BigInt.from(2500),
    autoPower: BigInt.from(1250),
    tagline: 'The goodest dog in the galaxy',
    color: Color(0xffd9d4ff),
  ),
  DogBreed(
    name: 'Infinity Wolf',
    emoji: '🐲',
    price: BigInt.from(1000000000000),
    clickPower: BigInt.from(10000),
    autoPower: BigInt.from(5000),
    tagline: 'Built for the endgame',
    color: Color(0xffc8f1ec),
  ),
];

class DogClickerScreen extends StatefulWidget {
  const DogClickerScreen({super.key});

  @override
  State<DogClickerScreen> createState() => _DogClickerScreenState();
}

class _DogClickerScreenState extends State<DogClickerScreen> {
  BigInt _coins = BigInt.zero;
  BigInt _clickUpgrade = BigInt.zero;
  BigInt _autoUpgrade = BigInt.zero;
  BigInt _treatUpgrade = BigInt.zero;
  BigInt _kennelUpgrade = BigInt.zero;
  var _selectedBreed = 0;
  final Set<int> _ownedBreeds = {0};
  final Random _random = Random();
  Timer? _timer;
  var _eventCountdown = 10;
  var _eventMessage = 'A surprise can happen at any moment!';

  DogBreed get _breed => dogBreeds[_selectedBreed];
  BigInt get _clickPower => _scaledPower(
    _scaledPower(_breed.clickPower, _clickUpgrade),
    _treatUpgrade,
  );
  BigInt get _autoPower => _scaledPower(
    _scaledPower(_breed.autoPower, _autoUpgrade),
    _kennelUpgrade,
  );
  BigInt get _clickUpgradeCost => _risingCost(50, _clickUpgrade, 6);
  BigInt get _autoUpgradeCost => _risingCost(100, _autoUpgrade, 7);
  BigInt get _treatUpgradeCost => _risingCost(250, _treatUpgrade, 8);
  BigInt get _kennelUpgradeCost => _risingCost(500, _kennelUpgrade, 9);

  BigInt _risingCost(int base, BigInt level, int growth) =>
      BigInt.from(base) * BigInt.from(growth).pow(level.toInt());

  BigInt _scaledPower(BigInt base, BigInt level) =>
      base * BigInt.from(2).pow(level.toInt());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _coins += _autoPower;
        _eventCountdown--;
        if (_eventCountdown <= 0) {
          _coins += _randomEventReward();
          _eventCountdown = 10 + _random.nextInt(11);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clickDog() {
    final lucky = _random.nextInt(25) == 0;
    setState(() {
      _coins += lucky ? _clickPower * BigInt.from(5) : _clickPower;
      if (lucky) _eventMessage = 'Lucky paw! That click paid 5× coins!';
    });
  }

  BigInt _randomEventReward() {
    final reward = switch (_random.nextInt(4)) {
      0 => _clickPower * BigInt.from(8),
      1 => _autoPower * BigInt.from(20) + _clickPower * BigInt.from(3),
      2 => (_clickPower + _autoPower) * BigInt.from(5),
      _ => _clickPower * BigInt.from(12) + BigInt.from(10),
    };
    final messages = [
      'Picnic time! Your dog found ${_number(reward)} bonus coins.',
      'A treasure box appeared! You got ${_number(reward)} coins.',
      'A friendly dog joined the walk and brought ${_number(reward)} coins.',
      'Zoomies bonus! Your dog earned ${_number(reward)} coins.',
    ];
    _eventMessage = messages[_random.nextInt(messages.length)];
    return reward;
  }

  void _buyBreed(int index) {
    final breed = dogBreeds[index];
    if (_ownedBreeds.contains(index) || _coins < breed.price) return;
    setState(() {
      _coins -= breed.price;
      _ownedBreeds.add(index);
      _selectedBreed = index;
    });
  }

  void _buyUpgrade({required String type}) {
    final cost = switch (type) {
      'click' => _clickUpgradeCost,
      'auto' => _autoUpgradeCost,
      'treat' => _treatUpgradeCost,
      _ => _kennelUpgradeCost,
    };
    if (_coins < cost) return;
    setState(() {
      _coins -= cost;
      switch (type) {
        case 'click':
          _clickUpgrade += BigInt.one;
        case 'auto':
          _autoUpgrade += BigInt.one;
        case 'treat':
          _treatUpgrade += BigInt.one;
        default:
          _kennelUpgrade += BigInt.one;
      }
    });
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart your coin journey?'),
        content: const Text('All coins, breeds, and upgrades will be reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _coins = BigInt.zero;
      _clickUpgrade = BigInt.zero;
      _autoUpgrade = BigInt.zero;
      _treatUpgrade = BigInt.zero;
      _kennelUpgrade = BigInt.zero;
      _selectedBreed = 0;
      _eventCountdown = 10;
      _eventMessage = 'A surprise can happen at any moment!';
      _ownedBreeds
        ..clear()
        ..add(0);
    });
  }

  String _number(BigInt value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4df),
    appBar: AppBar(
      title: const Text('Papillon Coin Club'),
      centerTitle: true,
      backgroundColor: const Color(0xffffd27d),
      actions: [
        IconButton(
          onPressed: _restart,
          tooltip: 'Restart game',
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '🪙 ${_number(_coins)} coins',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_number(_clickPower)} per click  •  ${_number(_autoPower)} per second',
              style: const TextStyle(color: Color(0xff76506a)),
            ),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xfffff0b3),
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xffd48a00),
                ),
                title: const Text('Random surprise'),
                subtitle: Text(_eventMessage),
                trailing: Text('$_eventCountdown s'),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _clickDog,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [_breed.color, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 36,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _breed.emoji,
                          style: const TextStyle(fontSize: 110),
                        ),
                        Text(
                          'Tap the ${_breed.name}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_breed.tagline),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Upgrades'),
            _upgradeButton(
              'Stronger paws',
              'Double coins per click',
              _clickUpgradeCost,
              _clickUpgrade,
              () => _buyUpgrade(type: 'click'),
            ),
            _upgradeButton(
              'Coin sniffer',
              'Double coins per second',
              _autoUpgradeCost,
              _autoUpgrade,
              () => _buyUpgrade(type: 'auto'),
            ),
            _upgradeButton(
              'Golden treats',
              'Triple coins per click',
              _treatUpgradeCost,
              _treatUpgrade,
              () => _buyUpgrade(type: 'treat'),
            ),
            _upgradeButton(
              'Luxury kennel',
              'Triple coins per second',
              _kennelUpgradeCost,
              _kennelUpgrade,
              () => _buyUpgrade(type: 'kennel'),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Dog breeds'),
            for (var index = 0; index < dogBreeds.length; index++)
              _breedTile(index),
          ],
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: Color(0xff76506a),
        ),
      ),
    ),
  );

  Widget _upgradeButton(
    String title,
    String detail,
    BigInt cost,
    BigInt level,
    VoidCallback onPressed,
  ) => Card(
    child: ListTile(
      leading: const Icon(Icons.upgrade, color: Color(0xffe8927e)),
      title: Text('$title  •  Lv. ${_number(level)}'),
      subtitle: Text('$detail\nCost: ${_number(cost)} coins'),
      isThreeLine: true,
      trailing: FilledButton(
        onPressed: _coins >= cost ? onPressed : null,
        child: const Text('Buy'),
      ),
    ),
  );

  Widget _breedTile(int index) {
    final breed = dogBreeds[index];
    final owned = _ownedBreeds.contains(index);
    return Card(
      child: ListTile(
        leading: Text(breed.emoji, style: const TextStyle(fontSize: 32)),
        title: Text(breed.name),
        subtitle: Text(
          owned
              ? '${_number(breed.clickPower)} click • ${_number(breed.autoPower)}/sec'
              : 'Unlock for ${_number(breed.price)} coins',
        ),
        trailing: owned
            ? OutlinedButton(
                onPressed: () => setState(() => _selectedBreed = index),
                child: Text(_selectedBreed == index ? 'Using' : 'Use'),
              )
            : FilledButton(
                onPressed: _coins >= breed.price
                    ? () => _buyBreed(index)
                    : null,
                child: const Text('Unlock'),
              ),
      ),
    );
  }
}

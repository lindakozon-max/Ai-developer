import 'dart:async';

import 'package:flutter/material.dart';

class DogBreed {
  const DogBreed({
    required this.name,
    required this.emoji,
    required this.price,
    required this.clickPower,
    required this.autoPower,
    required this.tagline,
  });

  final String name;
  final String emoji;
  final BigInt price;
  final BigInt clickPower;
  final BigInt autoPower;
  final String tagline;
}

final dogBreeds = [
  DogBreed(
    name: 'Papillon',
    emoji: '🐶',
    price: BigInt.from(0),
    clickPower: BigInt.from(1),
    autoPower: BigInt.from(0),
    tagline: 'Your first loyal coin collector',
  ),
  DogBreed(
    name: 'Corgi',
    emoji: '🐕',
    price: BigInt.from(100),
    clickPower: BigInt.from(2),
    autoPower: BigInt.from(1),
    tagline: 'Short legs, huge hustle',
  ),
  DogBreed(
    name: 'Husky',
    emoji: '🐺',
    price: BigInt.from(10000),
    clickPower: BigInt.from(20),
    autoPower: BigInt.from(10),
    tagline: 'Howls coins into existence',
  ),
  DogBreed(
    name: 'Golden Retriever',
    emoji: '🦮',
    price: BigInt.from(1000000),
    clickPower: BigInt.from(250),
    autoPower: BigInt.from(125),
    tagline: 'Always brings back a bonus',
  ),
  DogBreed(
    name: 'Cosmic Shiba',
    emoji: '🚀',
    price: BigInt.from(1000000000),
    clickPower: BigInt.from(1000),
    autoPower: BigInt.from(500),
    tagline: 'The goodest dog in the galaxy',
  ),
  DogBreed(
    name: 'Infinity Wolf',
    emoji: '🐲',
    price: BigInt.from(1000000000000),
    clickPower: BigInt.from(10000),
    autoPower: BigInt.from(5000),
    tagline: 'Built for the endgame',
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
  var _selectedBreed = 0;
  final Set<int> _ownedBreeds = {0};
  Timer? _timer;

  DogBreed get _breed => dogBreeds[_selectedBreed];
  BigInt get _clickPower => _scaledPower(_breed.clickPower, _clickUpgrade);
  BigInt get _autoPower => _scaledPower(_breed.autoPower, _autoUpgrade);
  BigInt get _clickUpgradeCost =>
      BigInt.from(25) *
      (_clickUpgrade + BigInt.one) *
      (_clickUpgrade + BigInt.one);
  BigInt get _autoUpgradeCost =>
      BigInt.from(50) *
      (_autoUpgrade + BigInt.one) *
      (_autoUpgrade + BigInt.one);

  BigInt _scaledPower(BigInt base, BigInt level) =>
      base * BigInt.from(2).pow(level.toInt());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _autoPower == BigInt.zero) return;
      setState(() => _coins += _autoPower);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clickDog() => setState(() => _coins += _clickPower);

  void _buyBreed(int index) {
    final breed = dogBreeds[index];
    if (_ownedBreeds.contains(index) || _coins < breed.price) return;
    setState(() {
      _coins -= breed.price;
      _ownedBreeds.add(index);
      _selectedBreed = index;
    });
  }

  void _buyUpgrade({required bool click}) {
    final cost = click ? _clickUpgradeCost : _autoUpgradeCost;
    if (_coins < cost) return;
    setState(() {
      _coins -= cost;
      if (click) {
        _clickUpgrade += BigInt.one;
      } else {
        _autoUpgrade += BigInt.one;
      }
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
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _clickDog,
              child: Card(
                color: const Color(0xffffdced),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 36,
                  ),
                  child: Column(
                    children: [
                      Text(_breed.emoji, style: const TextStyle(fontSize: 110)),
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
            const SizedBox(height: 18),
            _sectionTitle('Upgrades'),
            _upgradeButton(
              'Stronger paws',
              'Double coins per click',
              _clickUpgradeCost,
              _clickUpgrade,
              () => _buyUpgrade(click: true),
            ),
            _upgradeButton(
              'Coin sniffer',
              'Double coins per second',
              _autoUpgradeCost,
              _autoUpgrade,
              () => _buyUpgrade(click: false),
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

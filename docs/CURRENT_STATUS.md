# Current status

## Works

- Flutter menu opens a portrait-friendly Flame farm scene.
- A pastel map starts with a horse, sheep (Biscuit), goat, cow, chicken, and donkey.
- Each kind has five visible coat variants, available through the farm market.
- Animals wander, rest, blink, and animate their legs, tails, or wings.
- Feeding consumes food and improves needs; petting earns coins for purchases.
- Horses support classic, western, racing, royal, and trail saddles, each with a distinct appearance and price. Owned saddles can be equipped again for free.
- Fit a saddle, then tap Ride horse. WASD, arrow keys, and held touch buttons move the rider and horse together at a faster pace. Dismount returns to walking.
- Interaction panels show current coins, equipment, and purchase availability immediately.

## Tested

- Domain tests cover all animal variants, purchases, needs, saddle ownership, equipment switching, and riding guards.
- Widget tests cover feeding, market variant selection, live balances, saddle purchases, keyboard and held touch riding, dismounting, animation, and resize bounds.

## Intentionally missing

- External art assets (animals use animated Canvas drawings), saves, breeding/genetics, audio, Supabase, and multiplayer.

## Next milestone

- Add a versioned local save repository so animals, coins, and equipment survive reopening the farm.

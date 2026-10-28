enum FarmItem {
  dragon,
  fountain,
  windmill,
  flowerBed,
  appleTree,
  lanterns,
  picnicTable,
  hayCart,
  duckPond,
  butterflyGarden,
}

extension FarmItemDetails on FarmItem {
  int get price => switch (this) {
    FarmItem.dragon => 250,
    FarmItem.fountain => 80,
    FarmItem.windmill => 100,
    FarmItem.flowerBed => 20,
    FarmItem.appleTree => 35,
    FarmItem.lanterns => 25,
    FarmItem.picnicTable => 40,
    FarmItem.hayCart => 30,
    FarmItem.duckPond => 90,
    FarmItem.butterflyGarden => 45,
  };
}

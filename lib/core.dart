const String stone = 'ore.stone';
const String iron = 'ore.iron';
const String wood = 'wood';
const String dirt = 'dirt';
const String robot = 'crafted.robot';
const String miner = 'crafted.miner';
const String box = 'crafted.box';
const String planter = 'crafted.planter';
const String chopper = 'crafted.chopper';
const String antenna = 'crafted.antenna';

enum EntityType {
  table,
  collectibleWood,
  dirt,
  robot,
  miner,
  box,
  sapling,
  tree,
  player,
  planter,
  chopper,
  antenna,
}

class ItemStack {
  int count;
  String? item;

  @override
  String toString() => '${count}x$item';

  ItemStack(this.count, this.item);
  factory ItemStack.parse(String input) {
    List<String> parts = input.split('x');
    return ItemStack(int.parse(parts[0]), parts[1]);
  }

  ItemStack copy() {
    return ItemStack(count, item);
  }
}

Map<String, int> stackSizes = {
  miner: 50,
  robot: 50,
  box: 50,
  wood: 100,
  stone: 50,
  iron: 50,
  dirt: 100,
};

int stackSizeOf(String item) {
  return stackSizes[item] ?? 404;
}

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:some_app/core.dart';
import 'package:some_app/logic.dart';

void main() {
  testWidgets('Player can move', (WidgetTester tester) async {
    World world = World(MockRandom(), false, easterMode: false);
    world.screenWidth = 10;
    world.screenHeight = 10;
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    expect(p.dx, 0);
    expect(p.dy, 0);
    expect(p.room.x, 0);
    expect(p.room.y, 0);
    world.tick(() {});
    expect(p.dx, 6); // 10 - 4
    expect(p.dy, 6);
    expect(p.room.x, -1);
    expect(p.room.y, -1);
    world.tick(() {});
    expect(p.dx, 6);
    expect(p.dy, 6);
    world.left(p);
    world.tick(() {});
    expect(p.dx, 5);
    expect(p.dy, 6);
    world.tick(() {});
    expect(p.dx, 4);
    expect(p.dy, 6);
    world.right(p);
    world.tick(() {});
    expect(p.dx, 4);
    expect(p.dy, 6);
    world.right(p);
    world.tick(() {});
    expect(p.dx, 5);
    expect(p.dy, 6);
    world.tick(() {});
    world.tick(() {});
    expect(p.dx, 1);
    expect(p.dy, 6);
    expect(p.room.x, 0);
    expect(p.room.y, -1);
    world.left(p);
    world.down(p);
    world.tick(() {});
    expect(p.dx, 1);
    expect(p.dy, 1);
    expect(p.room.x, 0);
    expect(p.room.y, 0);
    world.tick(() {});
    expect(p.dx, 1);
    expect(p.dy, 2);
    world.up(p);
    world.tick(() {});
    expect(p.dx, 1);
    expect(p.dy, 2);
    world.up(p);
    world.tick(() {});
    world.tick(() {});
    expect(p.dx, 1);
    expect(p.dy, 6);
    expect(p.room.x, 0);
    expect(p.room.y, -1);
  });
  testWidgets('Wood collection/placement', (widgetTester) async {
    World world = World(MockRandom(), false, easterMode: false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    expect(p.hasItem(wood, 1), false);
    world.tick(() {});
    expect(p.hasItem(wood, 1), false);
    expect(world.entities[IntegerOffset(-1, -1)], hasLength(2));
    expect(world.entities[IntegerOffset(-1, -1)]!.whereType<CollectibleWood>(),
        hasLength(1));
    expect(world.entities[IntegerOffset(-1, -1)]!.whereType<Player>(),
        hasLength(1));
    CollectibleWood woody = world.entities[IntegerOffset(-1, -1)]!
        .whereType<CollectibleWood>()
        .single;
    expect(woody.dx, 1);
    expect(woody.dy, 1);
    world.left(p);
    world.up(p);
    world.tick(() {});
    world.tick(() {});
    world.right(p);
    world.down(p);
    expect(p.dx, 4);
    expect(p.dy, 4);
    expect(p.hasItem(wood, 1), true);
    expect(p.interacting, isNull);
    expect(world.entities.values.expand((element) => element),
        everyElement(isNot(isA<Table>())));
    world.interact(p);
    expect(p.interacting, isNull);
    expect(world.place(p, wood), true);
    expect(
        world.entities.values.expand((element) => element).whereType<Table>(),
        hasLength(1));
    expect(world.entities[IntegerOffset(-1, -1)]!.whereType<Table>(),
        hasLength(1));
    Table table =
        world.entities[IntegerOffset(-1, -1)]!.whereType<Table>().single;
    expect(table.dx, 4);
    expect(table.dy, 4);
    expect(p.interacting, isNull);
    world.interact(p);
    expect(p.interacting, isNotNull);
  });
  testWidgets('Mining iron', (WidgetTester tester) async {
    World world = World(MockRandom(), false, easterMode: false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick(() {});
    expect(p.hasItem(iron, 1), false);
    bool mined = false;
    world.mine(p, () {
      mined = true;
    });
    await tester.pump(const Duration(seconds: 2));
    expect(mined, true);
    expect(p.hasItem(stone, 1), false);
    expect(p.hasItem(dirt, 1), false);
    expect(p.hasItem(iron, 1), true);
  });
  testWidgets('Robot collection/placement', (WidgetTester tester) async {
    World world = World(MockRandom(), false, easterMode: false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    expect(world.entities.entries.map((kv) => kv.value).expand((e) => e),
        everyElement(isNot(isA<Robot>())));
    expect(p.hasItem(robot, 1), false);
    world.tick(() {});
    world.left(p);
    world.up(p);
    world.tick(() {});
    world.tick(() {});
    world.right(p);
    world.down(p);
    expect(p.dx, 4);
    expect(p.dy, 4);
    expect(world.place(p, wood), true);
    world.interact(
      p,
    );
    world.mine(p, () {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(p, World.recipes[0]);
    expect(p.hasItem(robot, 1), true);
    world.place(p, robot);
    expect(p.hasItem(robot, 1), false);
    expect(
        world.entities.values.expand((element) => element).whereType<Robot>(),
        hasLength(1));
  });
  testWidgets(skip: true, 'Robot movement/gathering', (WidgetTester tester) async {
    World world = World(MockRandom(), false, easterMode: false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick(() {});
    world.left(p);
    world.up(p);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    world.right(p);
    world.down(p);
    expect(p.dx, 3);
    expect(p.dy, 3);
    expect(p.room.x, -1);
    expect(p.room.x, -1);
    world.place(p, wood);
    world.interact(p);
    world.mine(p, () {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(p, World.recipes[0]);
    expect(world.place(p, robot), isTrue);
    IntegerOffset robotRoom = world.entities.entries
        .expand((element) => element.value
            .whereType<Robot>()
            .map((e) => MapEntry(element.key, e)))
        .single
        .key;
    late Robot roombot;
    Robot update() => roombot = world.entities.values
        .expand<Entity>((element) => element)
        .whereType<Robot>()
        .single;
    update();
    expect(robotRoom.x, p.room.x);
    expect(robotRoom.y, p.room.y);
    expect(roombot.dx, p.dx);
    expect(roombot.dy, p.dy);
    expect(roombot.inv, 0);
    world.tick(() {});
    world.tick(() {});
    update();
    expect(roombot.dx, 3);
    expect(roombot.dy, 1);
    expect(roombot.inv, 0);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    update();
    expect(roombot.dx, 1);
    expect(roombot.dy, 6);
    expect(robotRoom.x, -1);
    expect(robotRoom.y, -2);
    expect(roombot.inv, 0);
    world.tick(() {});
    update();
    expect(roombot.dx, 1);
    expect(roombot.dy, 6);
    expect(roombot.inv, 0);
    world.tick(() {});
    update();
    expect(roombot.dx, 0);
    expect(roombot.dy, 6);
    expect(roombot.inv, 0);
    world.tick(() {});
    update();
    expect(roombot.dx, 6);
    expect(roombot.dy, 6);
    expect(roombot.inv, 0);
    world.tick(() {});
    update();
    expect(roombot.dx, 3);
    expect(roombot.dy, 3);
    expect(roombot.inv, 0);
  });
  testWidgets('Trees', (WidgetTester tester) async {
    World world = World(MockRandom(), false, easterMode: false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick(() {});
    world.left(p);
    world.up(p);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    expect(p.dx, 3);
    expect(p.dy, 3);
    expect(p.hasItem(wood, 1), true);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    expect(p.dx, 6);
    expect(p.dy, 6);
    expect(p.room.x, -2);
    expect(p.room.y, -2);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    expect(p.dx, 3);
    expect(p.dy, 3);
    expect(p.hasItem(wood, 2), true);
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    world.tick(() {});
    expect(p.hasItem(wood, 3), true);
    expect(p.hasItem(wood, 4), false);
    expect(world.plant(p), true);
    world.right(p);
    world.down(p);
    int i = 360;
    while (i > 0) {
      i--;
      expect(world.entities[IntegerOffset(-3, -3)]!.whereType<Sapling>(),
          hasLength(1));
      expect(world.entities[IntegerOffset(-3, -3)]!.whereType<Tree>(),
          hasLength(0));
      expect(world.chop(p), false);
      world.tick(() {});
    }
    expect(world.entities[IntegerOffset(-3, -3)]!.whereType<Sapling>(),
        hasLength(0));
    expect(
        world.entities[IntegerOffset(-3, -3)]!.whereType<Tree>(), hasLength(1));
    expect(world.chop(p), true);
    expect(p.hasItem(wood, 4), true);
    expect(p.hasItem(wood, 5), false);
  });
}

class MockRandom implements Random {
  @override
  bool nextBool() {
    return false;
  }

  @override
  double nextDouble() {
    return 0;
  }

  @override
  int nextInt(int max) {
    throw UnimplementedError();
  }
}

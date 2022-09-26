import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:some_app/core.dart';
import 'package:some_app/logic.dart';

void main() {
  testWidgets('Player can move', (WidgetTester tester) async {
    World world = World(MockRandom(), false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick();
    expect(p.dx, 4);
    expect(p.dy, 4);
    expect(p.room.x, -1);
    expect(p.room.y, -1);
    world.tick();
    expect(p.dx, 4);
    expect(p.dy, 4);
    world.left(p);
    world.tick();
    expect(p.dx, 3);
    expect(p.dy, 4);
    world.tick();
    expect(p.dx, 2);
    expect(p.dy, 4);
    world.right(p);
    world.tick();
    expect(p.dx, 2);
    expect(p.dy, 4);
    world.right(p);
    world.tick();
    expect(p.dx, 3);
    expect(p.dy, 4);
    world.tick();
    world.tick();
    expect(p.dx, 1);
    expect(p.dy, 4);
    expect(p.room.x, 0);
    expect(p.room.y, -1);
    world.left(p);
    world.down(p);
    world.tick();
    expect(p.dx, 1);
    expect(p.dy, 1);
    expect(p.room.x, 0);
    expect(p.room.y, 0);
    world.tick();
    expect(p.dx, 1);
    expect(p.dy, 2);
    world.up(p);
    world.tick();
    expect(p.dx, 1);
    expect(p.dy, 2);
    world.up(p);
    world.tick();
    world.tick();
    expect(p.dx, 1);
    expect(p.dy, 4);
    expect(p.room.x, 0);
    expect(p.room.y, -1);
  });
  testWidgets('Wood collection/placement', (widgetTester) async {
    World world = World(MockRandom(), false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    expect(p.hasItem(wood, 1), false);
    world.tick();
    world.left(p);
    world.up(p);
    world.tick();
    world.tick();
    world.right(p);
    world.down(p);
    expect(p.hasItem(wood, 1), true);
    expect(p.interacting, isNull);
    expect(world.entities, everyElement(isNot(isA<Table>())));
    world.interact(p);
    expect(p.interacting, isNull);
    expect(world.place(p, wood), true);
    expect(
        world.entities.values.expand((element) => element).whereType<Table>(),
        hasLength(1));
    expect(p.interacting, isNull);
    world.interact(p);
    expect(p.interacting, isNotNull);
  });
  testWidgets('Mining iron', (WidgetTester tester) async {
    World world = World(MockRandom(), false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick();
    expect(p.hasItem(iron, 1), false);
    bool mined = false;
    world.mine(p, () {
      mined = true;
    });
    await tester.pump(const Duration(seconds: 2));
    expect(mined, true);
    expect(p.hasItem(stone, 1), false);
    expect(p.hasItem(iron, 1), true);
  });
  testWidgets('Robot collection/placement', (WidgetTester tester) async {
    World world = World(MockRandom(), false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    expect(world.entities.entries.map((kv) => kv.value).expand((e) => e),
        everyElement(isNot(isA<Robot>())));
    expect(p.hasItem(robot, 1), false);
    world.tick();
    world.left(p);
    world.up(p);
    world.tick();
    world.tick();
    world.right(p);
    world.down(p);
    expect(world.place(p, wood), true);
    world.interact(
      p,
    );
    world.mine(p, () {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(p, world.recipes[0]);
    expect(p.hasItem(robot, 1), true);
    world.place(p, robot);
    expect(p.hasItem(robot, 1), false);
    expect(
        world.entities.values.expand((element) => element).whereType<Robot>(),
        hasLength(1));
  });
  testWidgets('Robot movement/gathering', (WidgetTester tester) async {
    World world = World(MockRandom(), false);
    Player p = world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyK,
      ),
    );
    world.tick();
    world.left(p);
    world.up(p);
    world.tick();
    world.tick();
    world.right(p);
    world.down(p);
    world.place(p, wood);
    world.interact(p);
    world.mine(p, () {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(p, world.recipes[0]);
    world.place(p, robot);
    IntegerOffset robotRoom = world.entities.entries
        .expand((element) => element.value
            .whereType<Robot>()
            .map((e) => MapEntry(element.key, e)))
        .single
        .key;
    Robot roombot = world.entities.values
        .expand<Entity>((element) => element)
        .whereType<Robot>()
        .single;
    expect(robotRoom.x, p.room.x);
    expect(robotRoom.y, p.room.y);
    expect(roombot.dx, p.dx);
    expect(roombot.dy, p.dy);
    expect(roombot.inv, 0);
  });
}

class MockRandom implements Random {
  @override
  bool nextBool() {
    return true;
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

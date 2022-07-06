import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:some_app/core.dart';
import 'package:some_app/logic.dart';

void main() {
  testWidgets('Player can move', (WidgetTester tester) async {
    World world = World(MockRandom());
    world.tick();
    expect(world.playerX, 4);
    expect(world.playerY, 4);
    expect(world.roomX, -1);
    expect(world.roomY, -1);
    world.tick();
    expect(world.playerX, 4);
    expect(world.playerY, 4);
    world.left();
    world.tick();
    expect(world.playerX, 3);
    expect(world.playerY, 4);
    world.tick();
    expect(world.playerX, 2);
    expect(world.playerY, 4);
    world.right();
    world.tick();
    expect(world.playerX, 2);
    expect(world.playerY, 4);
    world.right();
    world.tick();
    expect(world.playerX, 3);
    expect(world.playerY, 4);
    world.tick();
    world.tick();
    expect(world.playerX, 1);
    expect(world.playerY, 4);
    expect(world.roomX, 0);
    expect(world.roomY, -1);
    world.left();
    world.down();
    world.tick();
    expect(world.playerX, 1);
    expect(world.playerY, 1);
    expect(world.roomX, 0);
    expect(world.roomY, 0);
    world.tick();
    expect(world.playerX, 1);
    expect(world.playerY, 2);
    world.up();
    world.tick();
    expect(world.playerX, 1);
    expect(world.playerY, 2);
    world.up();
    world.tick();
    world.tick();
    expect(world.playerX, 1);
    expect(world.playerY, 4);
    expect(world.roomX, 0);
    expect(world.roomY, -1);
  });
  testWidgets('Wood collection/placement', (widgetTester) async {
    World world = World(MockRandom());
    expect(world.inv[wood], isNull);
    world.tick();
    world.left();
    world.up();
    world.tick();
    world.tick();
    world.right();
    world.down();
    expect(world.inv[wood], 1);
    expect(world.tableOpen, isNull);
    expect(world.tables.values.expand((e) => e), isEmpty);
    world.openTable();
    expect(world.tableOpen, isNull);
    expect(world.place(wood), true);
    expect(world.tables.values.expand((e) => e), hasLength(1));
    expect(world.tableOpen, isNull);
    world.openTable();
    expect(world.tableOpen, isNotNull);
  });
  testWidgets('Mining iron', (WidgetTester tester) async {
    World world = World(MockRandom());
    world.tick();
    expect(world.inv[iron], isNull);
    bool mined = false;
    world.mine(() {
      mined = true;
    });
    await tester.pump(const Duration(seconds: 2));
    expect(mined, true);
    expect(world.inv[stone], isNull);
    expect(world.inv[iron], 1);
  });
  testWidgets('Robot collection/placement', (WidgetTester tester) async {
    World world = World(MockRandom());
    expect(world.robots, isEmpty);
    expect(world.inv[robot], isNull);
    world.tick();
    world.left();
    world.up();
    world.tick();
    world.tick();
    world.right();
    world.down();
    expect(world.place(wood), true);
    world.openTable();
    world.mine(() {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(world.recipes[0]);
    expect(world.inv[robot], 1);
    world.place(robot);
    expect(world.robots, hasLength(1));
  });
  testWidgets('Robot movement/gathering', (WidgetTester tester) async {
    World world = World(MockRandom());
    world.tick();
    world.left();
    world.up();
    world.tick();
    world.tick();
    world.right();
    world.down();
    world.place(wood);
    world.openTable();
    world.mine(() {});
    await tester.pump(const Duration(seconds: 2));
    world.craft(world.recipes[0]);
    world.place(robot);
    IntegerOffset robotPos = world.robots.keys.single;
    Robot roombot = world.robots.values.single.single;
    expect(robotPos.x, world.roomX);
    expect(robotPos.y, world.roomY);
    expect(roombot.dx, world.playerX);
    expect(roombot.dy, world.playerY);
    expect(roombot.inv, 0);
  });
}

class MockRandom implements Random {
  @override
  bool nextBool() {
    throw UnimplementedError();
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

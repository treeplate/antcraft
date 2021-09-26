// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'images.dart';
import 'logic.dart';
import 'tutorialoverride.dart';

const bool debugMode = false;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool d = false;
  bool a = false;
  bool w = false;
  bool s = false;
  bool e = false;

  late final World world = World(Random());

  Room get room {
    return world.room;
  }

  String get tutorial {
    if (tutorialOverride(world) != null) return tutorialOverride(world)!;
    if (won) return "You Won!";
    if (world.shopActive) {
      if ((world.inv['wood.raw'] ?? 0) >= 100) {
        return "Win the game by buying the 'Win game' item";
      }
      return "Remember to get wood before you go to the shop. (press Leave shop)";
    }

    if (room.shop) {
      if ((world.inv['wood.raw'] ?? 0) >= 100) {
        return "Go to the red square (the shop) and press x";
      }
    }
    if ((world.inv['wood.raw'] ?? 0) >= 100) {
      if (world.tableOpen != null) return "Press the X button";
      if (world.roomX > 1) return "Go left (press a)";
      if (world.roomX < 1) return "Go right (press d)";
      if (world.roomY > 1) return "Go up (press w)";
      return "Go down (press s)";
    }
    return 'XXX';
  }

  bool invActive = false;
  bool won = false;
  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      if (event is RawKeyDownEvent && w == false) {
        w = true;
        world.up();
      }
      if (event is RawKeyUpEvent) {
        w = false;
        world.down();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      if (event is RawKeyDownEvent && s == false) {
        s = true;
        world.down();
      }
      if (event is RawKeyUpEvent) {
        s = false;
        world.up();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      if (event is RawKeyDownEvent && d == false) {
        d = true;
        world.right();
      }
      if (event is RawKeyUpEvent) {
        d = false;
        world.left();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      if (event is RawKeyDownEvent && a == false) {
        a = true;
        world.left();
      }
      if (event is RawKeyUpEvent) {
        a = false;
        world.right();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyE && event is RawKeyUpEvent) {
      e = false;
    }
    if (event.character == "v") {
      world.mine(() {
        mineFeedback = "+1";
        Timer(
          const Duration(milliseconds: 500),
          () => setState(() => mineFeedback = ""),
        );
      });
    }
    if (event.character == "q") {
      world.place('wood.raw');
    }
    if (event.character == "c") {
      world.place('robot');
    }
    if (event.character == "x") {
      world.openShop();
    }
    if (event.character == "f") {
      world.openTable();
    }
    if (event.character == "e" && e == false) {
      e = true;
      invActive = !invActive;
    }

    return KeyEventResult.handled;
  }

  String mineFeedback = "";
  Map<int, Map<int, List<Offset>>> totalTables = {};
  late Timer movement =
      Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (_) {
    setState(world.tick);
  });
  _MyHomePageState() {
    movement;
  }
  @override
  void dispose() {
    super.dispose();
    movement.cancel();
  }

  @override
  Widget build(BuildContext context) {
    //debugDumpApp();
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      world.screenWidth = constraints.maxWidth / 10;
      world.screenHeight = constraints.maxHeight / 10;
      return Scaffold(
        body: Focus(
          onKey: _handleKeyPress,
          autofocus: true,
          child: ScreenFiller(
            child: Container(
              color: Colors.grey,
              child: Stack(
                children: [
                  if (room.ore != "none" && debugMode)
                    Positioned(
                      left: room.orePos.dx * 10,
                      top: room.orePos.dy * 10,
                      child: Container(
                        width: 150,
                        height: 150,
                        color: Colors.green,
                      ),
                    ),
                  if (room.shop)
                    Positioned(
                      left: constraints.maxWidth / 2 - 75,
                      top: constraints.maxHeight / 2 - 75,
                      child: Container(
                        width: 150,
                        height: 150,
                        color: Colors.red,
                      ),
                    ),
                  if (room.ore != "none")
                    Positioned(
                      left: room.orePos.dx * 10,
                      top: room.orePos.dy * 10,
                      child: ItemRenderer(
                        room.ore,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  if (debugMode)
                    Positioned(
                      left: room.logPos.dx * 10,
                      top: room.logPos.dy * 10,
                      child: Container(
                        width: 30,
                        height: 30,
                        color: Colors.green,
                      ),
                    ),
                  Positioned(
                    left: room.logPos.dx * 10,
                    top: room.logPos.dy * 10,
                    child: const ItemRenderer(
                      "wood.raw",
                      width: 30,
                      height: 30,
                    ),
                  ),
                  for (Offset table in {
                    for (MapEntry<Offset, Table> x
                        in world.tablesAt(world.roomX, world.roomY))
                      x.key: x.value
                  }.keys) ...[
                    if (debugMode)
                      Positioned(
                        left: table.dx * 10,
                        top: table.dy * 10,
                        child: Container(
                          color: Colors.green,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    Positioned(
                      left: table.dx * 10,
                      top: table.dy * 10,
                      child: const ItemRenderer(
                        "wood.placed",
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                  for (Offset robot in world.robots.entries
                      .toList()
                      .where(
                        (element) =>
                            element.key.x == world.roomX &&
                            element.key.y == world.roomY,
                      )
                      .map((e) => Offset(e.value.dx, e.value.dy))) ...[
                    if (debugMode)
                      Positioned(
                        left: robot.dx * 10,
                        top: robot.dy * 10,
                        child: Container(
                          color: Colors.green,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    Positioned(
                      left: robot.dx * 10,
                      top: robot.dy * 10,
                      child: const ItemRenderer(
                        "robot",
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                  Positioned(
                    left: world.playerX / .1,
                    top: world.playerY / .1,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.green),
                    ),
                  ),
                  for (IntegerOffset robot in world.robots.entries
                      .toList()
                      .where(
                        (element) => !(element.key.x == world.roomX &&
                            element.key.y == world.roomY),
                      )
                      .map((e) => e.key)) ...[
                    Positioned(
                      left: robot.x < world.roomX
                          ? 0
                          : robot.x > world.roomX
                              ? (world.screenWidth * 10) - 30
                              : (world.screenWidth * 5) - 30,
                      top: robot.y < world.roomY
                          ? 0
                          : robot.y > world.roomY
                              ? (world.screenHeight * 10) - 30
                              : (world.screenHeight * 5) - 30,
                      child: const ItemRenderer(
                        "furnace",
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                  Positioned(
                    left: world.playerX / .1,
                    top: world.playerY / .1,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.green),
                    ),
                  ),
                  if (world.shopActive)
                    Center(
                      child: Container(
                        color: Colors.lime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShopItem(
                              1000,
                              () {
                                won = true;
                              },
                              "Win game",
                              (world.inv["wood.raw"] ?? 0),
                              (g) => world.inv["wood.raw"] = g,
                              goldKey: "wood.raw",
                            ),
                            TextButton(
                                onPressed: world.closeShop,
                                child: const Text("Leave shop")),
                          ],
                        ),
                      ),
                    ),
                  if (world.tableOpen != null)
                    Center(
                      child: Container(
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TableSlotDropdown(
                                  inv: world.inv,
                                  slotKey: SlotKey.x0y0,
                                  table: world.tableOpen!,
                                  world: world,
                                ),
                                TableSlotDropdown(
                                  inv: world.inv,
                                  slotKey: SlotKey.x0y1,
                                  table: world.tableOpen!,
                                  world: world,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TableSlotDropdown(
                                  inv: world.inv,
                                  slotKey: SlotKey.x1y0,
                                  table: world.tableOpen!,
                                  world: world,
                                ),
                                TableSlotDropdown(
                                  inv: world.inv,
                                  slotKey: SlotKey.x1y1,
                                  table: world.tableOpen!,
                                  world: world,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => world.closeTable(),
                                  child: const Text("X"),
                                ),
                                TextButton(
                                  onPressed: () => setState(world.craft),
                                  child: ItemRenderer(
                                    world.tableOpen!.result,
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (invActive)
                    Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        color: Colors.black,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: world.inv.keys
                                .map(
                                  (a) => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ItemRenderer(
                                        a,
                                        width: 30,
                                        height: 30,
                                      ),
                                      Text(
                                        "${world.inv[a]}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  Center(child: Text(mineFeedback)),
                  Text(tutorial),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class ItemDropdown extends StatelessWidget {
  const ItemDropdown({
    Key? key,
    required this.inv,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final Map<String, int> inv;
  final String value;
  final void Function(String? x) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      items: (inv.keys.followedBy(const ["none"]))
          .map(
            (String e) => DropdownMenuItem(
              child: ItemRenderer(
                e,
                width: 30,
                height: 30,
              ),
              value: e,
            ),
          )
          .toList(),
      value: value,
      onChanged: onChanged,
    );
  }
}

class TableSlotDropdown extends StatefulWidget {
  const TableSlotDropdown({
    Key? key,
    required this.inv,
    required this.slotKey,
    required this.table,
    required this.world,
  }) : super(key: key);

  final Map<String, int> inv;
  final SlotKey slotKey;
  final Table table;
  final World world;
  @override
  _TableSlotDropdownState createState() => _TableSlotDropdownState();
}

class _TableSlotDropdownState extends State<TableSlotDropdown> {
  @override
  Widget build(BuildContext context) {
    return ItemDropdown(
      inv: widget.inv,
      value: widget.table.grid[widget.slotKey]!,
      onChanged: (String? value) {
        setState(() {
          widget.world.setCraftCorner(widget.slotKey, value!);
        });
      },
    );
  }
}

class ShopItem extends StatelessWidget {
  const ShopItem(this.cost, this.result, this.text, this.gold, this.goldSet,
      {Key? key, required this.goldKey})
      : super(key: key);
  final int cost;
  final void Function() result;
  final String text;
  final int gold;
  final String goldKey;
  final void Function(int) goldSet;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        Row(
          children: [
            ItemRenderer(
              goldKey,
              width: 30,
              height: 30,
            ),
            Text(cost.toString())
          ],
        ),
        TextButton(
          onPressed: () {
            if (cost <= gold) {
              goldSet(gold - cost);
              result();
            }
          },
          child: const Text("Buy"),
        ),
      ],
    );
  }
}

class ScreenFiller extends SingleChildRenderObjectWidget {
  const ScreenFiller({Key? key, required Widget child})
      : super(key: key, child: child);
  @override
  @override
  RenderObject createRenderObject(BuildContext context) {
    return SFRenderObject();
  }
}

class SFRenderObject extends RenderProxyBox {
  @override
  bool hitTestSelf(Offset position) => true;
}

class DirectionalIntent extends Intent {
  const DirectionalIntent(this.x, this.y);
  final int x;
  final int y;
}

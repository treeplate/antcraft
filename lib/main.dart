// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'images.dart';

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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool d = false;
  bool a = false;
  bool w = false;
  bool s = false;

  bool recentMined = false;
  double screenWidth = 144;
  double screenHeight = 90;

  final List<String> ores = ["ore.raw.iron"];

  bool craftingOpen = false;

  final Map<int, Map<int, Room>> rooms = {};

  Table? tableOpen;
  Room get room {
    if (rooms[roomX] == null) {
      rooms[roomX] = {};
    }
    if (rooms[roomX]![roomY] == null) {
      rooms[roomX]![roomY] = Room(
        Offset(
          (Random().nextDouble() * (screenWidth - 15)).roundToDouble(),
          (Random().nextDouble() * (screenHeight - 15)).roundToDouble(),
        ),
        {},
        (ores..shuffle()).first,
        playerX == 1 && playerY == 1,
        Offset(
          (Random().nextDouble() * (screenWidth - 15)).roundToDouble(),
          (Random().nextDouble() * (screenHeight - 15)).roundToDouble(),
        ),
      );
    }
    return rooms[roomX]![roomY]!;
  }

  String get tutorial {
    if (won) return "You Won!";
    if (shopActive) {
      if ((inv['furnace'] ?? 0) >= 1) {
        return "Win the game by buying the 'Win game' item";
      }
      return "Remember to get a furnace before you go to the shop. (press Leave shop)";
    }

    if (roomX == 1 && roomY == 1) {
      if ((inv['furnace'] ?? 0) >= 1) {
        return "Go to the red square (the shop) and press x";
      }
    }
    if ((inv['furnace'] ?? 0) >= 1) {
      if (tableOpen != null) return "Press the X button";
      if (roomX > 1) return "Go left (press a)";
      if (roomX < 1) return "Go right (press d)";
      if (roomY > 1) return "Go up (press w)";
      return "Go down (press s)";
    }
    if ((tableOpen?.result ?? "none") == "furnace") {
      return "Take your furnace (the new icon) by clicking on it.";
    }
    if ((inv['ore.just.stone'] ?? 0) < 2) {
      return "Press v on the gray floor to get some grey stone.";
    }
    if (tableOpen != null) {
      return "Set the top-left and bottom-right dropdowns to stone.";
    }
    if (woodPlaced) {
      return "Press f on your placed wood to open it.";
    }
    if ((inv['wood.raw'] ?? 0) >= 1) {
      return "Press q to place your wood.";
    }
    return "Walk over a wood log to get some wood.";
  }

  bool woodPlaced = false;

  bool won = false;
  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      if (event is RawKeyDownEvent && w == false) {
        w = true;
        yVel -= 1;
      }
      if (event is RawKeyUpEvent) {
        w = false;
        yVel += 1;
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      if (event is RawKeyDownEvent && s == false) {
        s = true;
        yVel += 1;
      }
      if (event is RawKeyUpEvent) {
        s = false;
        yVel -= 1;
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      if (event is RawKeyDownEvent && d == false) {
        d = true;
        xVel += 1;
      }
      if (event is RawKeyUpEvent) {
        d = false;
        xVel -= 1;
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      if (event is RawKeyDownEvent && a == false) {
        a = true;
        xVel -= 1;
      }
      if (event is RawKeyUpEvent) {
        a = false;
        xVel += 1;
      }
      return KeyEventResult.handled;
    }
    if (event.character == "v" && !recentMined) {
      recentMined = true;
      if (playerX > room.orePos.dx &&
          playerY > room.orePos.dy &&
          playerX < room.orePos.dx + 30 &&
          playerY < room.orePos.dy + 30 &&
          room.ore != "none") {
        inv[room.ore] = (inv[room.ore] ?? 0) + 1;
      } else {
        inv["ore.just.stone"] = (inv["ore.just.stone"] ?? 0) + 1;
      }
      mineFeedback = "+1";
      Timer(const Duration(milliseconds: 500),
          () => setState(() => mineFeedback = ""));
      Timer(Duration(seconds: cooldown), () => recentMined = false);
    }
    if (event.character == "q" && (inv['wood.raw'] ?? 0) > 0) {
      woodPlaced = true;
      inv['wood.raw'] = inv['wood.raw']! - 1;
      room.tables[Offset(playerX / 1, playerY / 1)] = Table();
    }
    if (event.character == "c" && (inv['robot'] ?? 0) > 0) {
      woodPlaced = true;
      inv['robot'] = inv['robot']! - 1;
      robots[IntegerOffset(roomX, roomY)] = Offset(playerX / 1, playerY / 1);
    }
    if (event.character == "x" &&
        playerX > screenWidth / 2 - 7.5 &&
        playerY > screenHeight / 2 - 7.5 &&
        playerX < (15 + screenWidth / 2) - 7.5 &&
        playerY < (screenHeight / 2 + 15) - 7.5 &&
        roomX == 1 &&
        roomY == 1) {
      shopActive = true;
    }
    if (event.character == "f") {
      for (MapEntry<Offset, Table> table in room.tables.entries) {
        Offset logPos = table.key;
        if (((logPos.dx > playerX && logPos.dx < playerX + 5) ||
                (logPos.dx + 3 > playerX && logPos.dx + 3 < playerX + 5)) &&
            ((logPos.dy + 3 > playerY && logPos.dy + 3 < playerY + 5) ||
                (logPos.dy > playerY && logPos.dy < playerY + 5))) {
          tableOpen = table.value;
        }
      }
    }
    if (event.character == "e") {
      invActive = !invActive;
    }
    return KeyEventResult.handled;
  }

  String mineFeedback = "";
  int cooldown = 2;
  int playerX = 0;
  int playerY = 0;
  int xVel = 0;
  int yVel = 0;
  int roomX = 0;
  int roomY = 0;
  Map<int, Map<int, List<Offset>>> totalTables = {};
  late Timer movement =
      Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (_) {
    setState(() {
      if (playerX <= 0) {
        roomX--;
        playerX = (screenWidth - 6).round();
      }
      if (playerX >= (screenWidth - 5).round()) {
        roomX++;
        playerX = 1;
      }
      if (playerY <= 0) {
        roomY--;
        playerY = (screenHeight - 6).round();
      }
      if (playerY >= (screenHeight - 5).round()) {
        roomY++;
        playerY = 1;
      }
      playerX += xVel;
      playerY += yVel;
      if (((room.logPos.dx > playerX && room.logPos.dx < playerX + 5) ||
              (room.logPos.dx + 3 > playerX &&
                  room.logPos.dx + 3 < playerX + 5)) &&
          ((room.logPos.dy + 3 > playerY && room.logPos.dy + 3 < playerY + 5) ||
              (room.logPos.dy > playerY && room.logPos.dy < playerY + 5))) {
        room.logPos = ([const Offset(-30, -30), Offset(-30, screenHeight + 30)]
              ..shuffle(Random(room.logPos.dx.ceil())))
            .first;

        inv['wood.raw'] = (inv['wood.raw'] ?? 0) + 1;
      }
      print(robots.entries.length);
      for (MapEntry<IntegerOffset, Offset> robot in robots.entries.toList()) {
        if (rooms[robot.key.x] == null) {
          rooms[robot.key.x] = {};
        }
        if (rooms[robot.key.x]![robot.key.y] == null) {
          rooms[robot.key.x]![robot.key.y] = Room(
            Offset(
              (Random().nextDouble() * (screenWidth - 15)).roundToDouble(),
              (Random().nextDouble() * (screenHeight - 15)).roundToDouble(),
            ),
            {},
            (ores..shuffle()).first,
            robot.key.x == 1 && robot.key.y == 1,
            Offset(
              (Random().nextDouble() * (screenWidth - 15)).roundToDouble(),
              (Random().nextDouble() * (screenHeight - 15)).roundToDouble(),
            ),
          );
        }
        Room room = rooms[robot.key.x]![robot.key.y]!;

        //("Pre-move ${robot.key.hashCode} pos ${robots[robot.key]} logpos ${room.logPos}");
        if (robot.value == room.logPos) {
          inv['wood.raw'] = (inv['wood.raw'] ?? 0) + 1;
          room.logPos = ([
            const Offset(-30, -30),
            Offset(-30, screenHeight + 30)
          ]..shuffle(Random(room.logPos.dx.ceil())))
              .first;
        }

        if (robot.value.dx > room.logPos.dx) {
          //("L.${robot.key.hashCode} pos ${robots[robot.key]}");
          robots[robot.key] = Offset(robot.value.dx - .5, robot.value.dy);
          //("L.${robot.key.hashCode} postpos ${robots[robot.key]}");
          robot =
              robots.entries.toList()[robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dx < room.logPos.dx) {
          //("R.${robot.key.hashCode} pos ${robots[robot.key]}");
          robots[robot.key] = Offset(robot.value.dx + .5, robot.value.dy);
          //("R.${robot.key.hashCode} postpos ${robots[robot.key]}");
          robot =
              robots.entries.toList()[robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy > room.logPos.dy) {
          //("U.${robot.key.hashCode} pos ${robots[robot.key]}");
          robots[robot.key] = Offset(robot.value.dx, robot.value.dy - .5);
          //("U.${robot.key.hashCode} postpos ${robots[robot.key]}");
          robot =
              robots.entries.toList()[robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy < room.logPos.dy) {
          //("D.${robot.key.hashCode} pos ${robots[robot.key]}");
          robots[robot.key] = Offset(robot.value.dx, robot.value.dy + .5);
          //("D.${robot.key.hashCode} postpos ${robots[robot.key]}");
          robot =
              robots.entries.toList()[robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dx <= 0) {
          robots.remove(robot.key);
          robots[IntegerOffset(robot.key.x - 1, robot.key.y)] =
              Offset(screenWidth.roundToDouble() - 1, robot.value.dy);
          robot = robots.entries.toList()[robots.keys.length - 1];
        }
        if (robot.value.dx >= screenWidth) {
          robots.remove(robot.key);
          robots[IntegerOffset(robot.key.x + 1, robot.key.y)] =
              Offset(1, robot.value.dy);
          robot = robots.entries.toList()[robots.keys.length - 1];
        }
        if (robot.value.dy <= 0) {
          robots.remove(robot.key);
          robots[IntegerOffset(robot.key.x, robot.key.y - 1)] =
              Offset(robot.value.dx, screenHeight.roundToDouble() - 1);
          robot = robots.entries.toList()[robots.keys.length - 1];
        }
        if (robot.value.dy >= screenHeight) {
          robots.remove(robot.key);
          robots[IntegerOffset(robot.key.x, robot.key.y + 1)] =
              Offset(robot.value.dx, 1);
        }
        //("Post-move ${robot.key.hashCode} pos ${robots[robot.key]}");
      }
    });
  });
  _MyHomePageState() {
    movement;
  }
  @override
  void dispose() {
    super.dispose();
    movement.cancel();
  }

  Map<String, int> inv = {};
  bool shopActive = false;
  bool invActive = false;
  @override
  Widget build(BuildContext context) {
    //debugDumpApp();
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      screenWidth = constraints.maxWidth / 10;
      screenHeight = constraints.maxHeight / 10;
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
                  if (roomX == 1 && roomY == 1)
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
                  for (Offset table in room.tables.keys) ...[
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
                  for (Offset robot in robots.entries
                      .toList()
                      .where(
                        (element) =>
                            element.key.x == roomX && element.key.y == roomY,
                      )
                      .map((e) => e.value)) ...[
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
                    left: playerX / .1,
                    top: playerY / .1,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.green),
                    ),
                  ),
                  for (IntegerOffset robot in robots.entries
                      .toList()
                      .where(
                        (element) =>
                            !(element.key.x == roomX && element.key.y == roomY),
                      )
                      .map((e) => e.key)) ...[
                    Positioned(
                      left: robot.x < roomX
                          ? 0
                          : robot.x > roomX
                              ? (screenWidth * 10) - 30
                              : (screenWidth * 5) - 30,
                      top: robot.y < roomY
                          ? 0
                          : robot.y > roomY
                              ? (screenHeight * 10) - 30
                              : (screenHeight * 5) - 30,
                      child: const ItemRenderer(
                        "furnace",
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                  Positioned(
                    left: playerX / .1,
                    top: playerY / .1,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.green),
                    ),
                  ),
                  if (shopActive)
                    Center(
                      child: Container(
                        color: Colors.lime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShopItem(
                              1,
                              () {
                                won = true;
                              },
                              "Win game",
                              (inv["furnace"] ?? 0),
                              (g) => inv["furnace"] = g,
                              goldKey: "furnace",
                            ),
                            TextButton(
                                onPressed: () => shopActive = false,
                                child: const Text("Leave shop")),
                          ],
                        ),
                      ),
                    ),
                  if (tableOpen != null)
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
                                  inv: inv,
                                  slotKey: SlotKey.x0y0,
                                  table: tableOpen!,
                                ),
                                TableSlotDropdown(
                                  inv: inv,
                                  slotKey: SlotKey.x0y1,
                                  table: tableOpen!,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TableSlotDropdown(
                                  inv: inv,
                                  slotKey: SlotKey.x1y0,
                                  table: tableOpen!,
                                ),
                                TableSlotDropdown(
                                  inv: inv,
                                  slotKey: SlotKey.x1y1,
                                  table: tableOpen!,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => tableOpen = null,
                                  child: const Text("X"),
                                ),
                                TextButton(
                                  onPressed: tableOpen!.result == "none"
                                      ? null
                                      : () {
                                          setState(() {
                                            inv[tableOpen!.result] =
                                                (inv[tableOpen!.result] ?? 0) +
                                                    1;
                                            tableOpen!.grid = {
                                              SlotKey.x0y0: "none",
                                              SlotKey.x0y1: "none",
                                              SlotKey.x1y0: "none",
                                              SlotKey.x1y1: "none",
                                            };
                                          });
                                        },
                                  child: ItemRenderer(
                                    tableOpen!.result,
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
                            children: inv.keys
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
                                        "${inv[a]}",
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

  final Map<IntegerOffset, Offset> robots = {};
}

class IntegerOffset {
  final int x;
  final int y;

  IntegerOffset(this.x, this.y);
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
  }) : super(key: key);

  final Map<String, int> inv;
  final SlotKey slotKey;
  final Table table;
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
          if (value == "none" || widget.inv[value]! > 0) {
            if (widget.table.grid[widget.slotKey] != "none") {
              widget.inv[widget.table.grid[widget.slotKey]!] =
                  widget.inv[widget.table.grid[widget.slotKey]!]! + 1;
            }

            if (value! != "none") {
              widget.inv[value] = widget.inv[value]! - 1;
            }
            widget.table.grid[widget.slotKey] = value;
          }
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

class Room {
  Offset logPos;
  final Map<Offset, Table> tables;
  final String ore;
  final Offset orePos;
  final bool shop;

  Room(this.logPos, this.tables, this.ore, this.shop, this.orePos);
}

enum SlotKey { x0y0, x0y1, x1y0, x1y1 }

class Table {
  Map<SlotKey, String> grid = {
    SlotKey.x0y0: "none",
    SlotKey.x0y1: "none",
    SlotKey.x1y0: "none",
    SlotKey.x1y1: "none",
  };

  String get result {
    if (grid[SlotKey.x0y0] == "ore.just.stone" &&
        grid[SlotKey.x1y0] == "none" &&
        grid[SlotKey.x0y1] == "none" &&
        grid[SlotKey.x1y1] == "ore.just.stone") {
      return "furnace";
    }
    if (grid[SlotKey.x0y0] == "ore.raw.iron" &&
        grid[SlotKey.x1y0] == "none" &&
        grid[SlotKey.x0y1] == "none" &&
        grid[SlotKey.x1y1] == "none") {
      return "robot";
    }
    return "none";
  }
}

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'images.dart';

const bool debugMode = false;
Map<String, MaterialColor> oreColors = {
  "gold": Colors.yellow,
  "iron": Colors.blue,
  "stone": Colors.grey,
};
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

  final List<String> ores = ["ore.raw.iron", "ore.raw.gold"];

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
          Random().nextDouble() * (screenWidth - 15),
          Random().nextDouble() * (screenHeight - 15),
        ),
        {},
        (ores..shuffle()).first,
        roomX == 1 && roomY == 1,
        Offset(
          Random().nextDouble() * (screenWidth - 15),
          Random().nextDouble() * (screenHeight - 15),
        ),
      );
    }
    return rooms[roomX]![roomY]!;
  }

  String get tutorial {
    if (won) return "You Won!";
    if (shopActive) {
      if ((inv['ore.raw.iron'] ?? 0) >= 20) {
        return "Win the game by buying the 'Win game' item";
      }
      if ((inv['ore.raw.gold'] ?? 0) >= 5) return "Buy a better pick.";
      return "Remember to get gold before you go to the shop. (press Leave shop)";
    }
    if (((inv['ore.raw.iron'] ?? 0) >= 20 && (roomX != 1 || roomY != 1)) ||
        ((inv['ore.raw.gold'] ?? 0) >= 5 && (roomX != 1 || roomY != 1))) {
      if (roomX > 1) return "Go left";
      if (roomX < 1) return "Go right";
      if (roomY > 1) return "Go up (press w)";
      return "Go down";
    }
    if (roomX == 1 && roomY == 1) {
      if (((inv['ore.raw.gold'] ?? 0) >= 5) ||
          (inv['ore.raw.iron'] ?? 0) >= 20) {
        return "Go to the red square (the shop) and press x";
      }
    }
    if (cooldown == 1 && room.ore == "ore.raw.iron") {
      return "Now that mining has a lower cooldown, mine iron in the iron mine (big square) until you get to twenty.";
    }
    if (cooldown == 3 && room.ore == "ore.raw.gold") {
      return "Press a to go left and s to go down and d to go right: Go to the gold mine (the big square) and hold v to mine it.";
    }
    return "Go up (press w)";
  }

  bool invOpened = false;

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
      invOpened = false;
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
      inv['wood.raw'] = inv['wood.raw']! - 1;
      room.tables[Offset(playerX / 1, playerY / 1)] = Table();
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
      print("F pressed");
      for (MapEntry<Offset, Table> table in room.tables.entries) {
        Offset logPos = table.key;
        if (((logPos.dx > playerX && logPos.dx < playerX + 5) ||
                (logPos.dx + 3 > playerX && logPos.dx + 3 < playerX + 5)) &&
            ((logPos.dy + 3 > playerY && logPos.dy + 3 < playerY + 5) ||
                (logPos.dy > playerY && logPos.dy < playerY + 5))) {
          print("Crafing opened");
          tableOpen = table.value;
        }
      }
    }
    if (event.character == "e") {
      invOpened = true;
      invActive = !invActive;
    }
    return KeyEventResult.handled;
  }

  String mineFeedback = "";
  int cooldown = 3;
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
        room.logPos = const Offset(-30, -30);
        if (inv['wood.raw'] == null) inv['wood.raw'] = 0;
        inv['wood.raw'] = inv['wood.raw']! + 1;
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
                            if (cooldown == 3)
                              ShopItem(
                                5,
                                () {
                                  cooldown = 1;
                                  shopActive = false;
                                },
                                "Better pick",
                                (inv["ore.raw.gold"] ?? 0),
                                (g) => inv["ore.raw.gold"] = g,
                                goldKey: "ore.raw.gold",
                              ),
                            ShopItem(
                              20,
                              () {
                                won = true;
                              },
                              "Win game",
                              (inv["ore.raw.iron"] ?? 0),
                              (g) => inv["ore.raw.iron"] = g,
                              goldKey: "ore.raw.iron",
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
                                ItemDropdown(
                                  inv: inv,
                                  onChanged: (String? value) {
                                    setState(() {
                                      tableOpen!.x0y0 = value!;
                                    });
                                  },
                                  value: tableOpen!.x0y0,
                                ),
                                ItemDropdown(
                                  inv: inv,
                                  onChanged: (String? value) {
                                    setState(() {
                                      tableOpen!.x0y1 = value!;
                                    });
                                  },
                                  value: tableOpen!.x0y1,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ItemDropdown(
                                  inv: inv,
                                  onChanged: (String? value) {
                                    setState(() {
                                      tableOpen!.x1y0 = value!;
                                    });
                                  },
                                  value: tableOpen!.x1y0,
                                ),
                                ItemDropdown(
                                  inv: inv,
                                  onChanged: (String? value) {
                                    setState(() {
                                      tableOpen!.x1y1 = value!;
                                    });
                                  },
                                  value: tableOpen!.x1y1,
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
      value: "wood.raw",
      onChanged: onChanged,
    );
  }
}

class ItemRenderer extends StatelessWidget {
  final String item;

  const ItemRenderer(this.item,
      {Key? key, required this.width, required this.height})
      : super(key: key);
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (item.contains(".") && item.substring(0, item.indexOf(".")) == "ore") {
      return OreRenderer(
        color: oreColors[item.substring(item.lastIndexOf(".") + 1)]!,
        smelted:
            !(item.substring(item.indexOf(".") + 1, item.lastIndexOf(".")) ==
                "raw"),
        height: height,
        width: width,
      );
    }
    if (item.contains(".") && item.substring(0, item.indexOf(".")) == "wood") {
      return WoodRenderer(
        placed: item.substring(item.indexOf(".") + 1) == "placed",
        height: height,
        width: width,
      );
    }
    if (item == "none") return Container();
    return Text(
      "unknown key $item",
      style: const TextStyle(color: Colors.red),
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

class Table {
  String x0y0 = "none";
  String x1y0 = "none";
  String x0y1 = "none";
  String x1y1 = "none";
}

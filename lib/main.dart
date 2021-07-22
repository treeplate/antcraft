// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'images.dart';
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
  Map<int, Map<int, String>> roomOres = {
    //1: {1: "none"},
  };
  Map<int, Map<int, Offset>> roomOrePositions = {};

  final List<String> ores = ["ore.raw.iron", "ore.raw.gold"];
  String get roomOre {
    if (roomOres[roomX] == null) {
      roomOres[roomX] = {};
      roomOrePositions[roomX] = {};
    }
    if (roomOres[roomX]![roomY] == null) {
      roomOres[roomX]![roomY] = (ores..shuffle()).first;
      roomOrePositions[roomX]![roomY] =
          Offset(Random().nextDouble() * 129, Random().nextDouble() * 75);
    }
    return roomOres[roomX]![roomY]!;
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
    if (cooldown == 1 && roomOre == "ore.raw.iron") {
      return "Now that mining has a lower cooldown, mine iron in the iron mine (big square) until you get to twenty.";
    }
    if (cooldown == 3 && roomOre == "ore.raw.gold") {
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
      if (playerX > roomOrePositions[roomX]![roomY]!.dx &&
          playerY > roomOrePositions[roomX]![roomY]!.dy &&
          playerX < roomOrePositions[roomX]![roomY]!.dx + 30 &&
          playerY < roomOrePositions[roomX]![roomY]!.dy + 30 &&
          roomOre != "none") {
        inv[roomOre] = (inv[roomOre] ?? 0) + 1;
      } else {
        inv["ore.just.stone"] = (inv["ore.just.stone"] ?? 0) + 1;
      }
      Timer(Duration(seconds: cooldown), () => recentMined = false);
    }
    if (event.character == "x" &&
        playerX > 72 - 7.5 &&
        playerY > 45 - 7.5 &&
        playerX < (15 + 72) - 7.5 &&
        playerY < (45 + 15) - 7.5 &&
        roomX == 1 &&
        roomY == 1) {
      shopActive = true;
    }
    if (event.character == "e") {
      invOpened = true;
      invActive = !invActive;
    }
    return KeyEventResult.handled;
  }

  int cooldown = 3;
  int playerX = 0;
  int playerY = 0;
  int xVel = 0;
  int yVel = 0;
  int roomX = 0;
  int roomY = 0;
  late Timer movement =
      Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (_) {
    setState(() {
      if (playerX <= 0) {
        roomX--;
        playerX = 138;
      }
      if (playerX >= 139) {
        roomX++;
        playerX = 1;
      }
      if (playerY <= 0) {
        roomY--;
        playerY = 84;
      }
      if (playerY >= 85) {
        roomY++;
        playerY = 1;
      }
      playerX += xVel;
      playerY += yVel;
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
    return Scaffold(
      body: Focus(
        onKey: _handleKeyPress,
        autofocus: true,
        child: ScreenFiller(
          child: Container(
            color: Colors.grey,
            child: Stack(
              children: [
                const Center(),
                if (roomOre != "none")
                  Positioned(
                    left: roomOrePositions[roomX]![roomY]!.dx * 10,
                    top: roomOrePositions[roomX]![roomY]!.dy * 10,
                    child: Container(
                      width: 150,
                      height: 150,
                      color: Colors.green,
                    ),
                  ),
                if (roomX == 1 && roomY == 1)
                  Positioned(
                    left: 720 - 75,
                    top: 450 - 75,
                    child: Container(
                      width: 150,
                      height: 150,
                      color: Colors.red,
                    ),
                  ),
                if (roomOre != "none")
                  Positioned(
                    left: roomOrePositions[roomX]![roomY]!.dx * 10,
                    top: roomOrePositions[roomX]![roomY]!.dy * 10,
                    child: ItemRenderer(roomOre),
                  ),
                Positioned(
                  left: playerX / .1,
                  top: playerY / .1,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(75)),
                        color: Colors.green),
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
                                    ),
                                    Text(
                                      "${inv[a]}",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                Text(tutorial),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemRenderer extends StatelessWidget {
  final String item;

  const ItemRenderer(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item.contains(".") && item.substring(0, item.indexOf(".")) == "ore") {
      return OreRenderer(
          color: oreColors[item.substring(item.lastIndexOf(".") + 1)]!,
          smelted:
              !(item.substring(item.indexOf(".") + 1, item.lastIndexOf(".")) ==
                  "raw"));
    }
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
          children: [ItemRenderer(goldKey), Text(cost.toString())],
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
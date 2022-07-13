// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Table;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'core.dart';
import 'estd.dart';
import 'images.dart';
import 'logic.dart';

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

enum VerticalDirection { up, down, stay }

enum HorizontalDirection { left, right, stay }

@immutable
class Direction {
  final VerticalDirection vertical;
  final HorizontalDirection horizontal;

  @override
  int get hashCode => vertical.hashCode ^ horizontal.hashCode;

  const Direction(this.vertical, this.horizontal);

  @override
  bool operator ==(Object other) {
    return other is Direction &&
        vertical == other.vertical &&
        horizontal == other.horizontal;
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

  static const List<EntityCell> toolbar = [
    EntityCell(wood, LogicalKeyboardKey.digit1),
    EntityCell(robot, LogicalKeyboardKey.digit2),
    EntityCell(miner, LogicalKeyboardKey.digit3),
    EntityCell(dirt, LogicalKeyboardKey.digit4),
  ];

  String get tutorial {
    return '';
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
    if (event.character == 'v') {
      world.mine(() {
        mineFeedback = '+1';
        Timer(
          const Duration(milliseconds: 500),
          () => setState(() => mineFeedback = ''),
        );
      });
    }
    if (event.character == 'f') {
      world.openTable();
    }
    if (event.character == 'q') {
      world.plant();
    }
    if (event.character == 'Q') {
      world.chop();
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is RawKeyDownEvent) {
      world.closeTable();
    }
    if (event.character == 'e' && e == false) {
      e = true;
      invActive = !invActive;
    }
    for (EntityCell entityCell in toolbar) {
      if (event.logicalKey == entityCell.keybind && event is RawKeyDownEvent) {
        world.place(entityCell.item);
      }
    }

    return KeyEventResult.handled;
  }

  String mineFeedback = '';
  Map<int, Map<int, List<Offset>>> totalTables = {};
  int frames = 0;
  late Timer movement =
      Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (_) {
    if ((world.inv[wood] ?? 0) >= 100) {
      won = true;
    }
    if (!won) {
      frames++;
    }
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

  Recipe? selectedRecipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      world.screenWidth = constraints.maxWidth / 10;
      world.screenHeight = constraints.maxHeight / 10;
      double screenYPart(VerticalDirection dir) {
        switch (dir) {
          case VerticalDirection.up:
            return 0;
          case VerticalDirection.down:
            return (world.screenHeight * 10) - 150;
          case VerticalDirection.stay:
            return (world.screenHeight * 5) - 30;
        }
      }

      double screenXPart(HorizontalDirection dir) {
        switch (dir) {
          case HorizontalDirection.left:
            return 0;
          case HorizontalDirection.right:
            return (world.screenWidth * 10);
          case HorizontalDirection.stay:
            return (world.screenWidth * 5);
        }
      }

      Map<Direction, List<Entity>> farawayMarkers = {};
      for (MapEntry<IntegerOffset, Entity> entity in world.entities.entries
          .toList()
          .where(
            (element) =>
                !(element.key.x == world.roomX &&
                    element.key.y == world.roomY) &&
                element.value.isNotEmpty,
          )
          .expand((element) =>
              element.value.map((e) => MapEntry(element.key, e)))) {
        Direction dir = Direction(
            entity.key.y < world.roomY
                ? VerticalDirection.up
                : entity.key.y > world.roomY
                    ? VerticalDirection.down
                    : VerticalDirection.stay,
            entity.key.x < world.roomX
                ? HorizontalDirection.left
                : entity.key.x > world.roomX
                    ? HorizontalDirection.right
                    : HorizontalDirection.stay);
        farawayMarkers[dir] ??= [];
        farawayMarkers[dir]!.add(entity.value);
      }
      return FocusScope(
        onKey: _handleKeyPress,
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Center(
              child: parseInlinedIcons(
                group(
                        world.entities.values.expand((element) => element).toList(),
                        (Entity entity) => entity.type)
                    .entries
                    .map((e) => '${e.value.length}x{entity.${e.key.name}}')
                    .join(' '),
              ),
            ),
          ),
          body: ScreenFiller(
            child: Container(
              color: stoneColor,
              child: Stack(
                children: [
                  if (room.baseOre == dirt)
                    Positioned.fill(
                      child: Image.asset(
                        'images/dirt.png',
                        repeat: ImageRepeat.repeat,
                        scale: 1 / 3,
                        opacity: const AlwaysStoppedAnimation(.5),
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  if (room.ore != null && debugMode)
                    Positioned(
                      left: room.orePos.dx * 10,
                      top: room.orePos.dy * 10,
                      child: Container(
                        width: 150,
                        height: 150,
                        color: Colors.green,
                      ),
                    ),
                  if (room.ore != null)
                    Positioned(
                      left: room.orePos.dx * 10,
                      top: room.orePos.dy * 10,
                      child: renderItem(
                        room.ore,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  Center(child: Text(won ? 'You Won' : '')),
                  for (Entity entity in world
                          .entities[IntegerOffset(world.roomX, world.roomY)] ??
                      []) ...[
                    if (debugMode)
                      Positioned(
                        left: entity.dx * 10,
                        top: entity.dy * 10,
                        child: Container(
                          color: Colors.green,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    Positioned(
                      left: entity.dx * 10,
                      top: entity.dy * 10,
                      child: renderEntity(
                        entity.type,
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                  for (MapEntry<Direction, List<Entity>> entity
                      in farawayMarkers.entries)
                    Positioned(
                      left: screenXPart(entity.key.horizontal) -
                          (entity.key.horizontal == HorizontalDirection.right
                              ? 30 * entity.value.length
                              : entity.key.horizontal ==
                                      HorizontalDirection.left
                                  ? 0
                                  : 15 * entity.value.length),
                      top: screenYPart(entity.key.vertical),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (Entity entity2 in entity.value)
                            renderEntity(entity2.type,
                                width: 30, height: 30, ghost: true),
                        ],
                      ),
                    ),
                  Positioned(
                    left: world.playerX / .1,
                    top: world.playerY / .1,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.green),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0;
                                    i < world.recipes.length;
                                    i++,) ...[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (MapEntry<String, int> item
                                          in world.recipes[i].recipe.entries)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            renderItem(item.key,
                                                width: 30, height: 30),
                                            Text(
                                              '${world.inv[item.key] ?? 0}/${item.value}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            )
                                          ],
                                        ),
                                      TextButton(
                                        child: renderItem(
                                            world.recipes[i].result,
                                            width: 30,
                                            height: 30),
                                        onPressed: () {
                                          selectedRecipe = world.recipes[i];
                                        },
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: selectedRecipe == null
                                      ? null
                                      : () {
                                          setState(() {
                                            if (world.craft(selectedRecipe!)) {
                                              selectedRecipe = null;
                                            }
                                          });
                                        },
                                  child: renderItem(
                                    selectedRecipe?.result,
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
                                      renderItem(
                                        a,
                                        width: 30,
                                        height: 30,
                                      ),
                                      Text(
                                        '${world.inv[a]}',
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
          bottomNavigationBar: Container(
            color: Colors.black,
            child: Row(
              children: [
                for (EntityCell cell in toolbar)
                  TextButton(
                    child: Column(
                      children: [
                        Center(
                          child: renderItem(cell.item, width: 30, height: 30),
                        ),
                        parseInlinedIcons(
                          '${world.inv[cell.item] ?? 0} x ${world.describePlaced(cell.item)} (shortcut: ${cell.keybind.keyLabel})',
                        ),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                    onPressed: (world.inv[cell.item] ?? 0) == 0
                        ? null
                        : () {
                            world.place(cell.item);
                          },
                  )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
          ),
        ),
      );
    });
  }
}

class EntityCell {
  final LogicalKeyboardKey keybind;

  final String item;

  const EntityCell(this.item, this.keybind);
}

class ItemDropdown extends StatelessWidget {
  const ItemDropdown({
    Key? key,
    required this.inv,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final Map<String, int> inv;
  final String? value;
  final void Function(String? x) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      items: (inv.keys.cast<String?>().followedBy(const [null]))
          .map(
            (String? e) => DropdownMenuItem(
              child: renderItem(
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

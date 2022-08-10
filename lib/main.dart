// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Table, Positioned;
import 'package:flutter/material.dart' as flutter show Positioned;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'core.dart';
import 'estd.dart';
import 'images.dart';
import 'logic.dart';

const bool debugMode = false;
void main() {
  runApp(
    const MyApp(),
  );
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
  late final World world = World(Random());
  late final List<Player> players = [
    world.newPlayer(
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
        LogicalKeyboardKey.tab,
      ),
    ),
    world.newPlayer(
      KeybindSet(
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.keyJ,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyO,
        LogicalKeyboardKey.semicolon,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.period,
        LogicalKeyboardKey.slash,
        LogicalKeyboardKey.keyY,
      ),
    ),
  ];

  static const List<EntityCell> toolbar = [
    EntityCell(wood, LogicalKeyboardKey.digit1),
    EntityCell(robot, LogicalKeyboardKey.digit2),
    EntityCell(miner, LogicalKeyboardKey.digit3),
    EntityCell(dirt, LogicalKeyboardKey.digit4),
  ];

  static LogicalKeyboardKey gpu(Player p1) {
    return p1.keybinds.up;
  }

  static void spu(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.up = p2;
  }

  static LogicalKeyboardKey gpd(Player p1) {
    return p1.keybinds.down;
  }

  static void spd(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.down = p2;
  }

  static LogicalKeyboardKey gpl(Player p1) {
    return p1.keybinds.left;
  }

  static void spl(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.left = p2;
  }

  static LogicalKeyboardKey gpr(Player p1) {
    return p1.keybinds.right;
  }

  static void spr(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.right = p2;
  }

  static LogicalKeyboardKey gpi(Player p1) {
    return p1.keybinds.inventory;
  }

  static void spi(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.inventory = p2;
  }

  static LogicalKeyboardKey gpot(Player p1) {
    return p1.keybinds.openTable;
  }

  static void spot(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.openTable = p2;
  }

  static LogicalKeyboardKey getPlayerPlant(Player p1) {
    return p1.keybinds.plant;
  }

  static void setPlayerPlant(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.plant = p2;
  }

  static LogicalKeyboardKey gpm(Player p1) {
    return p1.keybinds.mine;
  }

  static void spm(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.mine = p2;
  }

  static LogicalKeyboardKey getPlayerPlace(Player p1) {
    return p1.keybinds.placePrefix;
  }

  static void setPlayerPlace(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.placePrefix = p2;
  }

  static LogicalKeyboardKey gpoc(Player p1) {
    return p1.keybinds.openControlsDialog;
  }

  static void spoc(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.openControlsDialog = p2;
  }

  static const List<Control> controls = [
    Control(
      'Move up',
      'up',
      gpu,
      spu,
    ),
    Control(
      'Move down',
      'down',
      gpd,
      spd,
    ),
    Control(
      'Move left',
      'left',
      gpl,
      spl,
    ),
    Control(
      'Move right',
      'right',
      gpr,
      spr,
    ),
    Control(
      'Toggle inventory',
      'inventory',
      gpi,
      spi,
    ),
    Control(
      'Open/Close {entity.table}',
      'openTable',
      gpot,
      spot,
    ),
    Control(
      'Plant {entity.sapling} / Chop {entity.tree} (add <shift>)',
      'plant',
      getPlayerPlant,
      setPlayerPlant,
    ),
    Control(
      'Mine ore',
      'mine',
      gpm,
      spm,
    ),
    Control(
      'Place something',
      'placePrefix',
      getPlayerPlace,
      setPlayerPlace,
    ),
    Control(
      'Toggle this menu',
      'openControlsDialog',
      gpoc,
      spoc,
    ),
  ];

  Control? changingControl;
  Player? controlChanger;

  String get tutorial {
    return '';
  }

  bool won = false;

  Player? placer;
  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (changingControl != null) {
      if (event is RawKeyUpEvent) {
        changingControl!.setValue(controlChanger!, event.logicalKey);
        changingControl = null;
        controlChanger = null;
      }
      return KeyEventResult.handled;
    }
    if (placer != null) {
      for (EntityCell entityCell in toolbar) {
        if (event.logicalKey == entityCell.keybind &&
            event is RawKeyDownEvent) {
          world.place(placer!, entityCell.item);
        }
      }
    }
    for (Player rplayer in world.entities.values
        .expand((element) => element)
        .whereType<Player>()
        .toList()) {
      KeybindSet player = rplayer.keybinds;
      if (event.logicalKey == player.up) {
        if (event is RawKeyDownEvent && event.repeat == false) {
          world.up(rplayer);
        }
        if (event is RawKeyUpEvent) {
          world.down(rplayer);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == player.down) {
        if (event is RawKeyDownEvent && event.repeat == false) {
          world.down(rplayer);
        }
        if (event is RawKeyUpEvent) {
          world.up(rplayer);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == player.right) {
        if (event is RawKeyDownEvent && event.repeat == false) {
          world.right(rplayer);
        }
        if (event is RawKeyUpEvent) {
          world.left(rplayer);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == player.left) {
        if (event is RawKeyDownEvent && event.repeat == false) {
          world.left(rplayer);
        }
        if (event is RawKeyUpEvent) {
          world.right(rplayer);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == player.mine && event is RawKeyDownEvent) {
        world.mine(rplayer, () {
          mineFeedback = '+1';
          Timer(
            const Duration(milliseconds: 500),
            () => setState(() => mineFeedback = ''),
          );
        });
      }
      if (event.logicalKey == player.openTable && event is RawKeyDownEvent) {
        world.toggleTable(rplayer);
      }
      if (event.logicalKey == player.plant && event is RawKeyDownEvent) {
        if (event.isShiftPressed) {
          world.chop(rplayer);
        } else {
          world.plant(rplayer);
        }
      }
      if (event.logicalKey == player.inventory &&
          event is RawKeyDownEvent &&
          event.repeat == false) {
        invToggle(rplayer);
      }
      if (event.logicalKey == player.placePrefix &&
          event is RawKeyDownEvent &&
          event.repeat == false) {
        placer = rplayer;
      }
      if (event.logicalKey == player.openControlsDialog &&
          event is RawKeyDownEvent &&
          event.repeat == false) {
        pss[rplayer.code]!.controlsDialogActive =
            !pss[rplayer.code]!.controlsDialogActive;
      }
    }

    return KeyEventResult.handled;
  }

  String mineFeedback = '';
  Map<int, Map<int, List<Offset>>> totalTables = {};
  int frames = 0;
  late Timer movement =
      Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (_) {
    for (Player player in world.entities.values
        .expand((element) => element)
        .whereType<Player>()) {
      if ((player.inv[wood] ?? 0) >= 100) {
        won = true;
      }
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

  Widget playerScreen(Player player) {
    Map<Direction, List<Entity>> farawayMarkers = {};
    for (MapEntry<IntegerOffset, Entity> entity in world.entities.entries
        .toList()
        .where(
          (element) =>
              !(element.key.x == player.room.x &&
                  element.key.y == player.room.y) &&
              element.value.isNotEmpty,
        )
        .expand(
            (element) => element.value.map((e) => MapEntry(element.key, e)))) {
      Direction dir = Direction(
          entity.key.y < player.room.y
              ? VerticalDirection.up
              : entity.key.y > player.room.y
                  ? VerticalDirection.down
                  : VerticalDirection.stay,
          entity.key.x < player.room.x
              ? HorizontalDirection.left
              : entity.key.x > player.room.x
                  ? HorizontalDirection.right
                  : HorizontalDirection.stay);
      farawayMarkers[dir] ??= [];
      farawayMarkers[dir]!.add(entity.value);
    }
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

    return Expanded(
      child: Container(
        color: stoneColor,
        child: Stack(
          children: [
            if (world.roomAt(player.room).baseOre == dirt)
              flutter.Positioned.fill(
                child: Image.asset(
                  'images/dirt.png',
                  repeat: ImageRepeat.repeat,
                  scale: 1 / 3,
                  opacity: const AlwaysStoppedAnimation(.5),
                  filterQuality: FilterQuality.none,
                ),
              ),
            if (world.roomAt(player.room).ore != null && debugMode)
              flutter.Positioned(
                left: world.roomAt(player.room).orePos.dx * 10,
                top: world.roomAt(player.room).orePos.dy * 10,
                child: Container(
                  width: 150,
                  height: 150,
                  color: Colors.green,
                ),
              ),
            if (world.roomAt(player.room).ore != null)
              flutter.Positioned(
                left: world.roomAt(player.room).orePos.dx * 10,
                top: world.roomAt(player.room).orePos.dy * 10,
                child: renderItem(
                  world.roomAt(player.room).ore,
                  width: 150,
                  height: 150,
                ),
              ),
            Center(child: Text(won ? 'You Won' : '')),
            for (Entity entity in world
                    .entities[IntegerOffset(player.room.x, player.room.y)] ??
                []) ...[
              if (debugMode)
                flutter.Positioned(
                  left: entity.dx * 10,
                  top: entity.dy * 10,
                  child: Container(
                    color: Colors.green,
                    width: 30,
                    height: 30,
                  ),
                ),
              flutter.Positioned(
                left: entity.dx * 10,
                top: entity.dy * 10,
                child: renderEntity(
                  entity.type,
                  width: 30,
                  height: 30,
                  isMe: entity.code == player.code,
                ),
              ),
            ],
            for (MapEntry<Direction, List<Entity>> entity
                in farawayMarkers.entries)
              flutter.Positioned(
                left: screenXPart(entity.key.horizontal) -
                    (entity.key.horizontal == HorizontalDirection.right
                        ? 30 * entity.value.length
                        : entity.key.horizontal == HorizontalDirection.left
                            ? 0
                            : 15 * entity.value.length),
                top: screenYPart(entity.key.vertical),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (Entity entity2 in entity.value)
                      renderEntity(
                        entity2.type,
                        width: 30,
                        height: 30,
                        ghost: true,
                        isMe: entity2.code == player.code,
                      ),
                  ],
                ),
              ),
            if (player.tableOpen != null)
              Center(
                child: Container(
                  color: Colors.black,
                  width: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Crafting",
                        style: TextStyle(color: Colors.white),
                      ),
                      const Divider(
                        color: Colors.white,
                      ),
                      for (int i = 0; i < world.recipes.length; i++,) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (MapEntry<String, int> item
                                in world.recipes[i].recipe.entries)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  renderItem(item.key, width: 30, height: 30),
                                  Text(
                                    '${player.inv[item.key] ?? 0}/${item.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                ],
                              ),
                            TextButton(
                              child: renderItem(world.recipes[i].result,
                                  width: 30, height: 30),
                              onPressed: () {
                                world.craft(player, world.recipes[i]);
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
                ),
              ),
            if (pss[player.code]!.inventoryActive)
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.black,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const <Widget>[
                            Text(
                              "Inventory",
                              style: TextStyle(color: Colors.white),
                            ),
                            Divider(
                              color: Colors.white,
                            ),
                          ] +
                          player.inv.keys
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
                                      '${player.inv[a]}',
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
            if (pss[player.code]!.controlsDialogActive)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: controls
                            .map((e) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ControlSetting(player, e, s: this),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            Center(child: Text(mineFeedback)),
            TextButton(
              onPressed: () => controlsDialogToggle(player),
              child: const Text(
                'Change controls',
                style: TextStyle(color: Colors.yellow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      world.screenWidth = constraints.maxWidth / (10 * players.length);
      world.screenHeight = constraints.maxHeight / 10;
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
          // */
          body: ScreenFiller(
            child: Row(children: [
              for (Player p in players) ...[
                playerScreen(p),
                Container(
                  width: 10,
                  color: Colors.brown,
                )
              ],
            ]),
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
                          '${world.describePlaced(cell.item)} (shortcut: ${cell.keybind.keyLabel})',
                        ),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                    onPressed: (placer?.inv[cell.item] ?? 0) == 0
                        ? null
                        : () {
                            if (placer != null) {
                              world.place(placer!, cell.item);
                            }
                          },
                  )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
          ),
          // */
        ),
      );
    });
  }

  late final Map<int, PlayerScreenState> pss = Map.fromEntries(
      players.map((e) => MapEntry(e.code, PlayerScreenState(false, false))));

  void invToggle(Player rplayer) {
    pss[rplayer.code]!.inventoryActive = !pss[rplayer.code]!.inventoryActive;
  }

  void controlsDialogToggle(Player rplayer) {
    pss[rplayer.code]!.controlsDialogActive =
        !pss[rplayer.code]!.controlsDialogActive;
  }
}

class ControlSetting extends StatefulWidget {
  const ControlSetting(this.p, this.c, {Key? key, required this.s})
      : super(key: key);
  final Control c;
  final Player p;
  final _MyHomePageState s;

  @override
  State<ControlSetting> createState() => _ControlSettingState();
}

class _ControlSettingState extends State<ControlSetting> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      parseInlinedIcons(widget.c.readableName),
      Text(
        widget.c.internalName,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      TextButton(
        child: parseInlinedIcons(widget.s.changingControl != widget.c ||
                widget.s.controlChanger?.code != widget.p.code
            ? widget.c.getValue(widget.p).keyLabel
            : 'Press any key to change'),
        onPressed: () {
          widget.s.changingControl = widget.c;
          widget.s.controlChanger = widget.p;
          setState(() {});
        },
      ),
    ]);
  }
}

class Control {
  final String readableName;
  final String internalName;
  final LogicalKeyboardKey Function(Player) getValue;
  final void Function(Player, LogicalKeyboardKey) setValue;

  const Control(
      this.readableName, this.internalName, this.getValue, this.setValue);
}

class PlayerScreenState {
  bool controlsDialogActive;
  bool inventoryActive;

  PlayerScreenState(this.controlsDialogActive, this.inventoryActive);
}

class EntityCell {
  final LogicalKeyboardKey keybind;

  final String item;

  const EntityCell(this.item, this.keybind);
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

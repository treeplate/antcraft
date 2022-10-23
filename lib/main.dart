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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum MenuState { p1, p2, ready }

class _MyAppState extends State<MyApp> {
  MenuState menuState = MenuState.p1;

  late final bool cgisOn;
  late final bool multiplayer;

  @override
  Widget build(BuildContext context) {
    switch (menuState) {
      case MenuState.ready:
        return MaterialApp(
          home: MyHomePage(cgisOn: cgisOn, multiplayer: multiplayer),
        );
      case MenuState.p1:
        return MaterialApp(
          home: Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    menuState = MenuState.p2;
                    cgisOn = false;
                  });
                },
                child: const Text('CGIS Off'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    menuState = MenuState.p2;
                    cgisOn = true;
                  });
                },
                child: const Text('CGIS On'),
              ),
            ],
          ),
        );
      case MenuState.p2:
        return MaterialApp(
          home: Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    menuState = MenuState.ready;
                    multiplayer = true;
                  });
                },
                child: const Text('2 Player (local splitscreen)'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    menuState = MenuState.ready;
                    multiplayer = false;
                  });
                },
                child: const Text('Singleplayer'),
              ),
            ],
          ),
        );
    }
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
  final bool cgisOn;
  final bool multiplayer;

  const MyHomePage({Key? key, required this.cgisOn, required this.multiplayer})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController cA = TextEditingController(text: 'main');
  TextEditingController cB = TextEditingController(text: 'partner');

  late final World world = World(Random(), widget.cgisOn);

  Entity? yh; // yellow highlight
  Entity? gh; // green highlight

  @override
  void initState() {
    scheduleMicrotask(() {
      if (world.cgisMenuActive) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  color: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "CGIS Config",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: cA,
                          onChanged: (x) {
                            cgisName = x;
                          },
                          decoration: const InputDecoration(
                            labelText: 'name',
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: cB,
                          onChanged: (x) {
                            cgisPartner = x;
                          },
                          decoration: const InputDecoration(
                            labelText: 'partner',
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            world.registerCGIS(
                                cgisName, cgisPartner, players.first);
                          },
                          child: const Text('Submit'),
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
      }
    });
    super.initState();
  }

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
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.tab,
      ),
    ),
    if (widget.multiplayer)
      world.newPlayer(
        KeybindSet(
          LogicalKeyboardKey.keyI,
          LogicalKeyboardKey.keyK,
          LogicalKeyboardKey.keyJ,
          LogicalKeyboardKey.keyL,
          LogicalKeyboardKey.keyO,
          LogicalKeyboardKey.semicolon,
          LogicalKeyboardKey.keyU,
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
    EntityCell(box, LogicalKeyboardKey.digit5),
    EntityCell(planter, LogicalKeyboardKey.digit6),
    EntityCell(chopper, LogicalKeyboardKey.digit7),
    EntityCell(antenna, LogicalKeyboardKey.digit8),
  ];

  String cgisName = 'default';
  String cgisPartner = 'default2';

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
    return p1.keybinds.interact;
  }

  static void spot(Player p1, LogicalKeyboardKey p2) {
    p1.keybinds.interact = p2;
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
      'Open inventory / Close menu',
      'inventory',
      gpi,
      spi,
    ),
    Control(
      'Interact',
      'interact',
      gpot,
      spot,
    ),
    Control(
      'Plant {entity.sapling}',
      'plant',
      getPlayerPlant,
      setPlayerPlant,
    ),
    Control(
      'Mine ore / Chop tree',
      'mine',
      gpm,
      spm,
    ),
    Control(
      'Toggle this menu',
      'openControlsDialog',
      gpoc,
      spoc,
    ),
  ];
  final Advancement collectWoodAdv = Advancement(
    'First Steps',
    'Collect your first {$wood} (press the open/close inventory key [typically \'e\'] to see it there).',
  );
  final Advancement placeAdv = Advancement(
    'Ready to Craft',
    'Place an item (Press the {$wood} icon at the bottom of the screen to place a {$wood}, or other icons if you have the respective item. You can also use the number keys.).',
  );
  final Advancement mineAdv = Advancement(
    'Diggy Diggy',
    'Mine (typically the \'v\' key). You get what\'s under you.',
  );
  final Advancement craftAdv = Advancement(
    'Cool Machine',
    'Craft an item (Press the open/close {entity.table} key [typically \'f\'] and click on one of the recipes if you have enough items for it).',
  );
  final Advancement collectStoredAdv = Advancement(
    'Even Cooler',
    'Walk on top of a {entity.robot} or {entity.miner} that has mined (which it does every second) / collected {$wood}. This gives you those materials.',
  );
  final Advancement plantAdv = Advancement(
    'Terraforming',
    'Plant a {entity.sapling} (typically the \'q\' key). You must plant on a {$dirt} floor or on a {entity.dirt} you placed down. This costs 3 {$wood}.',
  );
  final Advancement chopAdv = Advancement(
    'Logging',
    'Chop down a {entity.tree} (using the mine key). You get 4 {$wood} for that.',
  );
  final Advancement targetPlanter = Advancement(
    'Configuration',
    'Use a {$antenna} to change the destination of a {$robot} to a {$planter}',
  );
  final Advancement autoChopAdv = Advancement(
    'Automation',
    'Automatically plant and chop a {entity.tree}',
  );
  late final List<Advancement> advancements = [
    collectWoodAdv,
    placeAdv,
    mineAdv,
    craftAdv,
    collectStoredAdv,
    plantAdv,
    chopAdv,
    targetPlanter,
    autoChopAdv,
  ];

  Control? changingControl;
  Player? controlChanger;

  String get tutorial {
    return '';
  }

  bool won = false;

  Player? placer;
  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (changingControl != null) {
      if (event is KeyUpEvent) {
        changingControl!.setValue(controlChanger!, event.logicalKey);
        changingControl = null;
        controlChanger = null;
      }
      return KeyEventResult.handled;
    }
    if (placer != null) {
      for (EntityCell entityCell in toolbar) {
        if (event.logicalKey == entityCell.keybind && event is KeyDownEvent) {
          if (world.place(placer!, entityCell.item)) {
            pss[placer!.code]!.advancementsAcheived.add(placeAdv);
          }
        }
      }
    }
    for (Player rplayer in world.entities.values
        .expand((element) => element)
        .whereType<Player>()
        .toList()) {
      KeybindSet player = rplayer.keybinds;
      if (event.logicalKey == player.up) {
        if (event is KeyDownEvent) {
          world.up(rplayer);
          placer = rplayer;
        }
        if (event is KeyUpEvent) {
          world.down(rplayer);
          placer = rplayer;
        }
      }
      if (event.logicalKey == player.down) {
        if (event is KeyDownEvent) {
          world.down(rplayer);
          placer = rplayer;
        }
        if (event is KeyUpEvent) {
          world.up(rplayer);
          placer = rplayer;
        }
      }
      if (event.logicalKey == player.right) {
        if (event is KeyDownEvent) {
          world.right(rplayer);
          placer = rplayer;
        }
        if (event is KeyUpEvent) {
          world.left(rplayer);
          placer = rplayer;
        }
      }
      if (event.logicalKey == player.left) {
        if (event is KeyDownEvent) {
          world.left(rplayer);
          placer = rplayer;
        }
        if (event is KeyUpEvent) {
          world.right(rplayer);
          placer = rplayer;
        }
      }
      if (event.logicalKey == player.mine && event is KeyDownEvent) {
        if (world.chop(rplayer)) {
          pss[rplayer.code]!.advancementsAcheived.add(chopAdv);
        }
        placer = rplayer;
        world.mine(rplayer, () {
          mineFeedback = '+1';
          Timer(
            const Duration(milliseconds: 500),
            () => setState(() => mineFeedback = ''),
          );
          pss[rplayer.code]!.advancementsAcheived.add(mineAdv);
        });
        placer = rplayer;
      }
      if (event.logicalKey == player.interact && event is KeyDownEvent) {
        world.interact(rplayer);
        placer = rplayer;
      }
      if (event.logicalKey == player.plant && event is KeyDownEvent) {
        if (world.plant(rplayer)) {
          pss[rplayer.code]!.advancementsAcheived.add(plantAdv);
        }
        placer = rplayer;
      }
      if (event.logicalKey == player.inventory && event is KeyDownEvent) {
        invToggle(rplayer);
        placer = rplayer;
      }
      if (event.logicalKey == player.openControlsDialog &&
          event is KeyDownEvent) {
        pss[rplayer.code]!.controlsDialogActive =
            !pss[rplayer.code]!.controlsDialogActive;
        placer = rplayer;
      }
      if (event.logicalKey == player.inventory &&
          event is KeyDownEvent &&
          !pss[rplayer.code]!.inventoryActive) {
        pss[rplayer.code]!.controlsDialogActive = false;
        pss[rplayer.code]!.advancementsDialogActive = false;
        pss[rplayer.code]!.inventoryActive = false;
        world.interact(rplayer);
        placer = rplayer;
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
      if (player.hasItem(wood, 1)) {
        pss[player.code]!.advancementsAcheived.add(collectWoodAdv);
      }
      if (player.collectedStored) {
        pss[player.code]!.advancementsAcheived.add(collectStoredAdv);
      }
      if (pss[player.code]!.advancementsAcheived.length ==
          advancements.length) {
        won = true;
      }
    }
    if (!won) {
      frames++;
    }
    setState(() {
      world.tick(() {
        pss.forEach((key, value) {
          value.advancementsAcheived.add(autoChopAdv);
        });
      });
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
            Center(
              child: Text(
                won
                    ? 'You Won in $frames frames (or about ${() {
                        int millis = frames * (1000 ~/ 60);
                        int secs = millis ~/ 1000;
                        int mins = secs ~/ 60;
                        int nms = secs - mins * 60;
                        int nsm = millis - secs * 1000;
                        return '$mins:${nms.toString().padLeft(2, '0')}.${nsm.toString().padLeft(3, '0')}';
                      }()})'
                    : 'about ${() {
                        int millis = frames * (1000 ~/ 60);
                        int secs = millis ~/ 1000;
                        int mins = secs ~/ 60;
                        int nms = secs - mins * 60;
                        int nsm = millis - secs * 1000;
                        return '$mins:${nms.toString().padLeft(2, '0')}.${nsm.toString().padLeft(3, '0')}';
                      }()}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
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
                  borderColor: gh?.code == entity.code
                      ? Colors.lightGreen
                      : yh?.code == entity.code
                          ? Colors.lime
                          : Colors.transparent,
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
                        borderColor: gh?.code == entity2.code
                            ? Colors.lightGreen
                            : yh?.code == entity2.code
                                ? Colors.lime
                                : Colors.transparent,
                        isMe: entity2.code == player.code,
                      ),
                  ],
                ),
              ),
            if (player.interacting is Box)
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InventoryWidget(
                      inventory: player.inv,
                      callback: (p0) {
                        world.store(player, p0);
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    InventoryWidget(
                      inventory: (player.interacting as Box).inv,
                      callback: (p0) {
                        world.take(player, p0);
                      },
                    ),
                  ],
                ),
              ),
            if (player.interacting is Antenna)
              Center(
                child: Container(
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[const Text('Robots')] +
                        world.entities.entries
                            .expand((element) => element.value)
                            .whereType<Robot>()
                            .map(
                              (e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  parseInlinedIcons(
                                    '{$robot}id ${e.code} destination:',
                                  ),
                                  DropdownButton(
                                    value: e.target,
                                    items: world.entities.entries
                                        .expand((element) => element.value)
                                        .map(
                                          (e2) => DropdownMenuItem(
                                            value: (e.target as Entity).code ==
                                                    e2.code
                                                ? e.target
                                                : e2,
                                            child: parseInlinedIcons(
                                                '{entity.${e2.type.name}}id ${e2.code}'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (e2) {
                                      world.assignTo(player, e, e2 as Entity);
                                      if (e2 is Planter) {
                                        pss[player.code]!
                                            .advancementsAcheived
                                            .add(targetPlanter);
                                      }
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      gh = e;
                                      yh = e.target is Entity
                                          ? e.target as Entity
                                          : null;
                                    },
                                    child: Text(gh == e
                                        ? 'Highlight destination if it changed'
                                        : 'Highlight'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      world.toggleExploreForWood(player, e);
                                    },
                                    child: parseInlinedIcons(e.exploreForWood
                                        ? 'Don\'t exit room to find {$wood}'
                                        : 'Exit room to find {$wood} if there isn\'t any in the current room'),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            if (player.interacting is Table)
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
                      for (int i = 0; i < World.recipes.length; i++,) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (MapEntry<String, int> item
                                in World.recipes[i].recipe.entries)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  renderItem(item.key, width: 30, height: 30),
                                  Text(
                                    '${player.inv.where((element) => element.item == item.key).fold<int>(0, (p, n) => p + n.count)}/${item.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                ],
                              ),
                            TextButton(
                              child: renderItem(World.recipes[i].result,
                                  width: 30, height: 30),
                              onPressed: () {
                                world.craft(player, World.recipes[i]);
                                pss[player.code]!
                                    .advancementsAcheived
                                    .add(craftAdv);
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
                child: InventoryWidget(
                  inventory: player.inv,
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
            if (pss[player.code]!.advancementsDialogActive)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: advancements
                            .map((e) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: AdvancementDisplay(
                                      pss[player.code]!
                                          .advancementsAcheived
                                          .contains(e),
                                      e),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            Center(child: Text(mineFeedback)),
            Row(
              children: [
                TextButton(
                  onPressed: () => controlsDialogToggle(player),
                  child: const Text(
                    'Change controls',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ),
                TextButton(
                  onPressed: () => advancementsDialogToggle(player),
                  child: const Text(
                    'Show advancements',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (conext, BoxConstraints constraints) {
      world.screenWidth = constraints.maxWidth / (10 * players.length);
      world.screenHeight = constraints.maxHeight / 10;
      return Focus(
        onKeyEvent: _handleKeyPress,
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
                          '${placer?.inv.where((element) => element.item == cell.item).fold<int>(0, (p, n) => p + n.count) ?? 'N/A'}',
                        ),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                    onPressed: !(placer?.hasItem(cell.item, 1) ?? false)
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

  late final Map<int, PlayerScreenState> pss = Map.fromEntries(players
      .map((e) => MapEntry(e.code, PlayerScreenState(false, false, false))));

  void invToggle(Player rplayer) {
    pss[rplayer.code]!.inventoryActive = !pss[rplayer.code]!.inventoryActive;
  }

  void controlsDialogToggle(Player rplayer) {
    pss[rplayer.code]!.controlsDialogActive =
        !pss[rplayer.code]!.controlsDialogActive;
  }

  void advancementsDialogToggle(Player rplayer) {
    pss[rplayer.code]!.advancementsDialogActive =
        !pss[rplayer.code]!.advancementsDialogActive;
  }
}

class AdvancementDisplay extends StatelessWidget {
  final Advancement advancement;

  final bool acheived;

  const AdvancementDisplay(this.acheived, this.advancement, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: acheived ? Colors.green : Colors.grey,
      child: Row(children: [
        parseInlinedIcons(advancement.name, 20),
        const SizedBox(
          width: 5,
          height: 20,
        ),
        Container(
          width: 5,
          height: 20,
          color: Colors.white,
        ),
        const SizedBox(
          width: 5,
          height: 20,
        ),
        parseInlinedIcons(advancement.description, 20),
      ]),
    );
  }
}

class Advancement {
  final String name;
  final String description;

  Advancement(this.name, this.description);
}

class ControlSetting extends StatelessWidget {
  const ControlSetting(this.p, this.c, {Key? key, required this.s})
      : super(key: key);
  final Control c;
  final Player p;
  final _MyHomePageState s;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      parseInlinedIcons(c.readableName),
      Text(
        c.internalName,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      TextButton(
        child: parseInlinedIcons(
            s.changingControl != c || s.controlChanger?.code != p.code
                ? c.getValue(p).keyLabel
                : 'Press any key to change'),
        onPressed: () {
          s.changingControl = c;
          s.controlChanger = p;
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
  bool advancementsDialogActive;

  Set<Advancement> advancementsAcheived = {};

  PlayerScreenState(
    this.controlsDialogActive,
    this.inventoryActive,
    this.advancementsDialogActive,
  );
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

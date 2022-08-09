import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'core.dart';

class World {
  final Map<IntegerOffset, Map<EntityType, List<Entity>>> _entitiesByType = {};

  final List<Recipe> recipes = const [
    Recipe({iron: 1}, robot),
    Recipe({wood: 1, iron: 1}, miner),
  ];

  World(this.random);
  double screenWidth = 10;
  double screenHeight = 10;
  final Map<int, Map<int, Room>> _rooms = {};
  final List<String> _ores = [iron];

  bool _recentMined = false;
  final int _cooldown = 2;
  final Random random;

  Map<IntegerOffset, Iterable<Entity>> get entities =>
      _entitiesByType.map<IntegerOffset, Iterable<Entity>>(
        (key, value) => MapEntry(
          key,
          value.values.expand((element) => element).map((e) => e.copy()),
        ),
      );

  Set<MapEntry<Offset, Entity>> _atOfType(int rx, int ry, EntityType type) {
    return _entitiesByType[IntegerOffset(rx, ry)]?[type]
            ?.map((e) => MapEntry(Offset(e.dx, e.dy), e))
            .toSet() ??
        {};
  }

  void left(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    player.xVel--;
  }

  void up(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    player.yVel--;
  }

  void down(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    player.yVel++;
  }

  void right(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    player.xVel++;
  }

  void mine(Player fakePlayer, VoidCallback callback) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    if (!_recentMined) {
      _recentMined = true;
      String ore = roomAt(player.room).oreAt(player.dx, player.dy);
      player.inv[ore] = (player.inv[ore] ?? 0) + 1;
      callback();
      Timer(
        Duration(seconds: _cooldown),
        () => _recentMined = false,
      );
    }
  }

  bool colliding(Offset aStart, double aSize, Offset bStart, double bSize) {
    Offset aEnd = Offset(aStart.dx + aSize, aStart.dy + aSize);
    Offset bEnd = Offset(bStart.dx + bSize, bStart.dy + bSize);
    if (aEnd.dx < bStart.dx) {
      return false;
    }
    if (bEnd.dx < aStart.dx) {
      return false;
    }
    if (aEnd.dy < bStart.dy) {
      return false;
    }
    if (bEnd.dy < aStart.dy) {
      return false;
    }
    return true;
  }

  void toggleTable(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    if (player.tableOpen == null) {
      for (MapEntry<Offset, Table> table
          in _atOfType(player.room.x, player.room.y, EntityType.table)
              .map((e) => MapEntry(e.key, e.value as Table))
              .cast()) {
        if (colliding(Offset(player.dx, player.dy), 3, table.key, 3)) {
          player.tableOpen = table.value;
        }
      }
    } else {
      player.tableOpen = null;
    }
  }

  bool place(Player fakePlayer, String type) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    if ((player.inv[type] ?? 0) > 0) {
      player.inv[type] = player.inv[type]! - 1;
      _placePrebuilt(
        placingTypes[type]!(player.dx / 1, player.dy / 1,
            IntegerOffset(player.room.x, player.room.y), player),
      );
      return true;
    }
    return false;
  }

  void _placePrebuilt(Entity entity) {
    IntegerOffset room = entity.room;
    _entitiesByType[room] ??= {};
    _entitiesByType[room]![entity.type] ??= [];
    _entitiesByType[room]![entity.type]!.add(entity);
  }

  void tick() {
    for (Player player in _entitiesByType.entries
        .map(
            (e) => MapEntry(e.key, e.value.values.expand((element) => element)))
        .expand((e) => e.value)
        .where((element) => element.type == EntityType.player)
        .cast()
        .toList()) {
      player.dx += player.xVel;
      player.dy += player.yVel;
      if (player.dx <= 0) {
        _entitiesByType[player.room]![player.type]!.remove(player);
        player.room = IntegerOffset(player.room.x - 1, player.room.y);
        _placePrebuilt(player);
        player.dx = (screenWidth - 4).roundToDouble();
      }
      if (player.dx >= (screenWidth - 3)) {
        _entitiesByType[player.room]![player.type]!.remove(player);
        player.room = IntegerOffset(player.room.x + 1, player.room.y);
        _placePrebuilt(player);
        player.dx = 1;
      }
      if (player.dy <= 0) {
        _entitiesByType[player.room]![player.type]!.remove(player);
        player.room = IntegerOffset(player.room.x, player.room.y - 1);
        _placePrebuilt(player);
        player.dy = (screenHeight - 4).roundToDouble();
      }
      if (player.dy >= (screenHeight - 3)) {
        _entitiesByType[player.room]![player.type]!.remove(player);
        player.room = IntegerOffset(player.room.x, player.room.y + 1);
        _placePrebuilt(player);
        player.dy = 1;
      }
      for (CollectibleWood pickup
          in _atOfType(player.room.x, player.room.y, EntityType.collectibleWood)
              .map((e) => e.value)
              .cast()
              .toList()) {
        if (colliding(
          Offset(player.dx, player.dy),
          3,
          Offset(pickup.dx, pickup.dy),
          3,
        )) {
          assert(_entitiesByType[IntegerOffset(player.room.x, player.room.y)]![
                  pickup.type]!
              .remove(pickup));

          player.inv[wood] = (player.inv[wood] ?? 0) + 1;
        }
      }
    }
    for (MapEntry<IntegerOffset, Entity> entity in _entitiesByType.entries
        .map((e) => MapEntry(
            e.key, e.value.values.expand((element) => element).toList()))
        .expand((e) => e.value.map((e2) => MapEntry(e.key, e2)))
        .toList()) {
      IntegerOffset entityRoom = entity.key;
      if (entity.value is Sapling) {
        Sapling sapling = entity.value as Sapling;
        sapling.growth--;
        if (sapling.growth == 0) {
          _entitiesByType[entityRoom]![sapling.type]!.remove(sapling);
          _placePrebuilt(Tree(sapling.dx, sapling.dy, entityRoom, null));
        }
      } else if (entity.value is Storer) {
        Storer storer = entity.value as Storer;
        if (_rooms[entityRoom.x] == null) {
          _rooms[entityRoom.x] = {};
        }
        if (_rooms[entityRoom.x]![entityRoom.y] == null) {
          genRoom(entityRoom);
        }
        Room room = _rooms[entityRoom.x]![entityRoom.y]!;
        for (Player player in _entitiesByType.entries
            .map((e) =>
                MapEntry(e.key, e.value.values.expand((element) => element)))
            .expand((e) => e.value.map((e2) => MapEntry(e.key, e2)))
            .cast()) {
          if (player.room.x == entityRoom.x &&
              player.room.y == entityRoom.y &&
              colliding(Offset(player.dx, player.dy), 3,
                  Offset(storer.dx, storer.dy), 3)) {
            player.inv[storer.storedItem(room)] =
                (player.inv[storer.storedItem(room)] ?? 0) + storer.inv;
            storer.inv = 0;
          }
        }

        if (storer is Miner) {
          Miner miner = storer;
          if (miner.inv < 10) {
            miner.cooldown--;
            if (miner.cooldown <= 0) {
              miner.inv++;
              miner.cooldown = 60;
            }
          }
        } else if (storer is Robot) {
          Robot robot = storer;
          for (CollectibleWood pickup in _atOfType(
                  entityRoom.x, entityRoom.y, EntityType.collectibleWood)
              .map((e) => e.value)
              .cast()) {
            if (robot.inv < 3) {
              if (colliding(
                Offset(robot.dx, robot.dy),
                3,
                Offset(pickup.dx, pickup.dy),
                3,
              )) {
                assert(
                  _entitiesByType[entityRoom]![pickup.type]!.remove(pickup),
                );
                assert(
                  robot.storedItem(_rooms[entityRoom.x]![entityRoom.y]!) ==
                      wood,
                );
                robot.inv++;
              }
            }
          }
          void hone(x, y) {
            if (robot.dx > x) {
              robot.dx--;
            } else if (robot.dx < x) {
              robot.dx++;
            } else if (robot.dy > y) {
              robot.dy--;
            } else if (robot.dy < y) {
              robot.dy++;
            } else {
              assert(false);
            }
          }

          void honeRoom(int x, int y) {
            if (entityRoom.x > x) {
              robot.dx--;
            } else if (entityRoom.x < x) {
              robot.dx++;
            } else if (entityRoom.y < y) {
              robot.dy++;
            } else if (entityRoom.y > y) {
              robot.dy--;
            } else {
              assert(false);
            }
          }

          if (robot.inv < 3) {
            if (_atOfType(
                    entityRoom.x, entityRoom.y, EntityType.collectibleWood)
                .isEmpty) {
              IntegerOffset woodRoom = nearestRoomWhere(
                  (Room r, IntegerOffset rPos) =>
                      _atOfType(rPos.x, rPos.y, EntityType.collectibleWood)
                          .isNotEmpty,
                  to: entityRoom);
              honeRoom(woodRoom.x, woodRoom.y);
            } else {
              hone(
                  _atOfType(entityRoom.x, entityRoom.y,
                          EntityType.collectibleWood)
                      .first
                      .value
                      .dx,
                  _atOfType(entityRoom.x, entityRoom.y,
                          EntityType.collectibleWood)
                      .first
                      .value
                      .dy);
            }
          } else {
            if (robot.target.room.x == entityRoom.x &&
                robot.target.room.y == entityRoom.y) {
              hone(
                robot.target.dx,
                robot.target.dy,
              );
            } else {
              honeRoom(robot.target.room.x, robot.target.room.y);
            }
          }
          if (robot.dx < 0) {
            assert(_entitiesByType[entityRoom]![robot.type]!.remove(robot));
            _placePrebuilt(
              robot
                ..dx = screenWidth.roundToDouble() - 1
                ..room = IntegerOffset(entityRoom.x - 1, entityRoom.y),
            );
            entityRoom = IntegerOffset(entityRoom.x - 1, entityRoom.y);
          }
          if (robot.dx > screenWidth) {
            assert(_entitiesByType[entityRoom]![robot.type]!.remove(robot));
            _placePrebuilt(
              robot
                ..dx = 1
                ..room = IntegerOffset(entityRoom.x + 1, entityRoom.y),
            );
            entityRoom = IntegerOffset(entityRoom.x + 1, entityRoom.y);
          }
          if (robot.dy < 0) {
            assert(_entitiesByType[entityRoom]![robot.type]!.remove(robot));
            _placePrebuilt(
              robot
                ..dy = screenHeight.roundToDouble() - 1
                ..room = IntegerOffset(entityRoom.x, entityRoom.y - 1),
            );
            entityRoom = IntegerOffset(entityRoom.x, entityRoom.y - 1);
          }
          if (robot.dy > screenHeight) {
            assert(_entitiesByType[entityRoom]![robot.type]!.remove(robot));
            _placePrebuilt(
              robot
                ..dy = 1
                ..room = IntegerOffset(entityRoom.x, entityRoom.y - 1),
            );
          }
        }
      }
    }
  }

  bool craft(Player fakePlayer, Recipe recipe) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    if (player.tableOpen != null) {
      for (MapEntry<String, int> item in recipe.recipe.entries) {
        if ((player.inv[item.key] ?? 0) < item.value) {
          return false;
        }
      }
      for (MapEntry<String, int> item in recipe.recipe.entries) {
        player.inv[item.key] = player.inv[item.key]! - item.value;
      }
      player.inv[recipe.result] = (player.inv[recipe.result] ?? 0) + 1;
      return true;
    }
    return false;
  }

  Room roomAt(IntegerOffset room) {
    if (_rooms[room.x] == null) {
      _rooms[room.x] = {};
    }
    if (_rooms[room.x]![room.y] == null) {
      genRoom(room);
    }
    return _rooms[room.x]![room.y]!;
  }

  String? numberToItem(int num) {
    switch (num) {
      case 0:
        return stone;
      case 1:
        return iron;
      case 2:
        return wood;
      case 3:
        return robot;
      case 4:
        return null;
      default:
        throw UnimplementedError();
    }
  }

  int itemToNumber(String? item) {
    switch (item) {
      case stone:
        return 0;
      case iron:
        return 1;
      case wood:
        return 2;
      case robot:
        return 3;
      case null:
        return 4;
      default:
        throw UnimplementedError();
    }
  }

  IntegerOffset nearestRoomWhere(bool Function(Room r, IntegerOffset rPos) test,
      {required IntegerOffset to}) {
    if (test(_rooms[to.x]![to.y]!, to)) {
      return to;
    }
    return IntegerOffset(to.x, to.y - 1);
  }

  String describePlaced(String item) {
    if (item == wood) {
      return 'Crafing Table';
    }
    if (item == robot) {
      return '{$wood}Collector';
    }
    if (item == miner) {
      return 'Ore Miner';
    }
    if (item == dirt) {
      return 'Dirt';
    }
    return 'Unknown placeable $item';
  }

  void genRoom(IntegerOffset room) {
    _rooms[room.x]![room.y] = Room(
      (_ores..shuffle()).first,
      Offset(
        (random.nextDouble() * (screenWidth - 3)).roundToDouble(),
        (random.nextDouble() * (screenHeight - 3)).roundToDouble(),
      ),
      random.nextBool() ? stone : dirt,
    );
    _placePrebuilt(
      CollectibleWood(
          (random.nextDouble() * (screenWidth - 3)).roundToDouble(),
          (random.nextDouble() * (screenHeight - 3)).roundToDouble(),
          room,
          null),
    );
  }

  void plant(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    if ((player.inv[wood] ?? 0) < 3) {
      return;
    }
    if (roomAt(player.room).baseOre != dirt) {
      outer:
      {
        for (Dirt dirt
            in _atOfType(player.room.x, player.room.y, EntityType.dirt)
                .map((e) => e.value)
                .cast()) {
          if (colliding(
              Offset(player.dx, player.dy), 0, Offset(dirt.dx, dirt.dy), 3)) {
            break outer;
          }
        }
        return;
      }
    }
    player.inv[wood] = player.inv[wood]! - 3;
    _placePrebuilt(Sapling(player.dx, player.dy, 360,
        IntegerOffset(player.room.x, player.room.y), null));
  }

  void chop(Player fakePlayer) {
    Player player =
        _atOfType(fakePlayer.room.x, fakePlayer.room.y, EntityType.player)
            .singleWhere((element) => element.value.code == fakePlayer.code)
            .value as Player;
    for (Tree tree in _atOfType(player.room.x, player.room.y, EntityType.tree)
        .map((e) => e.value)
        .cast()
        .toList()) {
      if (colliding(
          Offset(player.dx, player.dy), 3, Offset(tree.dx, tree.dy), 3)) {
        _entitiesByType[IntegerOffset(player.room.x, player.room.y)]![
                tree.type]!
            .remove(tree);
        player.inv[wood] = player.inv[wood]! + 4;
      }
    }
  }

  Player newPlayer(KeybindSet keybindSet) {
    Player player =
        Player(0, 0, keybindSet, IntegerOffset(0, 0), 0, 0, {}, null, null);
    _placePrebuilt(player);
    return player;
  }
}

class Room {
  final String? ore;
  final Offset orePos;

  final String baseOre;

  Room(this.ore, this.orePos, this.baseOre);

  String oreAt(double dx, double dy) {
    if (dx > orePos.dx &&
        dy > orePos.dy &&
        dx < orePos.dx + 15 &&
        dy < orePos.dy + 15 &&
        ore != null) {
      return ore!;
    } else {
      return baseOre;
    }
  }
}

enum SlotKey { x0y0, x0y1, x1y0, x1y1 }

Map<String, Entity Function(double, double, IntegerOffset, Positioned)>
    placingTypes = {
  wood: (dx, dy, room, target) => Table(dx, dy, room, null),
  robot: (dx, dy, room, target) => Robot(dx, dy, room, target, null),
  miner: (dx, dy, room, target) => Miner(dx, dy, room, null),
  dirt: (dx, dy, room, target) => Dirt(dx, dy, room, null)
};

class Recipe {
  final Map<String, int> recipe;

  final String result;

  const Recipe(this.recipe, this.result);
}

abstract class Entity extends Positioned {
  Entity(double dx, double dy, IntegerOffset room, int? codeArg)
      : super(dx, dy, room) {
    code = codeArg ?? hashCode;
  }
  late final int code;

  Entity copy();
  EntityType get type;
}

class Table extends Entity {
  Table(double dx, double dy, IntegerOffset room, int? codeArg)
      : super(dx, dy, room, codeArg);

  @override
  Table copy() => Table(dx, dy, room, code);

  @override
  EntityType get type => EntityType.table;
}

class CollectibleWood extends Entity {
  CollectibleWood(double dx, double dy, IntegerOffset room, int? codeArg)
      : super(dx, dy, room, codeArg);

  @override
  CollectibleWood copy() {
    return CollectibleWood(dx, dy, room, code);
  }

  @override
  EntityType get type => EntityType.collectibleWood;
}

class Dirt extends Entity {
  Dirt(double dx, double dy, IntegerOffset room, int? codeArg)
      : super(dx, dy, room, codeArg);

  @override
  Dirt copy() {
    return Dirt(dx, dy, room, code);
  }

  @override
  EntityType get type => EntityType.dirt;
}

abstract class Storer extends Entity {
  Storer(double dx, double dy, IntegerOffset room, int? codeArg, [this.inv = 0])
      : super(dx, dy, room, codeArg);
  int inv;

  String storedItem(Room room);
}

class Robot extends Storer {
  Robot(double dx, double dy, IntegerOffset room, this.target, int? codeArg,
      [int inv = 0])
      : super(dx, dy, room, codeArg, inv);

  @override
  String storedItem(Room room) => wood;

  Positioned target;

  @override
  Robot copy() {
    return Robot(dx, dy, room, target, code, inv);
  }

  @override
  EntityType get type => EntityType.robot;
}

class Positioned {
  double dx;
  double dy;
  IntegerOffset room;
  Positioned(this.dx, this.dy, this.room);
}

class Miner extends Storer {
  Miner(double dx, double dy, IntegerOffset room, int? codeArg,
      [int inv = 0, this.cooldown = 1])
      : super(dx, dy, room, inv);

  int cooldown;

  @override
  String storedItem(Room room) => room.oreAt(dx, dy);

  @override
  Miner copy() {
    return Miner(dx, dy, room, code, inv, cooldown);
  }

  @override
  EntityType get type => EntityType.miner;
}

class Sapling extends Entity {
  Sapling(double dx, double dy, this.growth, IntegerOffset room, int? codeArg)
      : super(dx, dy, room, codeArg);

  int growth;

  @override
  Sapling copy() {
    return Sapling(dx, dy, growth, room, code);
  }

  @override
  EntityType get type => EntityType.sapling;
}

class Tree extends Entity {
  Tree(double dx, double dy, IntegerOffset room, int? codeArg)
      : super(dx, dy, room, codeArg);

  @override
  Tree copy() {
    return Tree(dx, dy, room, code);
  }

  @override
  EntityType get type => EntityType.tree;
}

class Player extends Entity {
  Table? tableOpen;

  Player(double dx, double dy, this.keybinds, IntegerOffset room, this.xVel,
      this.yVel, this.inv, this.tableOpen, int? codeArg)
      : super(dx, dy, room, codeArg);
  final KeybindSet keybinds;
  double xVel;
  double yVel;
  final Map<String, int> inv;
  @override
  Entity copy() {
    return Player(dx, dy, keybinds, room, xVel, yVel, Map.of(inv),
        tableOpen?.copy(), code);
  }

  @override
  EntityType get type => EntityType.player;
}

class KeybindSet {
  LogicalKeyboardKey up; // w
  LogicalKeyboardKey down; // a
  LogicalKeyboardKey left; // s
  LogicalKeyboardKey right; // d
  LogicalKeyboardKey inventory; // e
  LogicalKeyboardKey openTable; // f
  LogicalKeyboardKey plant; // q
  LogicalKeyboardKey mine; // v
  LogicalKeyboardKey placePrefix; // c
  LogicalKeyboardKey openControlsDialog; // <tab>

  KeybindSet(
    this.up,
    this.down,
    this.left,
    this.right,
    this.inventory,
    this.openTable,
    this.plant,
    this.placePrefix,
    this.mine,
    this.openControlsDialog,
  );
}

class IntegerOffset {
  final int x;
  final int y;

  @override
  operator ==(Object other) {
    return other is IntegerOffset && other.x == x && other.y == y;
  }

  IntegerOffset(this.x, this.y);

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

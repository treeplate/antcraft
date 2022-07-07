// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'core.dart';
import 'packetbuffer.dart';

class World {
  int _roomX = 0;
  int _roomY = 0;
  final Map<IntegerOffset, List<Entity>> _entities = {};
  final List<MapEntry<IntegerOffset, Entity>> _updatedEntities = [];

  final List<Recipe> recipes = const [
    Recipe({iron: 1}, robot),
    Recipe({wood: 1, iron: 1}, miner),
  ];

  World(this.random);
  double screenWidth = 10;
  double screenHeight = 10;
  final Map<int, Map<int, Room>> _rooms = {};
  Table? _tableOpen;
  Table? get tableOpen => _tableOpen?.copy();
  final List<String> _ores = [iron];
  int get roomX => _roomX;
  int get roomY => _roomY;

  Map<IntegerOffset, Iterable<Table>> get tables {
    return _entities.map<IntegerOffset, Iterable<Table>>((key, value) =>
        MapEntry(
            key, _atOfType<Table>(key.x, key.y).map((e) => e.value.copy())));
  }

  Map<IntegerOffset, Iterable<Robot>> get robots {
    return _entities.map<IntegerOffset, Iterable<Robot>>((key, value) =>
        MapEntry(
            key, _atOfType<Robot>(key.x, key.y).map((e) => e.value.copy())));
  }

  Map<IntegerOffset, Iterable<CollectibleWood>> get woods {
    return _entities.map<IntegerOffset, Iterable<CollectibleWood>>(
        (key, value) => MapEntry(
            key,
            _atOfType<CollectibleWood>(key.x, key.y)
                .map((e) => e.value.copy())));
  }

  final Map<String, int> _inv = {};
  Map<String, int> get inv => _inv.map((key, value) => MapEntry(key, value));
  bool _recentMined = false;
  double playerX = 0;
  double playerY = 0;
  double _xVel = 0;
  double _yVel = 0;
  final int _cooldown = 2;
  final Random random;

  Map<IntegerOffset, Iterable<Entity>> get entities =>
      _entities.map<IntegerOffset, Iterable<Entity>>((key, value) => MapEntry(
          key,
          _entities[IntegerOffset(key.x, key.y)]?.map((e) => e.copy()) ?? {}));

  Set<MapEntry<Offset, T>> _atOfType<T extends Entity>(int rx, int ry) {
    return _entities[IntegerOffset(rx, ry)]
            ?.whereType<T>()
            .map((e) => MapEntry(Offset(e.dx, e.dy), e))
            .toSet() ??
        {};
  }

  void left() {
    _xVel--;
  }

  void up() {
    _yVel--;
  }

  void down() {
    _yVel++;
  }

  void right() {
    _xVel++;
  }

  void mine(VoidCallback callback) {
    if (!_recentMined) {
      _recentMined = true;
      String ore = room.oreAt(playerX, playerY);
      _inv[ore] = (inv[ore] ?? 0) + 1;
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

  void openTable() {
    for (MapEntry<Offset, Table> table in _atOfType<Table>(roomX, roomY)) {
      if (colliding(Offset(playerX, playerY), 5, table.key, 3)) {
        _tableOpen = table.value;
      }
    }
  }

  bool place(String type) {
    if ((inv[type] ?? 0) > 0) {
      _inv[type] = inv[type]! - 1;
      _placePrebuilt(
        IntegerOffset(roomX, roomY),
        placingTypes[type]!(
          playerX / 1,
          playerY / 1,
        ),
      );
      return true;
    }
    return false;
  }

  void _placePrebuilt(IntegerOffset room, Entity entity) {
    if (_entities[room] == null) {
      _entities[room] = [entity];
    } else {
      _entities[room]!.add(entity);
    }
  }

  void tick() {
    playerX += _xVel;
    playerY += _yVel;
    if (playerX <= 0) {
      _roomX--;
      playerX = (screenWidth - 6).roundToDouble();
    }
    if (playerX >= (screenWidth - 5)) {
      _roomX++;
      playerX = 1;
    }
    if (playerY <= 0) {
      _roomY--;
      playerY = (screenHeight - 6).roundToDouble();
    }
    if (playerY >= (screenHeight - 5)) {
      _roomY++;
      playerY = 1;
    }
    for (CollectibleWood pickup
        in _atOfType<CollectibleWood>(roomX, roomY).map((e) => e.value)) {
      if (colliding(
        Offset(playerX, playerY),
        5,
        Offset(pickup.dx, pickup.dy),
        3,
      )) {
        assert(_entities[IntegerOffset(roomX, roomY)]!.remove(pickup));

        _inv[wood] = (inv[wood] ?? 0) + 1;
      }
    }
    for (MapEntry<IntegerOffset, Entity> entity in _entities.entries
        .expand((e) => e.value.map((e2) => MapEntry(e.key, e2)))
        .toList()) {
      IntegerOffset entityRoom = entity.key;
      if (entity.value is Sapling) {
        Sapling sapling = entity.value as Sapling;
        sapling.growth--;
        if (sapling.growth == 0) {
          _entities[entityRoom]!.remove(sapling);
          _entities[entityRoom]!.add(Tree(sapling.dx, sapling.dy));
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
        if (roomX == entityRoom.x &&
            roomY == entityRoom.y &&
            colliding(
                Offset(playerX, playerY), 5, Offset(storer.dx, storer.dy), 3)) {
          _inv[storer.storedItem(room)] =
              (inv[storer.storedItem(room)] ?? 0) + storer.inv;
          storer.inv = 0;
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
          for (CollectibleWood pickup
              in _atOfType<CollectibleWood>(entityRoom.x, entityRoom.y)
                  .map((e) => e.value)) {
            if (robot.inv < 5) {
              if (colliding(
                Offset(robot.dx, robot.dy),
                3,
                Offset(pickup.dx, pickup.dy),
                3,
              )) {
                assert(_entities[entityRoom]!.remove(pickup));
                assert(robot.storedItem(_rooms[entityRoom.x]![entityRoom.y]!) ==
                    wood);
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

          if (robot.inv < 5) {
            if (woods[entityRoom]?.isEmpty ?? false) {
              IntegerOffset woodRoom = nearestRoomWhere(
                  (Room r, IntegerOffset rPos) =>
                      woods[rPos]?.isNotEmpty ?? false,
                  to: entityRoom);
              honeRoom(woodRoom.x, woodRoom.y);
            } else {
              hone(woods[entityRoom]!.first.dx, woods[entityRoom]!.first.dy);
            }
          } else {
            if (roomX == entityRoom.x && roomY == entityRoom.y) {
              hone(
                playerX,
                playerY,
              );
            } else {
              honeRoom(roomX, roomY);
            }
          }
          if (robot.dx < 0) {
            _entities[entityRoom]!.remove(robot);
            _placePrebuilt(
              IntegerOffset(entityRoom.x - 1, entityRoom.y),
              robot..dx = screenWidth.roundToDouble() - 1,
            );
            entityRoom = IntegerOffset(entityRoom.x - 1, entityRoom.y);
          }
          if (robot.dx > screenWidth) {
            _entities[entityRoom]!.remove(robot);
            _placePrebuilt(
              IntegerOffset(entityRoom.x + 1, entityRoom.y),
              robot..dx = 1,
            );
            entityRoom = IntegerOffset(entityRoom.x + 1, entityRoom.y);
          }
          if (robot.dy < 0) {
            _entities[entityRoom]!.remove(robot);
            _placePrebuilt(
              IntegerOffset(entityRoom.x, entityRoom.y - 1),
              robot..dy = screenHeight.roundToDouble() - 1,
            );
            entityRoom = IntegerOffset(entityRoom.x, entityRoom.y - 1);
          }
          if (robot.dy > screenHeight) {
            _entities[entityRoom]!.remove(robot);
            _placePrebuilt(
              IntegerOffset(entityRoom.x, entityRoom.y + 1),
              robot..dy = 1,
            );
          }
        }
      }
    }
  }

  bool craft(Recipe recipe) {
    if (tableOpen != null) {
      for (MapEntry<String, int> item in recipe.recipe.entries) {
        if ((inv[item.key] ?? 0) < item.value) {
          return false;
        }
      }
      for (MapEntry<String, int> item in recipe.recipe.entries) {
        _inv[item.key] = inv[item.key]! - item.value;
      }
      _inv[recipe.result] = (inv[recipe.result] ?? 0) + 1;
      return true;
    }
    return false;
  }

  Room get room {
    if (_rooms[roomX] == null) {
      _rooms[roomX] = {};
    }
    if (_rooms[roomX]![roomY] == null) {
      genRoom(IntegerOffset(roomX, roomY));
    }
    return _rooms[roomX]![roomY]!;
  }

  void closeTable() {
    _tableOpen = null;
  }

  void handlePacket(PacketBuffer buffer, SendPort connection) {
    if (buffer.available > 0) {
      int op = buffer.readUint8List(1).single;
      switch (op) {
        case 1:
          up();
          connection.send([6, 1]);
          break;
        case 2:
          down();
          connection.send([6, 2]);
          break;
        case 3:
          left();
          connection.send([6, 3]);
          break;
        case 4:
          right();
          connection.send([6, 4]);
          break;
        case 7:
          openTable();
          connection.send([6, 7]);
          break;
        case 9:
          craft(recipes[buffer.readInt64()]);
          connection.send([6, 9]);
          break;
        case 10:
          closeTable();
          connection.send([6, 10]);
          break;
        case 11:
          place(robot);
          connection.send([6, 11]);
          break;
        case 12:
          place(wood);
          connection.send([6, 12]);
          break;
        case 13:
          mine(() {});
          connection.send([6, 13]);
          break;
        case 14:
          connection.send([0, playerX, playerY]);
          break;
        case 15:
          connection.send([1, roomX, roomY]);
          break;
        case 16:
          connection.send([
            2,
            inv
                .map((key, value) => MapEntry(itemToNumber(key), value))
                .entries
                .map((e) => [e.key, e.value])
                .expand((element) => element)
          ]
              .expand((element) => element is Iterable ? element : [element])
              .toList());
          break;
        case 17:
          connection.send([
            3,
            robots.entries
                .expand((e) => e.value.map((e2) => MapEntry(e.key, e2)))
                .map((e) =>
                    MapEntry([e.key.x, e.key.y], [e.value.dx, e.value.dy]))
                .map((e) => [e.key, e.value])
                .expand((element) => element)
                .expand((element) => element)
          ]
              .expand((element) => element is Iterable ? element : [element])
              .toList());
          break;
        case 18:
          connection.send(
            [
              5,
              room.orePos.dx,
              room.orePos.dy,
              itemToNumber(room.ore),
            ].toList(),
          );
          break;
        default:
          connection.send([7]);
      }
    } else {
      print('[7] sending');
      connection.send([7]);
    }
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
      {IntegerOffset? to}) {
    to ??= IntegerOffset(roomX, roomY);
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
      room,
      CollectibleWood(
        (random.nextDouble() * (screenWidth - 3)).roundToDouble(),
        (random.nextDouble() * (screenHeight - 3)).roundToDouble(),
      ),
    );
  }

  void plant() {
    if ((inv[wood] ?? 0) < 1) {
      return;
    }
    if (room.baseOre != dirt) {
      outer:
      {
        for (Dirt dirt in _atOfType<Dirt>(roomX, roomY).map((e) => e.value)) {
          if (colliding(
              Offset(playerX, playerY), 0, Offset(dirt.dx, dirt.dy), 3)) {
            break outer;
          }
        }
        return;
      }
    }
    _inv[wood] = _inv[wood]! - 1;
    (_entities[IntegerOffset(roomX, roomY)] ??
            (_entities[IntegerOffset(roomX, roomY)] = []))
        .add(Sapling(playerX, playerY, 360));
  }

  void chop() {
    for (Tree dirt in _atOfType<Tree>(roomX, roomY).map((e) => e.value)) {
      if (colliding(Offset(playerX, playerY), 5, Offset(dirt.dx, dirt.dy), 3)) {
        _entities[IntegerOffset(roomX, roomY)]!.remove(dirt);
        _inv[wood] = _inv[wood]! + 10;
      }
    }
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
        dx < orePos.dx + 30 &&
        dy < orePos.dy + 30 &&
        ore != null) {
      return ore!;
    } else {
      return baseOre;
    }
  }
}

enum SlotKey { x0y0, x0y1, x1y0, x1y1 }

Map<String, Entity Function(double, double)> placingTypes = {
  wood: (dx, dy) => Table(dx, dy),
  robot: (dx, dy) => Robot(dx, dy),
  miner: (dx, dy) => Miner(dx, dy),
  dirt: (dx, dy) => Dirt(dx, dy)
};

class Recipe {
  final Map<String, int> recipe;

  final String result;

  const Recipe(this.recipe, this.result);
}

abstract class Entity {
  double dx;
  double dy;

  Entity(this.dx, this.dy);

  Entity copy();
  EntityKey get key;
}

class Table extends Entity {
  Table(double dx, double dy) : super(dx, dy);

  @override
  Table copy() => Table(dx, dy);

  @override
  EntityKey get key => EntityKey.table;
}

class CollectibleWood extends Entity {
  CollectibleWood(double dx, double dy) : super(dx, dy);

  @override
  CollectibleWood copy() {
    return CollectibleWood(dx, dy);
  }

  @override
  EntityKey get key => EntityKey.collectibleWood;
}

class Dirt extends Entity {
  Dirt(double dx, double dy) : super(dx, dy);

  @override
  Dirt copy() {
    return Dirt(dx, dy);
  }

  @override
  EntityKey get key => EntityKey.dirt;
}

abstract class Storer extends Entity {
  Storer(double dx, double dy, [this.inv = 0]) : super(dx, dy);
  int inv;

  String storedItem(Room room);
}

class Robot extends Storer {
  Robot(double dx, double dy, [int inv = 0]) : super(dx, dy, inv);

  @override
  String storedItem(Room room) => wood;

  @override
  Robot copy() {
    return Robot(dx, dy, inv);
  }

  @override
  EntityKey get key => EntityKey.robot;
}

class Miner extends Storer {
  Miner(double dx, double dy, [int inv = 0, this.cooldown = 1])
      : super(dx, dy, inv);

  int cooldown;

  @override
  String storedItem(Room room) => room.oreAt(dx, dy);

  @override
  Miner copy() {
    return Miner(dx, dy, inv, cooldown);
  }

  @override
  EntityKey get key => EntityKey.miner;
}

class Sapling extends Entity {
  Sapling(double dx, double dy, this.growth) : super(dx, dy);

  int growth;

  @override
  Sapling copy() {
    return Sapling(dx, dy, growth);
  }

  @override
  EntityKey get key => EntityKey.sapling;
}

class Tree extends Entity {
  Tree(double dx, double dy) : super(dx, dy);

  @override
  Tree copy() {
    return Tree(dx, dy);
  }

  @override
  EntityKey get key => EntityKey.tree;
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

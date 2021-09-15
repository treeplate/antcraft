// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'packetbuffer.dart';

const String stone = 'ore.just.stone';
const String iron = 'ore.raw.iron';
const String wood = 'wood.raw';

class World {
  int _roomX = 0;

  int _roomY = 0;

  World(this.random);
  double screenWidth = 10;
  double screenHeight = 10;
  final Map<int, Map<int, Room>> _rooms = {};
  Table? _tableOpen;
  Table? get tableOpen => _tableOpen?.toTable();
  final List<String> _ores = [iron];
  final Map<IntegerOffset, Robot> _robots = {};
  Map<IntegerOffset, Robot> get robots =>
      _robots.map((key, value) => MapEntry(key, value));
  int get roomX => _roomX;
  int get roomY => _roomY;
  final Map<String, int> _inv = {};
  Map<String, int> get inv => _inv.map((key, value) => MapEntry(key, value));
  bool _recentMined = false;
  double playerX = 0;
  double playerY = 0;
  double _xVel = 0;
  double _yVel = 0;
  final int _cooldown = 2;
  bool _shopActive = false;
  bool get shopActive => _shopActive;
  final Random random;
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
      if (playerX > room.orePos.dx &&
          playerY > room.orePos.dy &&
          playerX < room.orePos.dx + 30 &&
          playerY < room.orePos.dy + 30 &&
          room.ore != "none") {
        _inv[room.ore] = (_inv[room.ore] ?? 0) + 1;
      } else {
        _inv[stone] = (_inv[stone] ?? 0) + 1;
      }
      callback();
      Timer(
        Duration(seconds: _cooldown),
        () => _recentMined = false,
      );
    }
  }

  void placeTable() {
    if ((_inv[wood] ?? 0) > 0) {
      _inv[wood] = _inv[wood]! - 1;
      room.tables[Offset(playerX, playerY)] = Table();
    }
  }

  void openTable() {
    for (MapEntry<Offset, Table> table in room.tables.entries) {
      Offset logPos = table.key;
      if (((logPos.dx > playerX && logPos.dx < playerX + 5) ||
              (logPos.dx + 3 > playerX && logPos.dx + 3 < playerX + 5)) &&
          ((logPos.dy + 3 > playerY && logPos.dy + 3 < playerY + 5) ||
              (logPos.dy > playerY && logPos.dy < playerY + 5))) {
        _tableOpen = table.value;
      }
    }
  }

  void placeRobot() {
    if ((_inv['robot'] ?? 0) > 0) {
      _inv['robot'] = _inv['robot']! - 1;
      _robots[IntegerOffset(roomX, roomY)] = Robot(
        playerX / 1,
        playerY / 1,
        Offset(
          random.nextDouble() * screenWidth,
          random.nextDouble() * screenHeight,
        ),
      );
    }
  }

  void openShop() {
    if (playerX > screenWidth / 2 - 7.5 &&
        playerY > screenHeight / 2 - 7.5 &&
        playerX < (15 + screenWidth / 2) - 7.5 &&
        playerY < (screenHeight / 2 + 15) - 7.5 &&
        roomX == 1 &&
        roomY == 1) {
      _shopActive = true;
    }
  }

  void tick() {
    playerX += _xVel;
    playerY += _yVel;
    if (playerX <= 0) {
      _roomX--;
      playerX = (screenWidth - 6);
    }
    if (playerX >= (screenWidth - 5)) {
      _roomX++;
      playerX = 1;
    }
    if (playerY <= 0) {
      _roomY--;
      playerY = (screenHeight - 6);
    }
    if (playerY >= (screenHeight - 5)) {
      _roomY++;
      playerY = 1;
    }
    if (((room.logPos.dx > playerX && room.logPos.dx < playerX + 5) ||
            (room.logPos.dx + 3 > playerX &&
                room.logPos.dx + 3 < playerX + 5)) &&
        ((room.logPos.dy + 3 > playerY && room.logPos.dy + 3 < playerY + 5) ||
            (room.logPos.dy > playerY && room.logPos.dy < playerY + 5))) {
      room.logPos = const Offset(-30, -30);

      _inv[wood] = (_inv[wood] ?? 0) + 1;
    }
    for (MapEntry<IntegerOffset, Robot> robot in _robots.entries.toList()) {
      if (_rooms[robot.key.x] == null) {
        _rooms[robot.key.x] = {};
      }
      if (_rooms[robot.key.x]![robot.key.y] == null) {
        _rooms[robot.key.x]![robot.key.y] = Room(
          Offset(
            (random.nextDouble() * (screenWidth - 15)).roundToDouble(),
            (random.nextDouble() * (screenHeight - 15)).roundToDouble(),
          ),
          {},
          (_ores..shuffle()).first,
          robot.key.x == 1 && robot.key.y == 1,
          Offset(
            (random.nextDouble() * (screenWidth - 3)).roundToDouble(),
            (random.nextDouble() * (screenHeight - 3)).roundToDouble(),
          ),
        );
      }
      Room room = _rooms[robot.key.x]![robot.key.y]!;
      if (((robot.value.dx > playerX && robot.value.dx < playerX + 5) ||
              (robot.value.dx + 3 > playerX &&
                  robot.value.dx + 3 < playerX + 5)) &&
          ((robot.value.dy + 3 > playerY && robot.value.dy + 3 < playerY + 5) ||
              (robot.value.dy > playerY && robot.value.dy < playerY + 5)) &&
          roomX == robot.key.x &&
          roomY == robot.key.y) {
        _inv[wood] = (_inv[wood] ?? 0) + robot.value.inv;
        _robots[robot.key] = Robot(
          robot.value.dx,
          robot.value.dy,
          robot.value.pos,
          0,
        );
        robot = MapEntry(robot.key, _robots[robot.key]!);
      }

      //("Pre-move ${robot.key.hashCode} pos ${_robots[robot.key]} logpos ${room.logPos}");
      if (Offset(robot.value.dx, robot.value.dy) == room.logPos) {
        _robots[robot.key] = Robot(
          robot.value.dx,
          robot.value.dy,
          robot.value.pos,
          robot.value.inv + 1,
        );
        robot = MapEntry(robot.key, _robots[robot.key]!);
        room.logPos = const Offset(-30, -30);
      }
      void hone(x, y) {
        if (robot.value.dx > x) {
          //("L.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] = Robot(
            robot.value.dx - .5,
            robot.value.dy,
            robot.value.pos,
            robot.value.inv,
          );
          //("L.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dx < x) {
          //("R.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] = Robot(
            robot.value.dx + .5,
            robot.value.dy,
            robot.value.pos,
            robot.value.inv,
          );
          //("R.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy > y) {
          //("U.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] = Robot(
            robot.value.dx,
            robot.value.dy - .5,
            robot.value.pos,
            robot.value.inv,
          );
          //("U.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy < y) {
          //("D.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] = Robot(
            robot.value.dx,
            robot.value.dy + .5,
            robot.value.pos,
            robot.value.inv,
          );
          //("D.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
      }

      if (robot.value.inv < 5) {
        hone(room.logPos.dx, room.logPos.dy);
      } else {
        if (robot.key.x > roomX) {
          _robots[robot.key] = Robot(
            robot.value.dx - .5,
            robot.value.dy,
            robot.value.pos,
            robot.value.inv,
          );
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.x < roomX) {
          _robots[robot.key] = Robot(
            robot.value.dx + .5,
            robot.value.dy,
            robot.value.pos,
            robot.value.inv,
          );
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.y < roomY) {
          _robots[robot.key] = Robot(
            robot.value.dx,
            robot.value.dy + .5,
            robot.value.pos,
            robot.value.inv,
          );
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.y > roomY) {
          _robots[robot.key] = Robot(
            robot.value.dx,
            robot.value.dy - .5,
            robot.value.pos,
            robot.value.inv,
          );
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (roomX == robot.key.x && roomY == robot.key.y) {
          hone(
            robot.value.pos.dx,
            robot.value.pos.dy,
          );
        }
      }
      if (robot.value.dx <= 0) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x - 1, robot.key.y)] = Robot(
          screenWidth.roundToDouble() - 1,
          robot.value.dy,
          robot.value.pos,
          robot.value.inv,
        );
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dx >= screenWidth) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x + 1, robot.key.y)] = Robot(
          1,
          robot.value.dy,
          robot.value.pos,
          robot.value.inv,
        );
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dy <= 0) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x, robot.key.y - 1)] = Robot(
          robot.value.dx,
          screenHeight.roundToDouble() - 1,
          robot.value.pos,
          robot.value.inv,
        );
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dy >= screenHeight) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x, robot.key.y + 1)] = Robot(
          robot.value.dx,
          1,
          robot.value.pos,
          robot.value.inv,
        );
      }

      //("Post-move ${robot.key.hashCode} pos ${_robots[robot.key]}");
    }
  }

  void craft() {
    if (_tableOpen!.result != "none") {
      _inv[_tableOpen!.result] = (_inv[_tableOpen!.result] ?? 0) + 1;
      _tableOpen!.grid = {
        SlotKey.x0y0: "none",
        SlotKey.x0y1: "none",
        SlotKey.x1y0: "none",
        SlotKey.x1y1: "none",
      };
    }
  }

  void setCraftCorner(SlotKey slotKey, String value) {
    if (value == "none" || (_inv[value] ?? 0) > 0) {
      if (_tableOpen!.grid[slotKey] != "none") {
        _inv[_tableOpen!.grid[slotKey]!] =
            _inv[_tableOpen!.grid[slotKey]!]! + 1;
      }

      if (value != "none") {
        _inv[value] = _inv[value]! - 1;
      }
      _tableOpen!.grid[slotKey] = value;
    }
  }

  Room get room {
    if (_rooms[roomX] == null) {
      _rooms[roomX] = {};
    }
    if (_rooms[roomX]![roomY] == null) {
      _rooms[roomX]![roomY] = Room(
        Offset(
          (random.nextDouble() * (screenWidth - 15)).roundToDouble(),
          (random.nextDouble() * (screenHeight - 15)).roundToDouble(),
        ),
        {},
        (_ores..shuffle()).first,
        roomX == 1 && roomY == 1,
        Offset(
          (random.nextDouble() * (screenWidth - 3)).roundToDouble(),
          (random.nextDouble() * (screenHeight - 3)).roundToDouble(),
        ),
      );
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
        case 5:
          openShop();
          connection.send([6, 5]);
          break;
        case 6:
          closeShop();
          connection.send([6, 6]);
          break;
        case 7:
          openTable();
          connection.send([6, 7]);
          break;
        case 8:
          if (buffer.available >= 1) {
            int num = buffer.readUint8List(1).single;
            SlotKey slotKey = SlotKey.values[num & 3];
            String item;
            item = numberToItem((num - num % 3) ~/ 4);
            setCraftCorner(slotKey, item);
          } else {
            connection.send([7]);
            print('[7] sending');
            return;
          }
          connection.send([6, 8]);
          break;
        case 9:
          craft();
          connection.send([6, 9]);
          break;
        case 10:
          closeTable();
          connection.send([6, 10]);
          break;
        case 11:
          placeRobot();
          connection.send([6, 11]);
          break;
        case 12:
          placeTable();
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
            robots
                .map((a, b) => MapEntry([a.x, a.y], [b.dx, b.dy]))
                .entries
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
              room.logPos.dx,
              room.logPos.dy,
              room.orePos.dx,
              room.orePos.dy,
              room.tables
                  .map(
                    (a, b) => MapEntry(
                      [a.dx, a.dy],
                      [
                        b.grid
                            .map((a2, b2) =>
                                MapEntry(a2.index, itemToNumber(b2)))
                            .entries
                            .map((e) => [e.key, e.value])
                            .expand((element) => element),
                        itemToNumber(b.result),
                      ].expand((element) =>
                          element is Iterable ? element : [element]),
                    ),
                  )
                  .entries
                  .map((e) => [e.key, e.value])
                  .expand((element) => element)
                  .expand(
                    (element) => element is Iterable ? element : [element],
                  ),
              itemToNumber(room.ore),
              room.shop ? 1 : 0,
            ]
                .expand((element) => element is Iterable ? element : [element])
                .toList(),
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

  String numberToItem(int num) {
    switch (num) {
      case 0:
        return stone;
      case 1:
        return iron;
      case 2:
        return wood;

      case 3:
        return 'robot';
      case 4:
        return 'none';
      default:
        throw UnimplementedError();
    }
  }

  int itemToNumber(String item) {
    switch (item) {
      case stone:
        return 0;
      case iron:
        return 1;
      case wood:
        return 2;
      case 'robot':
        return 3;
      case 'none':
        return 4;
      default:
        throw UnimplementedError();
    }
  }

  void closeShop() {
    _shopActive = false;
  }
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
    if (grid[SlotKey.x0y0] == stone &&
        grid[SlotKey.x1y0] == "none" &&
        grid[SlotKey.x0y1] == "none" &&
        grid[SlotKey.x1y1] == stone) {
      return "furnace";
    }
    if (grid[SlotKey.x0y0] == iron &&
        grid[SlotKey.x1y0] == "none" &&
        grid[SlotKey.x0y1] == "none" &&
        grid[SlotKey.x1y1] == "none") {
      return "robot";
    }
    return "none";
  }

  Table toTable() =>
      Table()..grid = grid.map((key, value) => MapEntry(key, value));
}

class Robot {
  final double dx;
  final double dy;
  final int inv;
  final Offset pos;

  Robot(this.dx, this.dy, this.pos, [this.inv = 0]);
}

class IntegerOffset {
  final int x;
  final int y;

  IntegerOffset(this.x, this.y);
}

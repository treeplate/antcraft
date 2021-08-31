import 'dart:async';
import 'dart:math';
import 'dart:ui';

const String stone = 'ore.just.stone';
const String iron = 'ore.raw.iron';

class World {
  World(this.random);
  double screenWidth = 10;
  double screenHeight = 10;
  final Map<int, Map<int, Room>> _rooms = {};
  Map<int, Map<int, Room>> get rooms => _rooms.map((key, value) =>
      MapEntry(key, value.map((key, value) => MapEntry(key, value))));
  Table? _tableOpen;
  Table? get tableOpen => _tableOpen?.toTable();
  final List<String> ores = [iron];
  final Map<IntegerOffset, Robot> _robots = {};
  Map<IntegerOffset, Robot> get robots =>
      _robots.map((key, value) => MapEntry(key, value));
  int roomX = 0;
  int roomY = 0;
  final Map<String, int> _inv = {};
  Map<String, int> get inv => _inv.map((key, value) => MapEntry(key, value));
  bool recentMined = false;
  int playerX = 0;
  int playerY = 0;
  int xVel = 0;
  int yVel = 0;
  int cooldown = 2;
  bool shopActive = false;
  bool invActive = false;
  final Random random;
  void left() {
    xVel--;
  }

  void up() {
    yVel--;
  }

  void down() {
    yVel++;
  }

  void right() {
    xVel++;
  }

  void mine(VoidCallback callback) {
    if (!recentMined) {
      recentMined = true;
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
        Duration(seconds: cooldown),
        () => recentMined = false,
      );
    }
  }

  void placeTable() {
    if ((_inv['wood.raw'] ?? 0) > 0) {
      _inv['wood.raw'] = _inv['wood.raw']! - 1;
      room.tables[Offset(playerX / 1, playerY / 1)] = Table();
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
      _robots[IntegerOffset(roomX, roomY)] = Robot(playerX / 1, playerY / 1);
    }
  }

  void openShop() {
    if (playerX > screenWidth / 2 - 7.5 &&
        playerY > screenHeight / 2 - 7.5 &&
        playerX < (15 + screenWidth / 2) - 7.5 &&
        playerY < (screenHeight / 2 + 15) - 7.5 &&
        roomX == 1 &&
        roomY == 1) {
      shopActive = true;
    }
  }

  void openInventory() {
    invActive = !invActive;
  }

  void tick() {
    playerX += xVel;
    playerY += yVel;
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
    if (((room.logPos.dx > playerX && room.logPos.dx < playerX + 5) ||
            (room.logPos.dx + 3 > playerX &&
                room.logPos.dx + 3 < playerX + 5)) &&
        ((room.logPos.dy + 3 > playerY && room.logPos.dy + 3 < playerY + 5) ||
            (room.logPos.dy > playerY && room.logPos.dy < playerY + 5))) {
      room.logPos = const Offset(-30, -30);

      _inv['wood.raw'] = (_inv['wood.raw'] ?? 0) + 1;
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
          (ores..shuffle()).first,
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
        _inv['wood.raw'] = (_inv['wood.raw'] ?? 0) + robot.value.inv;
        _robots[robot.key] = Robot(robot.value.dx, robot.value.dy, 0);
        robot = MapEntry(robot.key, _robots[robot.key]!);
      }

      //("Pre-move ${robot.key.hashCode} pos ${_robots[robot.key]} logpos ${room.logPos}");
      if (Offset(robot.value.dx, robot.value.dy) == room.logPos) {
        _robots[robot.key] =
            Robot(robot.value.dx, robot.value.dy, robot.value.inv + 1);
        robot = MapEntry(robot.key, _robots[robot.key]!);
        room.logPos = ([const Offset(-30, -30), Offset(-30, screenHeight + 30)]
              ..shuffle(Random(room.logPos.dx.ceil())))
            .first;
      }
      void hone(x, y) {
        if (robot.value.dx > x) {
          //("L.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] =
              Robot(robot.value.dx - .5, robot.value.dy, robot.value.inv);
          //("L.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dx < x) {
          //("R.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] =
              Robot(robot.value.dx + .5, robot.value.dy, robot.value.inv);
          //("R.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy > y) {
          //("U.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] =
              Robot(robot.value.dx, robot.value.dy - .5, robot.value.inv);
          //("U.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.value.dy < y) {
          //("D.${robot.key.hashCode} pos ${_robots[robot.key]}");
          _robots[robot.key] =
              Robot(robot.value.dx, robot.value.dy + .5, robot.value.inv);
          //("D.${robot.key.hashCode} postpos ${_robots[robot.key]}");
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
      }

      if (robot.value.inv < 5) {
        hone(room.logPos.dx, room.logPos.dy);
      } else {
        if (robot.key.x > roomX) {
          _robots[robot.key] =
              Robot(robot.value.dx - .5, robot.value.dy, robot.value.inv);
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.x < roomX) {
          _robots[robot.key] =
              Robot(robot.value.dx + .5, robot.value.dy, robot.value.inv);
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.y < roomY) {
          _robots[robot.key] =
              Robot(robot.value.dx, robot.value.dy + .5, robot.value.inv);
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (robot.key.y > roomY) {
          _robots[robot.key] =
              Robot(robot.value.dx, robot.value.dy - .5, robot.value.inv);
          robot = _robots.entries
              .toList()[_robots.keys.toList().indexOf(robot.key)];
        }
        if (roomX == robot.key.x && roomY == robot.key.y) {
          hone(screenWidth / 2, screenHeight / 2);
        }
      }
      if (robot.value.dx <= 0) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x - 1, robot.key.y)] = Robot(
            screenWidth.roundToDouble() - 1, robot.value.dy, robot.value.inv);
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dx >= screenWidth) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x + 1, robot.key.y)] =
            Robot(1, robot.value.dy, robot.value.inv);
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dy <= 0) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x, robot.key.y - 1)] = Robot(
            robot.value.dx, screenHeight.roundToDouble() - 1, robot.value.inv);
        robot = _robots.entries.toList()[_robots.keys.length - 1];
      }
      if (robot.value.dy >= screenHeight) {
        _robots.remove(robot.key);
        _robots[IntegerOffset(robot.key.x, robot.key.y + 1)] =
            Robot(robot.value.dx, 1, robot.value.inv);
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
        (ores..shuffle()).first,
        playerX == 1 && playerY == 1,
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

  Robot(this.dx, this.dy, [this.inv = 0]);
}

class IntegerOffset {
  final int x;
  final int y;

  IntegerOffset(this.x, this.y);
}

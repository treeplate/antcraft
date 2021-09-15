// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:some_app/logic.dart';
import 'package:some_app/packetbuffer.dart';

void main() {
  test('Handling packets', () async {
    TestWorld world = TestWorld(Random());
    PacketBuffer buffer = PacketBuffer();
    ReceivePort connection = ReceivePort();
    StreamSubscription? subscription;
    Completer completer = Completer();
    subscription = connection.listen((message) {
      expect(message.first, lessThan(8));
      if (message.first >= 7) {
        subscription!.cancel();
        completer.complete();
        return;
      } else if (message.first >= 6) {
        if (message.last == 7) {
          buffer.add([8, 15]);
        } else {
          expect(message.last, lessThan(14));
          buffer.add([message.last + 1]);
        }
      } else {
        expect(message.first, greaterThan(-1));
        switch (message.first) {
          case 0:
            expect(message, [
              0,
              32,
              35,
            ]);
            break;
          case 1:
            expect(message, [
              1,
              324,
              354,
            ]);
            break;
          case 2:
            expect(message, [
              2,
              0,
              12,
              1,
              13,
              2,
              14,
              3,
              15,
            ]);
            break;
          case 3:
            expect(message, [
              3,
              0,
              1,
              3,
              2,
              6,
              7,
              8,
              9,
            ]);
            break;
          case 5:
            expect(message, [
              5,
              324,
              354,
              100,
              101,
              32,
              35,
              0,
              4,
              1,
              4,
              2,
              4,
              3,
              4,
              4,
              1,
              0,
            ]);
            break;
        }
        buffer.add([message.first + 15]);
      }
      world.handlePacket(buffer, connection.sendPort);
    });
    buffer.add([1]);
    world.handlePacket(buffer, connection.sendPort);
    await completer.future;
    expect(world.logs, [1, 2, 3, 4, 5, 6, 7, 6, 9, 10, 11, 12, 13]);
  });
}

class TestWorld extends World {
  TestWorld(Random random) : super(random);
  @override
  Map<IntegerOffset, Robot> get robots => {
        IntegerOffset(
          0,
          1,
        ): Robot(
          3,
          2,
          const Offset(4, 5),
          453,
        ),
        IntegerOffset(
          6,
          7,
        ): Robot(
          8,
          9,
          const Offset(10, 11),
          2432,
        ),
      };
  @override
  Map<String, int> get inv => {
        stone: 12,
        iron: 13,
        wood: 14,
        'robot': 15,
      };
  @override
  Room get room {
    return Room(
      Offset(roomX / 1, roomY / 1),
      {Offset(playerX, playerY): Table()},
      iron,
      playerX == roomX,
      const Offset(100, 101),
    );
  }

  List<int> logs = [];

  @override
  void up() => logs.add(1);
  @override
  void down() => logs.add(2);
  @override
  void left() => logs.add(3);
  @override
  void right() => logs.add(4);
  @override
  void craft() => logs.add(9);
  @override
  void placeTable() => logs.add(12);
  @override
  void openTable() => logs.add(7);
  @override
  void closeTable() => logs.add(10);
  @override
  void placeRobot() => logs.add(11);
  @override
  void setCraftCorner(SlotKey key, String string) =>
      logs.add(itemToNumber(string) + key.index);
  @override
  void openShop() => logs.add(5);
  @override
  void closeShop() => logs.add(6);
  @override
  int get roomX => 324;
  @override
  int get roomY => 354;
  @override
  double get playerX => 32;
  @override
  double get playerY => 35;

  @override
  void mine(VoidCallback callback) {
    callback();
    logs.add(13);
  }

  @override
  bool get shopActive => playerY == roomY;

  @override
  Table? get tableOpen => Table();

  @override
  void tick() {
    logs.add(-1);
  }
}

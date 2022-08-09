import 'package:flutter/material.dart';
import 'core.dart';

Map<String, MaterialColor> oreColors = {
  'iron': Colors.blue,
};

const Color stoneColor = Color.fromARGB(179, 60, 59, 59);

class OreRenderer extends StatelessWidget {
  const OreRenderer({
    Key? key,
    required this.color,
    required this.width,
    required this.height,
  }) : super(key: key);
  final MaterialColor color;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color[800],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class StoneRenderer extends StatelessWidget {
  const StoneRenderer({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: stoneColor,
      ),
    );
  }
}

class WoodRenderer extends StatelessWidget {
  const WoodRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/wood.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class TableRenderer extends StatelessWidget {
  const TableRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/placed-wood.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

Row parseInlinedIcons(String text) {
  List<Widget> result = [];
  StringBuffer buffer = StringBuffer();
  bool parsingKey = false;
  for (int rune in text.runes) {
    if (parsingKey) {
      if (rune == 0x7D) {
        result.add(renderItem(buffer.toString(), width: 30, height: 30));
        buffer = StringBuffer();
        parsingKey = false;
      } else {
        buffer.writeCharCode(rune);
      }
    } else {
      if (rune == 0x7B) {
        result.add(Text(
          buffer.toString(),
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ));
        buffer = StringBuffer();
        parsingKey = true;
      } else {
        buffer.writeCharCode(rune);
      }
    }
  }
  if (parsingKey) {
    result.add(renderItem(buffer.toString(), width: 30, height: 30));
  } else {
    result.add(Text(
      buffer.toString(),
      style: const TextStyle(fontSize: 30, color: Colors.white),
    ));
  }
  return Row(
    children: result,
    mainAxisSize: MainAxisSize.min,
  );
}

Widget renderItem(String? optionalItem,
    {required double width, required double height}) {
  if (optionalItem == null) {
    return SizedBox(
      width: width,
      height: height,
    );
  }
  String item = optionalItem;
  if (item.contains('.') && item.substring(0, item.indexOf('.')) == 'entity') {
    return renderEntity(
      EntityType.values.singleWhere(
          (element) => element.name == item.substring(item.indexOf('.') + 1)),
      height: height,
      width: width,
    );
  }
  if (item.contains('.') && item.substring(0, item.indexOf('.')) == 'ore') {
    if (item == stone) {
      return StoneRenderer(
        width: width,
        height: height,
      );
    } else {
      return OreRenderer(
        color: oreColors[item.substring(item.indexOf('.') + 1)]!,
        height: height,
        width: width,
      );
    }
  }
  if (item == wood) {
    return WoodRenderer(
      height: height,
      width: width,
    );
  }
  if (item == robot) {
    return RobotRenderer(
      width: width,
      height: height,
    );
  }
  if (item == miner) {
    return MinerRenderer(
      width: width,
      height: height,
    );
  }
  if (item == dirt) {
    return DirtRenderer(
      width: width,
      height: height,
    );
  }
  return Text(
    'unknown key $item',
    style: const TextStyle(color: Colors.red),
  );
}

Widget renderEntity(EntityType entity,
    {required double width,
    required double height,
    bool ghost = false,
    bool isMe = false}) {
  switch (entity) {
    case EntityType.miner:
      return MinerRenderer(width: width, height: height, ghost: ghost);
    case EntityType.dirt:
      return DirtRenderer(width: width, height: height, ghost: ghost);
    case EntityType.robot:
      return RobotRenderer(width: width, height: height, ghost: ghost);
    case EntityType.table:
      return TableRenderer(width: width, height: height, ghost: ghost);
    case EntityType.collectibleWood:
      return WoodRenderer(width: width, height: height, ghost: ghost);
    case EntityType.sapling:
      return SaplingRenderer(width: width, height: height, ghost: ghost);
    case EntityType.tree:
      return TreeRenderer(width: width, height: height, ghost: ghost);
    case EntityType.player:
      return PlayerRenderer(
        width: width,
        height: height,
        ghost: ghost,
        isMe: isMe,
      );
  }
}

class PlayerRenderer extends StatelessWidget {
  const PlayerRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
    required this.isMe,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          color: isMe
              ? ghost
                  ? Colors.red
                  : Colors.green
              : ghost
                  ? Colors.yellow.withAlpha(128)
                  : Colors.yellow),
    );
  }
}

class RobotRenderer extends StatelessWidget {
  const RobotRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/robot.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class MinerRenderer extends StatelessWidget {
  const MinerRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/miner.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class SaplingRenderer extends StatelessWidget {
  const SaplingRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/tree-sapling.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class TreeRenderer extends StatelessWidget {
  const TreeRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/tree-top.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class DirtRenderer extends StatelessWidget {
  const DirtRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.ghost = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/dirt.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

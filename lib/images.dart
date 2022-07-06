import 'package:flutter/material.dart' hide Table;
import 'package:some_app/logic.dart';
import 'core.dart';

Map<String, MaterialColor> oreColors = {
  "iron": Colors.blue,
};

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
      decoration: BoxDecoration(
        color: Colors.grey[600],
      ),
    );
  }
}

class WoodRenderer extends StatelessWidget {
  const WoodRenderer({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "wood.png",
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
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
      "placed-wood.png",
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
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
  if (item.contains(".") && item.substring(0, item.indexOf(".")) == "ore") {
    if (item == stone) {
      return StoneRenderer(
        width: width,
        height: height,
      );
    } else {
      return OreRenderer(
        color: oreColors[item.substring(item.indexOf(".") + 1)]!,
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
  return Text(
    "unknown key $item",
    style: const TextStyle(color: Colors.red),
  );
}

Widget renderEntity(Entity entity,
    {required double width, required double height, bool ghost = false}) {
  if (entity is Miner) {
    return MinerRenderer(width: width, height: height, ghost: ghost);
  }
  if (entity is Robot) {
    return RobotRenderer(width: width, height: height, ghost: ghost);
  }
  if (entity is Table) {
    return TableRenderer(width: width, height: height, ghost: ghost);
  }
  return Text(
    "unknown entity $entity",
    style: const TextStyle(color: Colors.red),
  );
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
      "robot.png",
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
      "miner.png",
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

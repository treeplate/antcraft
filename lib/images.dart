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

Row parseInlinedIcons(String text, [double size = 30]) {
  List<Widget> result = [];
  StringBuffer buffer = StringBuffer();
  bool parsingKey = false;
  for (int rune in text.runes) {
    if (parsingKey) {
      if (rune == 0x7D) {
        result.add(renderItem(buffer.toString(), width: size, height: size));
        buffer = StringBuffer();
        parsingKey = false;
      } else {
        buffer.writeCharCode(rune);
      }
    } else {
      if (rune == 0x7B) {
        result.add(Text(
          buffer.toString(),
          style: TextStyle(fontSize: size, color: Colors.white),
        ));
        buffer = StringBuffer();
        parsingKey = true;
      } else {
        buffer.writeCharCode(rune);
      }
    }
  }
  if (parsingKey) {
    result.add(renderItem(buffer.toString(), width: size, height: size));
  } else {
    result.add(Text(
      buffer.toString(),
      style: TextStyle(fontSize: size, color: Colors.white),
    ));
  }
  return Row(
    children: result,
    mainAxisSize: MainAxisSize.min,
  );
}

class InventoryWidget extends StatelessWidget {
  final List<ItemStack> inventory;
  final void Function(ItemStack)? callback;
  const InventoryWidget({Key? key, required this.inventory, this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int borderSize = 2;
    int imageSize = 30;
    int cellSize = (imageSize + borderSize * 2);
    return Container(
      color: Colors.black,
      width: 10 * cellSize / 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            "Inventory",
            style: TextStyle(color: Colors.white),
          ),
          const Divider(
            color: Colors.white,
          ),
          Stack(
            children: [
              Wrap(
                children: inventory
                    .map(
                      (e) => ColoredBox(
                        color: Colors.green,
                        child: Padding(
                          padding: EdgeInsets.all(borderSize / 1),
                          child: GestureDetector(
                            child: ColoredBox(
                              color: Colors.black,
                              child: renderItem(
                                e.item,
                                width: imageSize / 1,
                                height: imageSize / 1,
                              ),
                            ),
                            onTap: callback != null
                                ? () {
                                    callback!(e);
                                  }
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              IgnorePointer(
                child: Wrap(
                  children: inventory
                      .map(
                        (e) => SizedBox(
                          width: cellSize / 1,
                          height: cellSize / 1,
                          child: Center(
                            child: Text(
                              e.count.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        ],
      ),
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
  if (item == box) {
    return BoxRenderer(
      width: width,
      height: height,
    );
  }
  if (item == planter) {
    return PlanterRenderer(
      width: width,
      height: height,
    );
  }
  if (item == chopper) {
    return ChopperRenderer(
      width: width,
      height: height,
    );
  }
  if (item == antenna) {
    return AntennaRenderer(
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
    case EntityType.box:
      return BoxRenderer(width: width, height: height, ghost: ghost);
    case EntityType.planter:
      return PlanterRenderer(width: width, height: height, ghost: ghost);
    case EntityType.chopper:
      return ChopperRenderer(width: width, height: height, ghost: ghost);
    case EntityType.antenna:
      return AntennaRenderer(width: width, height: height, ghost: ghost);
  }
}

class BoxRenderer extends StatelessWidget {
  const BoxRenderer({
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
      'images/box.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class PlanterRenderer extends StatelessWidget {
  const PlanterRenderer({
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
      'images/auto-planter.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class ChopperRenderer extends StatelessWidget {
  const ChopperRenderer({
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
      'images/auto-chopper.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
    );
  }
}

class AntennaRenderer extends StatelessWidget {
  const AntennaRenderer({
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
      'images/antenna.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      opacity: ghost ? const AlwaysStoppedAnimation(.5) : null,
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

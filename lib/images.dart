import 'package:flutter/material.dart';

Map<String, MaterialColor> oreColors = {
  "iron": Colors.blue,
  "stone": Colors.grey,
};

class OreRenderer extends StatelessWidget {
  const OreRenderer({
    Key? key,
    required this.color,
    required this.smelted,
    required this.width,
    required this.height,
  }) : super(key: key);
  final MaterialColor color;
  final bool smelted;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color[smelted ? 600 : 800],
        borderRadius: BorderRadius.circular(smelted ? 0 : 10),
      ),
    );
  }
}

class WoodRenderer extends StatelessWidget {
  const WoodRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.placed = false,
  }) : super(key: key);
  final double width;
  final double height;
  final bool placed;
  @override
  Widget build(BuildContext context) {
    return placed
        ? Image.asset(
            "placed-wood.png",
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          )
        : Image.asset(
            "wood.png",
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          );
  }
}

class FurnaceRenderer extends StatelessWidget {
  const FurnaceRenderer({
    Key? key,
    required this.width,
    required this.height,
    this.placed = "none",
  }) : super(key: key);
  final double width;
  final double height;
  final String placed;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          "furnace.png",
          width: width,
          height: height,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),
        Positioned(
          left: 11 / 19 * width,
          top: 6 / 19 * height,
          child: ItemRenderer(
            placed,
            width: 4 / 19 * width,
            height: 4 / 19 * height,
          ),
        )
      ],
    );
  }
}

class ItemRenderer extends StatelessWidget {
  final String item;

  const ItemRenderer(this.item,
      {Key? key, required this.width, required this.height})
      : super(key: key);
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (item.contains(".") && item.substring(0, item.indexOf(".")) == "ore") {
      return OreRenderer(
        color: oreColors[item.substring(item.lastIndexOf(".") + 1)]!,
        smelted:
            !(item.substring(item.indexOf(".") + 1, item.lastIndexOf(".")) ==
                "raw"),
        height: height,
        width: width,
      );
    }
    if (item.contains(".") && item.substring(0, item.indexOf(".")) == "wood") {
      return WoodRenderer(
        placed: item.substring(item.indexOf(".") + 1) == "placed",
        height: height,
        width: width,
      );
    }
    if (item == "none") return Container();
    if (item.startsWith("furnace")) {
      return FurnaceRenderer(
        width: width,
        height: height,
        placed: "ore.raw.iron",
      );
    }
    if (item == "robot") {
      return FurnaceRenderer(
        width: width,
        height: height,
        placed: "wood.raw",
      );
    }
    return Text(
      "unknown key $item",
      style: const TextStyle(color: Colors.red),
    );
  }
}

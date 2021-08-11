import 'package:flutter/material.dart';

class OreRenderer extends StatelessWidget {
  const OreRenderer(
      {Key? key,
      required this.color,
      required this.smelted,
      required this.width,
      required this.height})
      : super(key: key);
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
  const WoodRenderer({Key? key, required this.width, required this.height})
      : super(key: key);
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

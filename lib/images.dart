import 'package:flutter/material.dart';

class OreRenderer extends StatelessWidget {
  const OreRenderer({Key? key, required this.color, required this.smelted})
      : super(key: key);
  final MaterialColor color;
  final bool smelted;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          color: color[smelted ? 600 : 800],
          borderRadius: BorderRadius.circular(smelted ? 0 : 10)),
    );
  }
}

class WoodRenderer extends StatelessWidget {
  const WoodRenderer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 5,
          color: Colors.brown[200],
        ),
        Container(
          width: 30,
          height: 25,
          color: Colors.brown,
        ),
      ],
    );
  }
}

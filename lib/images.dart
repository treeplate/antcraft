import 'package:flutter/material.dart';
// test autolabeler again
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

import 'dart:io';

class ItemStack {
  final int count;
  final String item;

  @override
  String toString() => '${count}x$item';

  ItemStack(this.count, this.item);
  factory ItemStack.parse(String input) {
    List<String> parts = input.split('x');
    return ItemStack(int.parse(parts[0]), parts[1]);
  }
}

void register(String name, String partner, List<ItemStack> Function() oldInv,
    void Function(List<ItemStack>) newInv) async {
  WebSocket s = await WebSocket.connect('ws://treeplate.damowmow.com:8010');
  s.add('register$name');
  s.forEach((element) {
    if (element == 'swap') {
      s.add('$partner:a:${oldInv().join(',')}');
    }
    if (element.startsWith('converted')) {
      List<String> parts = element.split(':');
      if (parts[1] == 'a') {
        newInv(parts[2].split(',').map((e) => ItemStack.parse(e)).toList());
      }
    }
  });
}

import 'dart:io';
import 'core.dart';

void register(String name, String partner, List<ItemStack> Function() oldInv,
    void Function(List<ItemStack>) newInv) async {
  WebSocket s = await WebSocket.connect('ws://treeplate.damowmow.com:8010');
  s.add('register$name');
  s.forEach((element) {
    if (element == 'swap') {
      s.add('sendover$partner:a:${oldInv().join(',')}');
    }
    if (element.startsWith('converted')) {
      List<String> parts = element.split(':');
      if (parts[1] == 'a') {
        newInv(parts[2].split(',').map((e) => ItemStack.parse(e)).toList());
      }
    }
  });
}

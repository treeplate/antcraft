import 'logic.dart';

String? tutorialOverride(World world) => world.tableOpen?.result == 'furnace' || world.inv['furnace'] != null ? 'next clue: in the towels' : null ;
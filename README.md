# antcraft
A 2D automation-based work-in-progress open-world game.
## Current game
- Infinite-sized inventory
- Wood:
  - natural generation: one wood item per room
  - collection: walking onto a wood item gets you that item
  - planting: for 3 wood you can plant a tree (on dirt), after some time you can chop it down for 4. 
  - usage: use the placed wood to craft other stuff
  - place: '1'
- Robots:
  - recipe: iron
  - place: '2'
  - behavior: goes and collects 5 wood and returns them to you, repeat
- Miners:
  - recipe: wood, iron
  - place: '3'
  - behavior: mines 10 of whatever's under it, you can collect what it's mined so far and reset the counter by walking on it
- Stone:
  - usage: useless
  - collection: mine some floors to get
- Iron:
  - natural generation: one patch of iron per room
  - collection: mine on that to get iron
  - usage: used in some recipes
- Dirt:
  - collection: mine some floors to get
  - place: '4'
  - usage: you can plant on stone if you're touching one of these
- Game is won when you get 100 wood
## TODO: (in order)
- https://github.com/treeplate/antcraft/projects/1?add_cards_query=is%3Aopen
## Naming
The 'ant' part of the name is for historical reasons:
At first my game was basically a snake game with no apples.
When I pointed it out to someone they said it was not a snake game but an ***ant*** game.
I may change the name.
## PRs
I am open to PRs, however, I am not especially likely to accept them.

# Build a 2D Action RPG

Build a complete action RPG from scratch using Heaps. Each tutorial adds new features to create a fully playable game.

**[Play the game online!](https://bginbey.github.io/actionRPG/)**

### Game Controls
- **Movement**: WASD or Arrow Keys
- **Attack**: J or X (3-hit combo system)
- **Dash**: Space or Shift
- **Toggle Rain**: R
- **Show/Hide Help**: H
- **Debug View**: ` (backtick)
- **Return to Menu**: ESC

## What This Series Builds

```
🎮 Complete Action RPG
├── ⚡ Player movement and dash ability
├── ⚔️ Combo-based combat system
├── 🤖 Enemy AI with multiple behaviors
├── 🗺️ Tile-based levels with collision
└── ✨ Visual effects and polish
```

## Prerequisites

- [Heaps installed](../getting-started/installation.md)
- [Hello World example working](../getting-started/hello-world.md)
- Code editor

## Tutorial Structure

### [Part 1: Foundation](01-foundation.md)
- Set up the project structure
- Write `Main.hx` that serves as the entry point and the game loop
- Build a scene manager and scene class
- Polish with smooth transitions between scenes

### [Part 2: Core Systems](02-core-systems.md)
- Create a tilemap system to render levels with 16x16 pixel tiles
- Code a camera that smoothly follows the player
- Design an entity base class for all game objects
- Add collision detection so the player can't walk through walls
- Wire up a debug overlay to visualize collision boxes and stats

### [Part 3: Player Movement](03-player-movement.md)
- Program 8-directional movement with acceleration and friction
- Develop a dash ability with cooldown timer
- Set up animation state machine for idle, walk, and dash states
- Craft a ghost trail effect using object pooling
- Fine-tune input buffering for responsive controls

### [Part 4: Combat System](04-combat-system.md)
- Design a 3-hit combo system with timing windows
- Code hitbox components for attack collision
- Calculate damage and knockback physics
- Program screen shake and hit pause for impact
- Generate particle effects for hits and combos

### [Part 5: Enemy AI](05-enemy-ai.md)
- Build AI state machines with idle, patrol, chase, and attack states
- Program line of sight detection for player awareness
- Design multiple enemy types with different behaviors
- Set up a health system with damage and healing
- Polish with death animations and loot drops

## Project Structure

```
my-action-rpg/
├── src/
│   ├── Main.hx              # Entry point
│   ├── Game.hx              # Game coordinator
│   ├── scenes/              # Menu, Gameplay, etc.
│   ├── entities/            # Player, enemies
│   ├── components/          # Reusable behaviors
│   ├── systems/             # Game systems
│   └── utils/               # Helper classes
├── res/                     # Assets
│   ├── sprites/
│   ├── sounds/
│   └── data/
└── build.hxml               # Build configuration
```

## Code Style

```haxe
// Clear variable names
var playerSpeed = 150.0;
var dashCooldown = 0.3;

// Constants for configuration
class GameConfig {
    public static inline var TILE_SIZE = 16;
    public static inline var PLAYER_SPEED = 150.0;
}

// Small, focused functions
function updatePlayer(dt:Float) {
    handleInput(dt);
    updatePhysics(dt);
    updateAnimation(dt);
}
```

## Performance Targets

- 60 FPS with 50+ enemies
- < 100MB memory usage
- < 1000 draw calls

## Getting Started

Begin with [Part 1: Foundation →](01-foundation.md)

Next up: [Part 1: Foundation](01-foundation.md)

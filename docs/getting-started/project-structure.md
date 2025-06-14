# Project Structure

A well-organized project structure is crucial for maintainable game development. Here's how to structure a Heaps project for success.

## Recommended Structure

```
my-game/
├── src/                    # Source code
│   ├── Main.hx            # Entry point
│   ├── Game.hx            # Core game class
│   ├── scenes/            # Game scenes/states
│   ├── entities/          # Game objects
│   ├── components/        # Reusable components
│   ├── systems/           # Game systems
│   ├── ui/                # UI elements
│   └── utils/             # Helper classes
├── res/                    # Resources (auto-imported)
│   ├── sprites/           # Images and animations
│   ├── fonts/             # Bitmap fonts
│   ├── sounds/            # Audio files
│   ├── music/             # Background music
│   ├── data/              # JSON/XML data files
│   └── shaders/           # HXSL shader files
├── bin/                    # Build output
├── tools/                  # Build scripts, asset pipeline
├── docs/                   # Documentation
├── build.hxml             # HashLink build config
├── build-web.hxml         # Web build config
├── .gitignore
└── README.md
```

## The Resource System

Heaps automatically imports everything in the `res/` folder:

```haxe
// Access resources via hxd.Res
var playerSprite = hxd.Res.sprites.player_png;
var font = hxd.Res.fonts.pixel_fnt;
var levelData = hxd.Res.data.level1_json;
```

### Resource Initialization

Add to your build.hxml:
```hxml
-resource res/sprites/player.png@sprites.player_png
# Or use automatic import:
-D resourcePath=res
```

Initialize in your Main class:
```haxe
class Main extends hxd.App {
    override function init() {
        // Initialize resource system
        hxd.Res.initEmbed();
        
        // Now use resources
        var tile = hxd.Res.sprites.player_png.toTile();
    }
}
```

## Core Architecture

### Main.hx - Entry Point
```haxe
class Main extends hxd.App {
    public static var instance : Main;
    var game : Game;
    
    override function init() {
        instance = this;
        
        // Initialize resources
        hxd.Res.initEmbed();
        
        // Configure engine
        engine.backgroundColor = 0x1a1a2e;
        
        // Start game
        game = new Game();
    }
    
    override function update(dt:Float) {
        game.update(dt);
    }
    
    static function main() {
        new Main();
    }
}
```

### Game.hx - Game Manager
```haxe
class Game {
    var sceneManager : SceneManager;
    
    public function new() {
        sceneManager = new SceneManager();
        sceneManager.switchTo(new MenuScene());
    }
    
    public function update(dt:Float) {
        sceneManager.update(dt);
    }
}
```

## Scene Management

### scenes/Scene.hx - Base Scene
```haxe
package scenes;

class Scene extends h2d.Object {
    var game : Game;
    
    public function new() {
        super(Main.instance.s2d);
        game = Main.instance.game;
    }
    
    public function update(dt:Float) {
        // Override in subclasses
    }
    
    public function onEnter() {
        // Called when scene becomes active
    }
    
    public function onExit() {
        // Called when leaving scene
    }
    
    public function dispose() {
        remove();
    }
}
```

### scenes/GameScene.hx - Gameplay
```haxe
package scenes;

class GameScene extends Scene {
    var player : entities.Player;
    var enemies : Array<entities.Enemy> = [];
    
    override function onEnter() {
        // Create game world
        createLevel();
        
        // Spawn player
        player = new entities.Player(this);
        player.x = 100;
        player.y = 100;
    }
    
    override function update(dt:Float) {
        player.update(dt);
        
        for (enemy in enemies) {
            enemy.update(dt);
        }
    }
    
    function createLevel() {
        // Load tilemap, spawn enemies, etc.
    }
}
```

## Entity System

### entities/Entity.hx - Base Entity
```haxe
package entities;

class Entity extends h2d.Object {
    public var velocity : h2d.col.Point;
    public var health : Int = 100;
    
    public function new(?parent:h2d.Object) {
        super(parent);
        velocity = new h2d.col.Point();
    }
    
    public function update(dt:Float) {
        x += velocity.x * dt;
        y += velocity.y * dt;
    }
    
    public function takeDamage(amount:Int) {
        health -= amount;
        if (health <= 0) {
            destroy();
        }
    }
    
    public function destroy() {
        remove();
    }
}
```

## Configuration Files

### build.hxml - HashLink Build
```hxml
-cp src
-lib heaps
-lib hlsdl
-hl bin/game.hl
-main Main
-D resourcePath=res
-D windowTitle=My Awesome Game
-D windowSize=1280x720
```

### build-web.hxml - Web Build
```hxml
-cp src
-lib heaps
-js bin/game.js
-main Main
-D resourcePath=res
-dce full
-D analyzer-optimize
```

### .gitignore
```
bin/
.DS_Store
*.hl
.vscode/*
!.vscode/tasks.json
!.vscode/launch.json
```

## Asset Pipeline

### Texture Atlases
Create `tools/pack-atlas.hxml`:
```hxml
-lib heaps
-lib hxp
-main PackAtlas
-neko pack-atlas.n

--next

-cmd neko pack-atlas.n
```

### Automatic Import
Configure in `res/.heaps`:
```json
{
    "props": {
        "sprites": {
            "alpha": true,
            "filter": false
        },
        "fonts": {
            "convert": "fnt"
        }
    }
}
```

## Best Practices

### 1. Separation of Concerns
- **Entities**: Game objects (player, enemies, items)
- **Components**: Reusable behaviors (health, movement, AI)
- **Systems**: Game-wide managers (collision, particles, audio)
- **Scenes**: Game states (menu, gameplay, game over)

### 2. Resource Management
```haxe
// Create a resource manager
class Assets {
    public static var playerTile : h2d.Tile;
    public static var enemyTile : h2d.Tile;
    public static var font : h2d.Font;
    
    public static function init() {
        playerTile = hxd.Res.sprites.player_png.toTile();
        enemyTile = hxd.Res.sprites.enemy_png.toTile();
        font = hxd.Res.fonts.pixel_fnt.toFont();
    }
}
```

### 3. Constants
```haxe
// utils/Constants.hx
package utils;

class Constants {
    // Gameplay
    public static inline var PLAYER_SPEED = 200.0;
    public static inline var DASH_DISTANCE = 100.0;
    public static inline var GRAVITY = 980.0;
    
    // Display
    public static inline var TILE_SIZE = 16;
    public static inline var SCREEN_WIDTH = 1280;
    public static inline var SCREEN_HEIGHT = 720;
    
    // Layers
    public static inline var LAYER_BACKGROUND = 0;
    public static inline var LAYER_WORLD = 1;
    public static inline var LAYER_ENTITIES = 2;
    public static inline var LAYER_UI = 3;
}
```

### 4. Debug Configuration
```haxe
// In debug builds
#if debug
trace("Debug mode enabled");
s2d.addChild(new h2d.FPS());
#end
```

## Example: Complete Game Structure

Here's how a simple game might use this structure:

```haxe
// Main.hx
class Main extends hxd.App {
    public static var instance : Main;
    
    override function init() {
        instance = this;
        hxd.Res.initEmbed();
        Assets.init();
        
        SceneManager.init();
        SceneManager.switchTo(new scenes.MenuScene());
    }
    
    override function update(dt:Float) {
        SceneManager.update(dt);
    }
    
    static function main() {
        new Main();
    }
}

// scenes/MenuScene.hx
package scenes;

class MenuScene extends Scene {
    override function onEnter() {
        var title = new h2d.Text(Assets.font, this);
        title.text = "MY GAME";
        title.center();
        
        var startBtn = new ui.Button("Start Game", this);
        startBtn.onClick = () -> {
            SceneManager.switchTo(new GameScene());
        };
    }
}

// entities/Player.hx  
package entities;

class Player extends Entity {
    var sprite : h2d.Bitmap;
    
    public function new(?parent) {
        super(parent);
        
        sprite = new h2d.Bitmap(Assets.playerTile, this);
        sprite.center();
    }
    
    override function update(dt:Float) {
        // Handle input
        if (hxd.Key.isDown(hxd.Key.LEFT)) {
            velocity.x = -Constants.PLAYER_SPEED;
        }
        
        super.update(dt);
    }
}
```

## Next Steps

With a solid project structure in place, you're ready to dive into [Core Concepts →](../core-concepts/game-loop.md) and start building your game!
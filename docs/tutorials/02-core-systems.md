# Part 2: Core Systems

Let's build the game world! We'll add a tilemap system, camera, entities, and collision detection to create a playable environment.

## What We're Building

- Create a tilemap system to render levels with 16x16 pixel tiles
- Code a camera that smoothly follows the player
- Design an entity base class for all game objects
- Add collision detection so the player can't walk through walls
- Wire up a debug overlay to visualize collision boxes and stats

## Step 1: Create the Tilemap System

A tilemap uses small images (tiles) to build larger levels efficiently. [Dive deeper into how tilemap systems work](../dive-deeper/tilemap-systems.md).

Create `src/systems/Tilemap.hx`:

```haxe
package systems;

class Tilemap extends h2d.Object {
    // Size of each tile in pixels
    public static inline var TILE_SIZE = 16;
    
    // Level dimensions in tiles
    var widthInTiles : Int;
    var heightInTiles : Int;
    
    // Visual representation
    var tileGroup : h2d.TileGroup;
    
    // Collision data (0 = empty, 1 = solid)
    var collisionData : Array<Int>;
    
    public function new(parent:h2d.Object) {
        super(parent);
    }
    
    // Load a level from array data
    public function loadLevel(width:Int, height:Int, tiles:Array<Int>) {
        widthInTiles = width;
        heightInTiles = height;
        collisionData = tiles.copy();
        
        // Create visual tiles
        buildVisuals();
    }
    
    function buildVisuals() {
        // Remove old tiles if any
        if (tileGroup != null) {
            tileGroup.remove();
        }
        
        // Create tile graphics - using colored squares for now
        var whiteTile = h2d.Tile.fromColor(0xFFFFFF, TILE_SIZE, TILE_SIZE);
        tileGroup = new h2d.TileGroup(whiteTile, this);
        
        // Build the level
        for (y in 0...heightInTiles) {
            for (x in 0...widthInTiles) {
                var tileIndex = getTile(x, y);
                
                if (tileIndex == 1) {
                    // Add a wall tile
                    tileGroup.add(
                        x * TILE_SIZE,
                        y * TILE_SIZE,
                        whiteTile
                    );
                }
            }
        }
    }
    
    // Get tile at grid position
    public function getTile(x:Int, y:Int) : Int {
        if (x < 0 || x >= widthInTiles || y < 0 || y >= heightInTiles) {
            return 1; // Treat out of bounds as solid
        }
        return collisionData[y * widthInTiles + x];
    }
    
    // Check if a world position is solid
    public function isSolid(worldX:Float, worldY:Float) : Bool {
        var tileX = Math.floor(worldX / TILE_SIZE);
        var tileY = Math.floor(worldY / TILE_SIZE);
        return getTile(tileX, tileY) == 1;
    }
    
    // Convert world position to tile coordinates
    public function worldToTile(worldX:Float, worldY:Float) : {x:Int, y:Int} {
        return {
            x: Math.floor(worldX / TILE_SIZE),
            y: Math.floor(worldY / TILE_SIZE)
        };
    }
}
```

## Step 2: Create a Test Level

Let's define a simple level. Create `src/data/Levels.hx`:

```haxe
package data;

class Levels {
    // Test level - 20x15 tiles
    // 0 = empty, 1 = wall
    public static var testLevel = {
        width: 20,
        height: 15,
        tiles: [
            1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
            1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
            1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
            1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1,
            1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
            1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
            1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1,
            1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
            1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1,
            1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
            1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
            1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1,
            1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
            1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
            1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        ]
    };
}
```

## Step 3: Create the Camera System

The camera determines what part of the world is visible. Create `src/systems/Camera.hx`:

```haxe
package systems;

class Camera {
    // The scene layer being controlled
    var scene : h2d.Layers;
    
    // Camera position (center of view)
    public var x : Float = 0;
    public var y : Float = 0;
    
    // Viewport size
    var viewWidth : Int;
    var viewHeight : Int;
    
    // Bounds to keep camera inside
    var boundsLeft : Float = 0;
    var boundsTop : Float = 0;
    var boundsRight : Float = 1000;
    var boundsBottom : Float = 1000;
    
    // Smooth follow
    var target : h2d.Object;
    var followSpeed : Float = 0.1;
    
    public function new(scene:h2d.Layers, viewWidth:Int, viewHeight:Int) {
        this.scene = scene;
        this.viewWidth = viewWidth;
        this.viewHeight = viewHeight;
    }
    
    // Set level bounds
    public function setBounds(left:Float, top:Float, right:Float, bottom:Float) {
        boundsLeft = left;
        boundsTop = top;
        boundsRight = right;
        boundsBottom = bottom;
    }
    
    // Follow a target smoothly
    public function follow(target:h2d.Object, speed=0.1) {
        this.target = target;
        this.followSpeed = speed;
    }
    
    // Update camera position
    public function update(dt:Float) {
        if (target != null) {
            // Smoothly move toward target
            x += (target.x - x) * followSpeed;
            y += (target.y - y) * followSpeed;
        }
        
        // Keep camera in bounds
        var halfWidth = viewWidth * 0.5;
        var halfHeight = viewHeight * 0.5;
        
        x = Math.max(boundsLeft + halfWidth, Math.min(boundsRight - halfWidth, x));
        y = Math.max(boundsTop + halfHeight, Math.min(boundsBottom - halfHeight, y));
        
        // Apply to scene
        scene.x = -x + halfWidth;
        scene.y = -y + halfHeight;
    }
    
    // Instantly center on position
    public function centerOn(x:Float, y:Float) {
        this.x = x;
        this.y = y;
        update(0);
    }
    
    // Check if object is visible
    public function isVisible(obj:h2d.Object, margin=50) : Bool {
        var halfWidth = viewWidth * 0.5 + margin;
        var halfHeight = viewHeight * 0.5 + margin;
        
        return obj.x > x - halfWidth && obj.x < x + halfWidth &&
               obj.y > y - halfHeight && obj.y < y + halfHeight;
    }
}
```

## Step 4: Build the Entity System

Entities are game objects with position, velocity, and collision. Create `src/entities/Entity.hx`:

```haxe
package entities;

class Entity extends h2d.Object {
    // Movement
    public var vx : Float = 0;
    public var vy : Float = 0;
    
    // Collision box (relative to position)
    public var collisionBox : {
        x:Float,      // Offset from entity x
        y:Float,      // Offset from entity y
        width:Float,
        height:Float
    };
    
    // Reference to tilemap for collision
    var tilemap : systems.Tilemap;
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Default collision box
        collisionBox = {
            x: -8,
            y: -8,
            width: 16,
            height: 16
        };
    }
    
    // Set the tilemap for collision checking
    public function setTilemap(tm:systems.Tilemap) {
        tilemap = tm;
    }
    
    // Update physics
    public function update(dt:Float) {
        // Store old position
        var oldX = x;
        var oldY = y;
        
        // Try to move horizontally
        x += vx * dt;
        if (tilemap != null && checkTilemapCollision()) {
            x = oldX; // Cancel horizontal movement
        }
        
        // Try to move vertically
        y += vy * dt;
        if (tilemap != null && checkTilemapCollision()) {
            y = oldY; // Cancel vertical movement
        }
    }
    
    // Check collision with tilemap
    function checkTilemapCollision() : Bool {
        // Get collision box corners in world space
        var left = x + collisionBox.x;
        var right = left + collisionBox.width;
        var top = y + collisionBox.y;
        var bottom = top + collisionBox.height;
        
        // Check all four corners
        return tilemap.isSolid(left, top) ||
               tilemap.isSolid(right, top) ||
               tilemap.isSolid(left, bottom) ||
               tilemap.isSolid(right, bottom);
    }
    
    // Get world bounds
    public function getBounds() : {x:Float, y:Float, width:Float, height:Float} {
        return {
            x: x + collisionBox.x,
            y: y + collisionBox.y,
            width: collisionBox.width,
            height: collisionBox.height
        };
    }
}
```

## Step 5: Update GameScene

Now let's use these systems in the game. Update `src/GameScene.hx`:

```haxe
package scenes;

import systems.Tilemap;
import systems.Camera;
import entities.Entity;

class GameScene extends Scene {
    // Game layers
    var world : h2d.Layers;
    
    // Systems
    var tilemap : Tilemap;
    var camera : Camera;
    
    // Entities
    var player : Entity;
    
    public function new() {
        super(GameConfig.SCENE_GAME);
    }
    
    override function onEnter() {
        super.onEnter();
        
        // Create world container
        world = new h2d.Layers(this);
        
        // Setup systems
        setupTilemap();
        setupCamera();
        setupPlayer();
        
        // UI stays on top
        setupUI();
    }
    
    function setupTilemap() {
        tilemap = new Tilemap(world);
        tilemap.loadLevel(
            data.Levels.testLevel.width,
            data.Levels.testLevel.height,
            data.Levels.testLevel.tiles
        );
    }
    
    function setupCamera() {
        camera = new Camera(world, GameConfig.GAME_WIDTH, GameConfig.GAME_HEIGHT);
        
        // Set bounds based on level size
        camera.setBounds(
            0, 0,
            tilemap.widthInTiles * Tilemap.TILE_SIZE,
            tilemap.heightInTiles * Tilemap.TILE_SIZE
        );
    }
    
    function setupPlayer() {
        // Create player with a green square
        player = new Entity(world);
        player.setTilemap(tilemap);
        
        var sprite = new h2d.Bitmap(h2d.Tile.fromColor(0x00FF00, 14, 14), player);
        sprite.x = -7; // Center the sprite
        sprite.y = -7;
        
        // Start in center of level
        player.x = tilemap.widthInTiles * Tilemap.TILE_SIZE * 0.5;
        player.y = tilemap.heightInTiles * Tilemap.TILE_SIZE * 0.5;
        
        // Smaller collision box
        player.collisionBox = {
            x: -6,
            y: -6,
            width: 12,
            height: 12
        };
        
        // Camera follows player
        camera.follow(player, 0.1);
        camera.centerOn(player.x, player.y); // Start centered
    }
    
    function setupUI() {
        // Instructions (stays on screen)
        var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
        text.text = "Arrow keys to move, TAB for debug";
        text.x = 10;
        text.y = 10;
    }
    
    override function update(dt:Float) {
        // Player input
        handleInput(dt);
        
        // Update systems
        player.update(dt);
        camera.update(dt);
        
        // Return to menu
        if (hxd.Key.isPressed(hxd.Key.ESCAPE)) {
            Main.instance.sceneManager.switchTo(GameConfig.SCENE_MENU);
        }
    }
    
    function handleInput(dt:Float) {
        // Reset velocity
        player.vx = 0;
        player.vy = 0;
        
        // Movement
        var speed = 100;
        if (hxd.Key.isDown(hxd.Key.LEFT))  player.vx = -speed;
        if (hxd.Key.isDown(hxd.Key.RIGHT)) player.vx = speed;
        if (hxd.Key.isDown(hxd.Key.UP))    player.vy = -speed;
        if (hxd.Key.isDown(hxd.Key.DOWN))  player.vy = speed;
        
        // Diagonal movement should be same speed
        if (player.vx != 0 && player.vy != 0) {
            player.vx *= 0.707; // 1/sqrt(2)
            player.vy *= 0.707;
        }
    }
}
```

## Step 6: Add Debug Visualization

Let's add a debug overlay to see collision boxes. Create `src/systems/DebugDisplay.hx`:

```haxe
package systems;

class DebugDisplay extends h2d.Object {
    var graphics : h2d.Graphics;
    var enabled = false;
    
    // What to show
    var showCollision = true;
    var showGrid = false;
    var showStats = true;
    
    // References
    var camera : Camera;
    var tilemap : Tilemap;
    var entities : Array<entities.Entity> = [];
    
    // Stats
    var statsText : h2d.Text;
    var fps = 0.0;
    var frameCount = 0;
    var frameTime = 0.0;
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        graphics = new h2d.Graphics(this);
        
        // Stats display
        statsText = new h2d.Text(hxd.res.DefaultFont.get(), this);
        statsText.x = 10;
        statsText.y = 30;
        statsText.textColor = 0x00FF00;
    }
    
    public function toggle() {
        enabled = !enabled;
        visible = enabled;
    }
    
    public function setReferences(camera:Camera, tilemap:Tilemap) {
        this.camera = camera;
        this.tilemap = tilemap;
    }
    
    public function addEntity(e:entities.Entity) {
        entities.push(e);
    }
    
    public function update(dt:Float) {
        if (!enabled) return;
        
        // Update FPS counter
        frameCount++;
        frameTime += dt;
        if (frameTime >= 1.0) {
            fps = frameCount / frameTime;
            frameCount = 0;
            frameTime = 0;
        }
        
        // Clear previous frame
        graphics.clear();
        
        // Draw based on settings
        if (showGrid) drawGrid();
        if (showCollision) drawCollision();
        if (showStats) updateStats();
    }
    
    function drawGrid() {
        graphics.lineStyle(1, 0x333333, 0.3);
        
        // Calculate visible area
        var startX = Math.floor((camera.x - GameConfig.GAME_WIDTH * 0.5) / Tilemap.TILE_SIZE);
        var endX = Math.ceil((camera.x + GameConfig.GAME_WIDTH * 0.5) / Tilemap.TILE_SIZE);
        var startY = Math.floor((camera.y - GameConfig.GAME_HEIGHT * 0.5) / Tilemap.TILE_SIZE);
        var endY = Math.ceil((camera.y + GameConfig.GAME_HEIGHT * 0.5) / Tilemap.TILE_SIZE);
        
        // Draw vertical lines
        for (x in startX...endX + 1) {
            var worldX = x * Tilemap.TILE_SIZE;
            graphics.moveTo(worldX + camera.scene.x, 0);
            graphics.lineTo(worldX + camera.scene.x, GameConfig.GAME_HEIGHT);
        }
        
        // Draw horizontal lines
        for (y in startY...endY + 1) {
            var worldY = y * Tilemap.TILE_SIZE;
            graphics.moveTo(0, worldY + camera.scene.y);
            graphics.lineTo(GameConfig.GAME_WIDTH, worldY + camera.scene.y);
        }
    }
    
    function drawCollision() {
        // Entity collision boxes
        graphics.lineStyle(2, 0xFF0000, 0.8);
        
        for (entity in entities) {
            if (!camera.isVisible(entity)) continue;
            
            var bounds = entity.getBounds();
            graphics.drawRect(
                bounds.x + camera.scene.x,
                bounds.y + camera.scene.y,
                bounds.width,
                bounds.height
            );
        }
        
        // Tilemap collision (only visible tiles)
        graphics.lineStyle(1, 0x0000FF, 0.5);
        
        var startX = Math.floor((camera.x - GameConfig.GAME_WIDTH * 0.5) / Tilemap.TILE_SIZE) - 1;
        var endX = Math.ceil((camera.x + GameConfig.GAME_WIDTH * 0.5) / Tilemap.TILE_SIZE) + 1;
        var startY = Math.floor((camera.y - GameConfig.GAME_HEIGHT * 0.5) / Tilemap.TILE_SIZE) - 1;
        var endY = Math.ceil((camera.y + GameConfig.GAME_HEIGHT * 0.5) / Tilemap.TILE_SIZE) + 1;
        
        for (y in startY...endY) {
            for (x in startX...endX) {
                if (tilemap.getTile(x, y) == 1) {
                    graphics.drawRect(
                        x * Tilemap.TILE_SIZE + camera.scene.x,
                        y * Tilemap.TILE_SIZE + camera.scene.y,
                        Tilemap.TILE_SIZE,
                        Tilemap.TILE_SIZE
                    );
                }
            }
        }
    }
    
    function updateStats() {
        statsText.text = 'FPS: ${Math.round(fps)}
Entities: ${entities.length}
Camera: ${Math.round(camera.x)},${Math.round(camera.y)}';
    }
}
```

## Step 7: Integrate Debug Display

Update `GameScene.hx` to use the debug display:

```haxe
// Add to GameScene class:
var debugDisplay : systems.DebugDisplay;

// In onEnter(), after setupUI():
function setupDebug() {
    debugDisplay = new systems.DebugDisplay(this);
    debugDisplay.setReferences(camera, tilemap);
    debugDisplay.addEntity(player);
}

// In update(), add:
if (hxd.Key.isPressed(hxd.Key.TAB)) {
    debugDisplay.toggle();
}
debugDisplay.update(dt);
```

## Step 8: Test the Game

Build and run:
```bash
haxe build.hxml && hl bin/game.hl
```

The game should display:
- A level made of white tiles forming rooms
- A green square (player) that moves with arrow keys
- Camera follows the player smoothly
- Player can't move through walls
- Press TAB to see debug visualization

## Common Issues

**Player stuck in walls?**
- Check collision box size matches sprite
- Ensure starting position isn't inside a wall
- Verify tilemap data is correct

**Camera jittery?**
- Increase camera follow speed (closer to 1.0)
- Make sure camera update happens after player update

**Can't see anything?**
- Check layer ordering (world should be child of scene)
- Verify camera bounds are set correctly
- Ensure tilemap visual building works

## Go Further

1. **Different Tile Types**: 
   - Add multiple tile types (floor, wall, water)
   - Use different colors for each type
   - Make water tiles slow the player

2. **Better Camera**:
   - Add camera shake function
   - Implement camera zones (areas with different behavior)
   - Add smooth zoom in/out

3. **Entity Improvements**:
   - Add gravity to entities
   - Implement entity-to-entity collision
   - Create pickup items

## What We Did

- **Tilemap System**: Efficient level rendering with tiles
- **Camera Control**: Smooth following and boundary constraints
- **Entity Architecture**: Base class for game objects
- **Collision Detection**: Tile-based collision checking
- **Debug Tools**: Visualizing invisible game systems
- **Layer Management**: Organizing visual elements

## Next Steps

Great work! The game now has:

- A proper game world with collision
- Smooth camera movement
- Reusable entity system
- Debug visualization tools

In [Part 3: Player Movement](03-player-movement.md), we'll add smooth acceleration and friction, dash ability with effects, animation system, and input buffering.

Next up: [Part 3: Player Movement](03-player-movement.md) 
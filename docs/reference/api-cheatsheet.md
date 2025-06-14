# API Cheatsheet

Quick reference for the most commonly used Heaps APIs.

## Display Objects

### Basic Objects
```haxe
// Create objects
var bitmap = new h2d.Bitmap(tile, parent);
var text = new h2d.Text(font, parent);
var graphics = new h2d.Graphics(parent);
var object = new h2d.Object(parent);

// Position and transform
obj.x = 100;
obj.y = 50;
obj.rotation = Math.PI / 4;
obj.scaleX = 2;
obj.scaleY = 2;
obj.alpha = 0.5;
obj.visible = false;

// Remove from parent
obj.remove();
```

### Graphics Drawing
```haxe
var g = new h2d.Graphics(parent);
g.clear();
g.beginFill(0xFF0000, 0.5);
g.drawRect(0, 0, 100, 50);
g.drawCircle(50, 50, 25);
g.endFill();

g.lineStyle(2, 0x00FF00);
g.moveTo(0, 0);
g.lineTo(100, 100);
```

## Resources

### Loading Resources
```haxe
// Initialize resources
hxd.Res.initEmbed();
hxd.Res.initLocal();

// Load images
var tile = hxd.Res.player.toTile();
var texture = hxd.Res.background.toTexture();

// Load fonts
var font = hxd.Res.fonts.pixel.toFont();
var font = hxd.res.DefaultFont.get();

// Load sounds
var sound = hxd.Res.sounds.jump.toSound();
```

## Tiles and Bitmaps

### Working with Tiles
```haxe
// Create tiles
var tile = h2d.Tile.fromColor(0xFF0000, 32, 32);
var tile = h2d.Tile.fromTexture(texture);

// Modify tiles
tile.center(); // Center pivot point
var subTile = tile.sub(x, y, w, h); // Create sub-tile

// Tile groups for batching
var tileGroup = new h2d.TileGroup(tile, parent);
tileGroup.add(x, y, tile);
tileGroup.clear();
```

## Input Handling

### Keyboard
```haxe
// Check key states
if (hxd.Key.isDown(hxd.Key.LEFT)) { }
if (hxd.Key.isPressed(hxd.Key.SPACE)) { }
if (hxd.Key.isReleased(hxd.Key.ESCAPE)) { }

// Common key codes
hxd.Key.LEFT, RIGHT, UP, DOWN
hxd.Key.SPACE, ENTER, ESCAPE, TAB
hxd.Key.A-Z, NUMBER_0-9
hxd.Key.SHIFT, CTRL, ALT
```

### Mouse
```haxe
// Get mouse position
var mouseX = s2d.mouseX;
var mouseY = s2d.mouseY;

// Interactive objects
var interactive = new h2d.Interactive(width, height, parent);
interactive.onClick = function(e) { }
interactive.onOver = function(e) { }
interactive.onOut = function(e) { }
```

## Scene Management

### Creating Scenes
```haxe
class MyScene extends h2d.Scene {
    override function init() {
        // Setup scene
    }
    
    override function update(dt:Float) {
        // Update logic
    }
}

// Switch scenes
s2d.dispose();
s2d = new MyScene();
```

## Animation

### Animated Sprites
```haxe
// Create animation
var tiles = [tile1, tile2, tile3];
var anim = new h2d.Anim(tiles, 15, parent);
anim.loop = true;
anim.speed = 10;
anim.pause = false;

// Control playback
anim.play(tiles);
anim.currentFrame = 0;
```

## Sound

### Playing Sounds
```haxe
// Play sound once
var channel = sound.play();
channel.volume = 0.5;
channel.stop();

// Background music
var music = sound.play(true); // Loop
music.fadeTo(0, 2); // Fade out over 2 seconds
```

## Collision Detection

### Simple AABB Collision
```haxe
// Check bounds overlap
function collides(a:h2d.Object, b:h2d.Object):Bool {
    var boundsA = a.getBounds();
    var boundsB = b.getBounds();
    return boundsA.intersects(boundsB);
}

// Manual AABB check
function checkAABB(x1:Float, y1:Float, w1:Float, h1:Float,
                   x2:Float, y2:Float, w2:Float, h2:Float):Bool {
    return x1 < x2 + w2 && x1 + w1 > x2 && 
           y1 < y2 + h2 && y1 + h1 > y2;
}
```

## Common Patterns

### Game Loop
```haxe
class Main extends hxd.App {
    override function init() {
        // Setup
    }
    
    override function update(dt:Float) {
        // Update each frame
    }
    
    static function main() {
        new Main();
    }
}
```

### Object Pooling
```haxe
class Pool<T> {
    var available:Array<T> = [];
    var active:Array<T> = [];
    
    function get():T {
        return available.pop() ?? createNew();
    }
    
    function recycle(obj:T) {
        active.remove(obj);
        available.push(obj);
    }
}
```

### State Machine
```haxe
enum State {
    Idle;
    Moving;
    Jumping;
}

class Player {
    var state:State = Idle;
    
    function changeState(newState:State) {
        // Exit old state
        switch(state) {
            case Idle: // cleanup
            case _:
        }
        
        state = newState;
        
        // Enter new state
        switch(state) {
            case Moving: // setup
            case _:
        }
    }
}
```

## Useful Math

### Common Operations
```haxe
// Distance between points
var dist = Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2));
var dist = hxd.Math.distance(x1, y1, x2, y2);

// Angle between points
var angle = Math.atan2(y2-y1, x2-x1);

// Lerp (linear interpolation)
var lerp = (a, b, t) -> a + (b - a) * t;

// Clamp value
var clamp = (v, min, max) -> Math.max(min, Math.min(max, v));
```

## Performance Tips

```haxe
// Batch draw calls with TileGroup
var group = new h2d.TileGroup(tile, parent);

// Use object pooling for bullets/particles
// Pre-allocate arrays with known size
var array = new Array<Entity>();
array.resize(100);

// Cache calculations
var halfWidth = width * 0.5; // Calculate once

// Use squared distance for comparison
if (dx*dx + dy*dy < radius*radius) { } // Faster than Math.sqrt
```

---

For complete API documentation, visit [api.heaps.io](https://api.heaps.io)
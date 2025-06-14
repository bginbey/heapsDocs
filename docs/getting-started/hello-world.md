# Hello World

Let's build your first interactive Heaps application - a simple game where you click to spawn bouncing sprites.

## Basic Application Structure

Every Heaps application extends `hxd.App`:

```haxe
class Main extends hxd.App {
    override function init() {
        // Called once when app starts
    }
    
    override function update(dt:Float) {
        // Called every frame
        // dt = delta time in seconds
    }
    
    static function main() {
        new Main();
    }
}
```

## Display Your First Sprite

```haxe
class Main extends hxd.App {
    var player : h2d.Bitmap;
    
    override function init() {
        // Create a colored square
        var tile = h2d.Tile.fromColor(0xFF0000, 32, 32);
        player = new h2d.Bitmap(tile, s2d);
        
        // Center it on screen
        player.x = s2d.width * 0.5 - 16;
        player.y = s2d.height * 0.5 - 16;
    }
}
```

The `s2d` property is your 2D scene - everything displayed must be added to it.

## Make It Move

Add movement in the update loop:

```haxe
class Main extends hxd.App {
    var player : h2d.Bitmap;
    var velocity = 200.0; // pixels per second
    
    override function init() {
        var tile = h2d.Tile.fromColor(0xFF0000, 32, 32);
        player = new h2d.Bitmap(tile, s2d);
        player.center(); // Centers the tile pivot
        
        player.x = s2d.width * 0.5;
        player.y = s2d.height * 0.5;
    }
    
    override function update(dt:Float) {
        // Move right
        player.x += velocity * dt;
        
        // Wrap around screen
        if (player.x > s2d.width + 16) {
            player.x = -16;
        }
    }
}
```

!!! tip "Delta Time"
    Always multiply movement by `dt` to ensure consistent speed regardless of framerate.

## Add Input

Heaps provides easy access to keyboard and mouse:

```haxe
class Main extends hxd.App {
    var player : h2d.Bitmap;
    var speed = 200.0;
    
    override function init() {
        var tile = h2d.Tile.fromColor(0x00FF00, 32, 32);
        player = new h2d.Bitmap(tile, s2d);
        player.center();
        
        player.x = s2d.width * 0.5;
        player.y = s2d.height * 0.5;
    }
    
    override function update(dt:Float) {
        // Keyboard input
        if (hxd.Key.isDown(hxd.Key.LEFT))  player.x -= speed * dt;
        if (hxd.Key.isDown(hxd.Key.RIGHT)) player.x += speed * dt;
        if (hxd.Key.isDown(hxd.Key.UP))    player.y -= speed * dt;
        if (hxd.Key.isDown(hxd.Key.DOWN))  player.y += speed * dt;
        
        // Mouse position
        player.rotation = Math.atan2(
            s2d.mouseY - player.y,
            s2d.mouseX - player.x
        );
    }
}
```

## Interactive Demo

Here's a complete interactive demo:

```haxe
class Main extends hxd.App {
    var squares : Array<Square> = [];
    
    override function init() {
        // Display instructions
        var text = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        text.text = "Click to spawn squares!";
        text.x = 10;
        text.y = 10;
        
        // Change background
        engine.backgroundColor = 0x1a1a2e;
    }
    
    override function update(dt:Float) {
        // Spawn on click
        if (hxd.Key.isPressed(hxd.Key.MOUSE_LEFT)) {
            spawnSquare(s2d.mouseX, s2d.mouseY);
        }
        
        // Update all squares
        for (square in squares) {
            square.update(dt);
        }
        
        // Remove off-screen squares
        squares = squares.filter(s -> s.y < s2d.height + 50);
    }
    
    function spawnSquare(x:Float, y:Float) {
        var square = new Square(s2d);
        square.x = x;
        square.y = y;
        squares.push(square);
    }
    
    static function main() {
        new Main();
    }
}

class Square extends h2d.Bitmap {
    var velocity : Float;
    var gravity = 500.0;
    var hue : Float;
    
    public function new(parent:h2d.Object) {
        // Random colored square
        hue = Math.random();
        var color = hxd.Math.colorHSV(hue, 0.8, 0.9);
        var tile = h2d.Tile.fromColor(color, 16, 16);
        
        super(tile, parent);
        center();
        
        // Random upward velocity
        velocity = -Math.random() * 300 - 100;
        
        // Random rotation speed
        rotation = Math.random() * Math.PI;
    }
    
    public function update(dt:Float) {
        // Physics
        velocity += gravity * dt;
        y += velocity * dt;
        
        // Spin
        rotation += dt * 2;
        
        // Fade based on hue
        alpha = 1 - (y / 600);
    }
}
```

## Understanding the Code

### Display Objects
- `h2d.Object` - Base class for all 2D display objects
- `h2d.Bitmap` - Displays a single tile/image
- `h2d.Text` - Renders text
- `s2d` - The root 2D scene

### Game Loop
- `init()` - Setup your game state
- `update(dt)` - Update logic each frame
- `dt` - Time since last frame in seconds

### Input
- `hxd.Key.isDown()` - Check if key is held
- `hxd.Key.isPressed()` - Check if key was just pressed
- `s2d.mouseX/mouseY` - Current mouse position

## Build and Run

Save as `src/Main.hx` and build:

```bash
# HashLink
haxe build.hxml && hl bin/game.hl

# Web
haxe build-web.hxml
# Open bin/index.html
```

## Exercises

Try these modifications:

1. **Change Colors**: Make squares cycle through colors as they fall
2. **Add Particles**: Spawn multiple small squares on click
3. **Add Sound**: Play a sound effect on spawn (hint: `hxd.Res.sound.play()`)
4. **Add Text**: Display the number of squares on screen

## Common Patterns

### Object Pooling
```haxe
var pool : Array<Square> = [];

function getSquare() : Square {
    if (pool.length > 0) {
        return pool.pop();
    }
    return new Square(s2d);
}

function recycleSquare(s:Square) {
    s.visible = false;
    pool.push(s);
}
```

### Screen Boundaries
```haxe
// Keep object on screen
obj.x = Math.max(0, Math.min(s2d.width - obj.width, obj.x));
obj.y = Math.max(0, Math.min(s2d.height - obj.height, obj.y));
```

### Simple Timer
```haxe
var timer = 0.0;
var interval = 1.0; // 1 second

override function update(dt:Float) {
    timer += dt;
    if (timer >= interval) {
        timer -= interval;
        // Do something every second
    }
}
```

## Next Steps

Now that you understand the basics, let's look at [Project Structure →](project-structure.md) to organize larger games.
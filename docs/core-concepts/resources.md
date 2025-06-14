# Resource System

Heaps provides a powerful resource system that automatically imports and manages your game assets. Understanding this system is crucial for efficient asset management.

## How It Works

Place assets in the `res/` folder, and Heaps makes them available through `hxd.Res`:

```
res/
├── sprites/
│   └── player.png      → hxd.Res.sprites.player
├── sounds/
│   └── jump.wav        → hxd.Res.sounds.jump  
├── fonts/
│   └── pixel.fnt       → hxd.Res.fonts.pixel
└── data/
    └── levels.json     → hxd.Res.data.levels
```

## Basic Usage

### Initialize Resources

```haxe
class Main extends hxd.App {
    override function init() {
        // Required for embedded resources
        hxd.Res.initEmbed();
        
        // Now access resources
        var playerSprite = hxd.Res.sprites.player.toTile();
    }
}
```

### Build Configuration

Add to your `build.hxml`:
```hxml
-D resourcePath=res
```

## Image Resources

### Loading Images

```haxe
// Get as texture
var texture = hxd.Res.sprites.player.toTexture();

// Get as tile (more common)
var tile = hxd.Res.sprites.player.toTile();

// Create bitmap
var bitmap = new h2d.Bitmap(tile, s2d);

// Get image info
trace(hxd.Res.sprites.player.entry.width);
trace(hxd.Res.sprites.player.entry.height);
```

### Tile Manipulation

```haxe
// Get full tile
var fullTile = hxd.Res.sprites.tileset.toTile();

// Create sub-tiles
var grassTile = fullTile.sub(0, 0, 16, 16);
var stoneTile = fullTile.sub(16, 0, 16, 16);
var waterTile = fullTile.sub(32, 0, 16, 16);

// Animation frames
var frames = [
    fullTile.sub(0, 0, 32, 32),
    fullTile.sub(32, 0, 32, 32),
    fullTile.sub(64, 0, 32, 32),
];
```

### Texture Atlas

```haxe
// Load atlas
var atlas = hxd.Res.atlas.character.toTile();

// Define animations
var anims = new Map<String, Array<h2d.Tile>>();

anims["idle"] = [
    atlas.sub(0, 0, 32, 32),
    atlas.sub(32, 0, 32, 32),
    atlas.sub(64, 0, 32, 32),
    atlas.sub(96, 0, 32, 32),
];

anims["walk"] = [
    atlas.sub(0, 32, 32, 32),
    atlas.sub(32, 32, 32, 32),
    atlas.sub(64, 32, 32, 32),
    atlas.sub(96, 32, 32, 32),
];
```

## Audio Resources

### Sound Effects

```haxe
// Play once
hxd.Res.sounds.jump.play();

// With volume
hxd.Res.sounds.explosion.play(0.5);

// Get sound resource for more control
var sound = hxd.Res.sounds.hit;
var channel = sound.play(true); // loop
channel.volume = 0.7;
channel.pause = true;
```

### Music

```haxe
class MusicManager {
    static var current : hxd.snd.Channel;
    
    public static function play(music:hxd.res.Sound, volume=1.0) {
        if (current != null) {
            current.stop();
        }
        
        current = music.play(true); // loop
        current.volume = volume;
    }
    
    public static function fadeOut(duration:Float) {
        if (current == null) return;
        
        var start = current.volume;
        var elapsed = 0.0;
        
        Main.instance.updates.push((dt) -> {
            elapsed += dt;
            var t = elapsed / duration;
            
            if (t >= 1) {
                current.stop();
                current = null;
                return false;
            }
            
            current.volume = start * (1 - t);
            return true;
        });
    }
}

// Usage
MusicManager.play(hxd.Res.music.theme);
```

## Font Resources

### Bitmap Fonts

```haxe
// Load font
var font = hxd.Res.fonts.pixel.toFont();

// Create text
var text = new h2d.Text(font, s2d);
text.text = "Hello World!";
text.textColor = 0xFFFFFF;
text.scale(2);

// With drop shadow
text.dropShadow = {
    dx: 2,
    dy: 2,
    color: 0x000000,
    alpha: 0.5
};
```

### Font Generation

Create `.fnt` files from TrueType fonts:
```hxml
# In res/fonts/
# Convert .ttf to .fnt using BMFont or Hiero
```

## Data Resources

### JSON Data

```haxe
// res/data/enemies.json
{
    "goblin": {
        "health": 50,
        "speed": 100,
        "damage": 10
    },
    "orc": {
        "health": 100,
        "speed": 80,
        "damage": 20
    }
}

// Load in game
var enemyData = hxd.Res.data.enemies.toText();
var enemies = haxe.Json.parse(enemyData);

// Typed access
typedef EnemyData = {
    health: Int,
    speed: Float,
    damage: Int
}

var data:Map<String, EnemyData> = haxe.Json.parse(enemyData);
var goblin = data.get("goblin");
```

### XML Data

```haxe
// res/data/items.xml
var xml = Xml.parse(hxd.Res.data.items.toText());
for (item in xml.firstElement().elementsNamed("item")) {
    var id = item.get("id");
    var name = item.get("name");
    var price = Std.parseInt(item.get("price"));
}
```

### Custom Binary

```haxe
// Save level data
var bytes = haxe.io.Bytes.alloc(1000);
// ... write data
sys.io.File.saveBytes("res/levels/level1.dat", bytes);

// Load in game
var levelData = hxd.Res.levels.level1.entry.getBytes();
```

## Dynamic Loading

### Load at Runtime

```haxe
class DynamicLoader {
    public static function loadTexture(path:String, onLoaded:h3d.mat.Texture->Void) {
        hxd.res.Loader.currentInstance.load(path).then((res) -> {
            var tex = res.toTexture();
            onLoaded(tex);
        });
    }
    
    public static function loadSound(path:String, onLoaded:hxd.res.Sound->Void) {
        hxd.res.Loader.currentInstance.load(path).then((res) -> {
            var sound = cast(res, hxd.res.Sound);
            onLoaded(sound);
        });
    }
}
```

### Hot Reload

```haxe
#if debug
class HotReload {
    static var watched : Map<String, Float> = [];
    
    public static function watch(path:String, onChange:Void->Void) {
        watched.set(path, getModTime(path));
        
        // Check periodically
        haxe.Timer.delay(() -> {
            checkFile(path, onChange);
        }, 1000);
    }
    
    static function checkFile(path:String, onChange:Void->Void) {
        var modTime = getModTime(path);
        if (modTime > watched.get(path)) {
            watched.set(path, modTime);
            hxd.Res.loader.cleanCache();
            onChange();
        }
        
        haxe.Timer.delay(() -> checkFile(path, onChange), 1000);
    }
}
#end
```

## Resource Management

### Preloading

```haxe
class Preloader {
    var toLoad : Array<String>;
    var loaded = 0;
    public var onProgress : Float->Void;
    public var onComplete : Void->Void;
    
    public function new(resources:Array<String>) {
        toLoad = resources;
    }
    
    public function start() {
        loadNext();
    }
    
    function loadNext() {
        if (loaded >= toLoad.length) {
            if (onComplete != null) onComplete();
            return;
        }
        
        var path = toLoad[loaded];
        hxd.Res.loader.load(path).then((_) -> {
            loaded++;
            if (onProgress != null) {
                onProgress(loaded / toLoad.length);
            }
            loadNext();
        });
    }
}

// Usage
var preloader = new Preloader([
    "sprites/enemies.png",
    "sounds/battle.ogg",
    "data/level1.json"
]);

preloader.onProgress = (p) -> trace('Loading: ${Math.round(p * 100)}%');
preloader.onComplete = () -> startGame();
preloader.start();
```

### Memory Management

```haxe
class ResourceCache {
    static var textures : Map<String, h3d.mat.Texture> = [];
    static var sounds : Map<String, hxd.res.Sound> = [];
    
    public static function getTexture(path:String) : h3d.mat.Texture {
        if (!textures.exists(path)) {
            textures.set(path, hxd.Res.loader.load(path).toTexture());
        }
        return textures.get(path);
    }
    
    public static function clearTextures() {
        for (tex in textures) {
            tex.dispose();
        }
        textures.clear();
    }
    
    public static function removeTexture(path:String) {
        var tex = textures.get(path);
        if (tex != null) {
            tex.dispose();
            textures.remove(path);
        }
    }
}
```

## Asset Pipeline

### Image Optimization

Create `res/.heaps` configuration:
```json
{
    "convert": {
        "format": "png",
        "quality": 90,
        "alpha": true
    },
    "props": {
        "sprites": {
            "filter": false,
            "wrap": "clamp"
        }
    }
}
```

### Automatic Atlas Packing

```haxe
// Use texture packer tool
// Outputs: atlas.png + atlas.xml

// Load in code
var atlas = new hxd.res.Atlas(hxd.Res.sprites.atlas);
var tile = atlas.get("player_idle");
```

## Best Practices

### 1. Resource Organization
```
res/
├── sprites/
│   ├── player/
│   ├── enemies/
│   └── environment/
├── audio/
│   ├── sfx/
│   └── music/
├── fonts/
├── data/
│   ├── levels/
│   └── config/
└── shaders/
```

### 2. Lazy Loading
```haxe
class Assets {
    static var _playerTile : h2d.Tile;
    
    public static var playerTile(get, never) : h2d.Tile;
    static function get_playerTile() {
        if (_playerTile == null) {
            _playerTile = hxd.Res.sprites.player.toTile();
        }
        return _playerTile;
    }
}
```

### 3. Error Handling
```haxe
function loadResource(path:String) : hxd.res.Any {
    try {
        return hxd.Res.loader.load(path);
    } catch (e:Dynamic) {
        trace('Failed to load resource: $path');
        return null;
    }
}
```

## Next Steps

Understand the [Entity System →](entities.md) to create game objects with Heaps.
# Tilemap Systems

Tilemaps are a fundamental technique in 2D game development for creating large game worlds efficiently. This page explains how the tilemap system from [Part 2: Core Systems](../tutorials/02-core-systems.md) works under the hood.

## How Tilemaps Work

A tilemap divides the game world into a grid of uniform cells (tiles). Instead of storing large images for entire levels, the game stores:

1. **A small set of tile images** (tileset)
2. **A grid of numbers** indicating which tile goes where

This approach saves memory and makes level editing straightforward.

## Breaking Down the Implementation

### The Data Structure

From the tutorial's `Tilemap.hx`:

```haxe
class Tilemap extends h2d.Object {
    public static inline var TILE_SIZE = 16;
    
    var widthInTiles : Int;
    var heightInTiles : Int;
    var collisionData : Array<Int>;
    var tileGroup : h2d.TileGroup;
}
```

The key components:
- **TILE_SIZE**: Each tile is 16x16 pixels
- **widthInTiles/heightInTiles**: Level dimensions in tile units
- **collisionData**: 1D array storing tile types (0=empty, 1=solid)
- **tileGroup**: Heaps' efficient rendering container

### Array to Grid Mapping

The tilemap stores level data as a 1D array but represents a 2D grid:

```haxe
public function getTile(x:Int, y:Int) : Int {
    if (x < 0 || x >= widthInTiles || y < 0 || y >= heightInTiles) {
        return 1; // Treat out of bounds as solid
    }
    return collisionData[y * widthInTiles + x];
}
```

The formula `y * widthInTiles + x` converts 2D coordinates to a 1D array index:

```
Grid position (2,1) in a 5-wide level:
Index = 1 * 5 + 2 = 7

Array: [0,0,0,0,0, 0,0,X,0,0, 0,0,0,0,0]
                      ↑
                   Position 7
```

### Efficient Rendering with TileGroup

Instead of creating individual objects for each tile, the system uses `h2d.TileGroup`:

```haxe
function buildVisuals() {
    var whiteTile = h2d.Tile.fromColor(0xFFFFFF, TILE_SIZE, TILE_SIZE);
    tileGroup = new h2d.TileGroup(whiteTile, this);
    
    for (y in 0...heightInTiles) {
        for (x in 0...widthInTiles) {
            if (getTile(x, y) == 1) {
                tileGroup.add(
                    x * TILE_SIZE,  // World position X
                    y * TILE_SIZE,  // World position Y
                    whiteTile       // Tile to draw
                );
            }
        }
    }
}
```

`TileGroup` batches all tiles into a single draw call, dramatically improving performance compared to individual sprites.

## Level Data Format

The test level demonstrates a simple format:

```haxe
public static var testLevel = {
    width: 20,
    height: 15,
    tiles: [
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1,
        // ... more rows
    ]
};
```

Each number represents a tile type:
- `0` = Empty space (walkable)
- `1` = Wall (solid)

This creates a bordered room with internal walls.

## Collision Detection

The tilemap provides collision checking in two ways:

### Grid-Based Check
```haxe
public function isSolid(worldX:Float, worldY:Float) : Bool {
    var tileX = Math.floor(worldX / TILE_SIZE);
    var tileY = Math.floor(worldY / TILE_SIZE);
    return getTile(tileX, tileY) == 1;
}
```

This converts a world position to tile coordinates and checks if that tile is solid.

### Entity Integration
Entities check their corners against the tilemap:

```haxe
function checkTilemapCollision() : Bool {
    var left = x + collisionBox.x;
    var right = left + collisionBox.width;
    var top = y + collisionBox.y;
    var bottom = top + collisionBox.height;
    
    return tilemap.isSolid(left, top) ||
           tilemap.isSolid(right, top) ||
           tilemap.isSolid(left, bottom) ||
           tilemap.isSolid(right, bottom);
}
```

This prevents entities from overlapping solid tiles.

## Performance Considerations

### Memory Efficiency
A 100x100 tile level using 16x16 pixel tiles:
- **Without tilemaps**: 1600x1600 pixels = ~10MB uncompressed
- **With tilemaps**: 10,000 integers + small tileset = ~40KB + tileset

### Rendering Performance
- **Individual sprites**: 10,000 draw calls (one per tile)
- **TileGroup**: 1 draw call for all static tiles

## Common Extensions

### Multiple Tile Types
```haxe
// Extended tile types
enum TileType {
    Empty;
    Wall;
    Water;
    Spikes;
}

// Visual mapping
var tileTextures = [
    0 => grassTile,
    1 => wallTile,
    2 => waterTile,
    3 => spikeTile
];
```

### Animated Tiles
```haxe
class AnimatedTile {
    var frames : Array<h2d.Tile>;
    var currentFrame : Int;
    var animSpeed : Float;
}
```

### Layers
```haxe
class LayeredTilemap {
    var backgroundLayer : TileGroup;
    var collisionLayer : TileGroup;
    var foregroundLayer : TileGroup;
}
```

## Best Practices

1. **Keep tile sizes power-of-2** (16, 32, 64) for GPU efficiency
2. **Use tile atlases** to reduce texture switching
3. **Separate visual and collision data** for flexibility
4. **Cache frequently accessed tiles** in hot paths
5. **Consider chunking** for very large worlds

## Related Topics

- [Entity System](../core-concepts/entities.md) - How entities interact with tilemaps
- [Rendering](../core-concepts/rendering.md) - GPU batching and optimization
- [Resource System](../core-concepts/resources.md) - Loading tilesets efficiently
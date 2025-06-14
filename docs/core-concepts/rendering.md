# Rendering

Heaps provides a powerful GPU-accelerated rendering system for both 2D and 3D graphics. Understanding how rendering works helps you optimize performance and create stunning visual effects.

## Rendering Pipeline

Heaps renders in several stages:

1. **Update** - Game logic and transformations
2. **Sync** - Update render data
3. **Draw** - GPU rendering
4. **Present** - Display to screen

```haxe
// Simplified render loop
class RenderContext {
    function render() {
        // 1. Clear
        clear(backgroundColor);
        
        // 2. Sync objects
        scene.syncPos();
        
        // 3. Draw batches
        drawCalls();
        
        // 4. Present
        swapBuffers();
    }
}
```

## 2D Rendering

### Sprite Batching

Heaps automatically batches sprites for performance:

```haxe
// These sprites will batch together
var sprite1 = new h2d.Bitmap(tile, s2d);
var sprite2 = new h2d.Bitmap(tile, s2d);
var sprite3 = new h2d.Bitmap(tile, s2d);

// This breaks the batch (different texture)
var sprite4 = new h2d.Bitmap(otherTile, s2d);

// Check draw calls
trace(s2d.renderer.drawCalls); // Shows batch count
```

### Optimizing Batches

```haxe
class BatchOptimizer {
    // Good: Single texture atlas
    public static function createFromAtlas() {
        var atlas = hxd.Res.sprites.atlas.toTile();
        
        var objects = [];
        for (i in 0...100) {
            var tile = atlas.sub(i * 32, 0, 32, 32);
            var sprite = new h2d.Bitmap(tile, s2d);
            objects.push(sprite);
        }
        // Result: 1 draw call
    }
    
    // Bad: Multiple textures
    public static function createIndividual() {
        for (i in 0...100) {
            var texture = hxd.Res.loader.load('sprite$i.png').toTile();
            var sprite = new h2d.Bitmap(texture, s2d);
        }
        // Result: 100 draw calls
    }
}
```

### SpriteBatch

For thousands of sprites:

```haxe
class ParticleSystem extends h2d.SpriteBatch {
    var particles : Array<BatchElement> = [];
    
    public function new(texture:h2d.Tile, parent) {
        super(texture, parent);
        
        // Pre-allocate particles
        for (i in 0...1000) {
            var p = new BatchElement(texture);
            p.visible = false;
            particles.push(p);
            add(p);
        }
    }
    
    public function emit(x:Float, y:Float) {
        for (p in particles) {
            if (!p.visible) {
                p.reset(x, y);
                break;
            }
        }
    }
}

class BatchElement extends h2d.SpriteBatch.BatchElement {
    var vx : Float;
    var vy : Float;
    var life : Float;
    
    public function reset(x:Float, y:Float) {
        this.x = x;
        this.y = y;
        this.visible = true;
        this.alpha = 1;
        
        vx = Math.random() * 200 - 100;
        vy = -Math.random() * 300 - 100;
        life = 1.0;
    }
    
    public function update(dt:Float) {
        if (!visible) return;
        
        life -= dt;
        if (life <= 0) {
            visible = false;
            return;
        }
        
        x += vx * dt;
        y += vy * dt;
        vy += 500 * dt; // gravity
        
        alpha = life;
        scale = 1 + (1 - life) * 0.5;
    }
}
```

## Shaders

### HXSL (Heaps Shader Language)

```haxe
// Simple color shader
class ColorShader extends hxsl.Shader {
    static var SRC = {
        @param var color : Vec4;
        
        var pixelColor : Vec4;
        
        function fragment() {
            pixelColor *= color;
        }
    };
}

// Usage
var shader = new ColorShader();
shader.color.set(1, 0, 0, 1); // Red tint
sprite.addShader(shader);
```

### Common Shader Effects

```haxe
// Outline shader
class OutlineShader extends hxsl.Shader {
    static var SRC = {
        @param var outlineColor : Vec4;
        @param var outlineSize : Float;
        
        var textureColor : Vec4;
        var pixelColor : Vec4;
        var uv : Vec2;
        
        function fragment() {
            var alpha = textureColor.a;
            
            // Sample neighbors
            var n = texture.get(uv + vec2(0, -outlineSize)).a;
            var s = texture.get(uv + vec2(0, outlineSize)).a;
            var e = texture.get(uv + vec2(outlineSize, 0)).a;
            var w = texture.get(uv + vec2(-outlineSize, 0)).a;
            
            var outline = max(max(n, s), max(e, w));
            
            if (alpha < 0.5 && outline > 0.5) {
                pixelColor = outlineColor;
            }
        }
    };
}

// Wave distortion
class WaveShader extends hxsl.Shader {
    static var SRC = {
        @param var time : Float;
        @param var frequency : Float;
        @param var amplitude : Float;
        
        var relativePosition : Vec2;
        var transformedPosition : Vec4;
        
        function vertex() {
            transformedPosition.x += sin(relativePosition.y * frequency + time) * amplitude;
        }
    };
}
```

### Shader Parameters

```haxe
class ShaderController {
    var shader : WaveShader;
    var time = 0.0;
    
    public function new(target:h2d.Object) {
        shader = new WaveShader();
        shader.frequency = 0.1;
        shader.amplitude = 10;
        target.addShader(shader);
    }
    
    public function update(dt:Float) {
        time += dt;
        shader.time = time;
    }
}
```

## Render Targets

### Off-screen Rendering

```haxe
class RenderToTexture {
    var texture : h3d.mat.Texture;
    var scene : h2d.Scene;
    
    public function new(width:Int, height:Int) {
        // Create render target
        texture = new h3d.mat.Texture(width, height, [Target]);
        
        // Create separate scene
        scene = new h2d.Scene();
        scene.setFixedSize(width, height);
    }
    
    public function render(content:h2d.Object) {
        // Add content to scene
        scene.addChild(content);
        
        // Render to texture
        engine.pushTarget(texture);
        engine.clear(0x000000, 1);
        scene.render(engine);
        engine.popTarget();
        
        // Remove content
        content.remove();
    }
    
    public function getSprite() : h2d.Bitmap {
        return new h2d.Bitmap(h2d.Tile.fromTexture(texture));
    }
}
```

### Post-Processing

```haxe
class PostProcess {
    var screenTexture : h3d.mat.Texture;
    var postScene : h2d.Scene;
    
    public function apply(s2d:h2d.Scene) {
        // Capture screen
        if (screenTexture == null) {
            screenTexture = new h3d.mat.Texture(
                s2d.width, 
                s2d.height, 
                [Target]
            );
        }
        
        // Render scene to texture
        engine.pushTarget(screenTexture);
        s2d.render(engine);
        engine.popTarget();
        
        // Apply effects
        var screen = new h2d.Bitmap(
            h2d.Tile.fromTexture(screenTexture),
            postScene
        );
        
        // Add shaders
        screen.addShader(new BloomShader());
        screen.addShader(new ChromaticAberrationShader());
        
        // Render with effects
        postScene.render(engine);
    }
}
```

## Performance Optimization

### Draw Call Reduction

```haxe
class DrawCallOptimizer {
    // Use TileGroup for static geometry
    public static function createTilemap(tiles:Array<{x:Int, y:Int, tile:h2d.Tile}>) {
        var group = new h2d.TileGroup(tiles[0].tile, s2d);
        
        for (t in tiles) {
            group.add(t.x, t.y, t.tile);
        }
        
        // Result: 1 draw call for entire tilemap
        return group;
    }
    
    // Sort by texture
    public static function sortByTexture(objects:Array<h2d.Object>) {
        objects.sort((a, b) -> {
            var texA = getTexture(a);
            var texB = getTexture(b);
            return texA.id - texB.id;
        });
    }
}
```

### Culling

```haxe
class ViewCulling {
    var camera : h2d.Camera;
    var objects : Array<h2d.Object>;
    
    public function update() {
        var bounds = camera.getViewBounds();
        
        for (obj in objects) {
            // Simple bounds check
            var inView = obj.x + obj.width > bounds.xMin &&
                        obj.x < bounds.xMax &&
                        obj.y + obj.height > bounds.yMin &&
                        obj.y < bounds.yMax;
            
            obj.visible = inView;
        }
    }
}
```

### LOD (Level of Detail)

```haxe
class LODSprite extends h2d.Object {
    var highDetail : h2d.Bitmap;
    var lowDetail : h2d.Bitmap;
    var threshold = 100.0;
    
    public function new(high:h2d.Tile, low:h2d.Tile, parent) {
        super(parent);
        
        highDetail = new h2d.Bitmap(high, this);
        lowDetail = new h2d.Bitmap(low, this);
        lowDetail.visible = false;
    }
    
    public function updateLOD(cameraX:Float, cameraY:Float) {
        var dist = Math.sqrt(
            Math.pow(x - cameraX, 2) + 
            Math.pow(y - cameraY, 2)
        );
        
        highDetail.visible = dist < threshold;
        lowDetail.visible = dist >= threshold;
    }
}
```

## Blend Modes

```haxe
// Additive - Great for lights/glows
particle.blendMode = Add;

// Multiply - Shadows/darkening
shadow.blendMode = Multiply;

// Screen - Brightening without overexposure
flash.blendMode = Screen;

// Custom blend
class CustomBlend {
    public static function apply(obj:h2d.Object) {
        var blend = new h2d.BlendMode();
        blend.src = One;
        blend.dst = OneMinusSrcAlpha;
        blend.alphaSrc = One;
        blend.alphaDst = OneMinusSrcAlpha;
        obj.blendMode = blend;
    }
}
```

## Debugging Rendering

### Visual Debug

```haxe
class RenderDebug extends h2d.Object {
    var info : h2d.Text;
    
    public function new(parent) {
        super(parent);
        
        info = new h2d.Text(hxd.res.DefaultFont.get(), this);
    }
    
    override function sync(ctx:h2d.RenderContext) {
        info.text = 'Draw Calls: ${ctx.drawCalls}
Triangles: ${ctx.triangles}
Textures: ${ctx.textures}';
        
        super.sync(ctx);
    }
}
```

### Overdraw Visualization

```haxe
class OverdrawDebug {
    public static function enable(scene:h2d.Scene) {
        // Make everything semi-transparent
        function makeTransparent(obj:h2d.Object) {
            obj.alpha = 0.3;
            for (child in obj.children) {
                makeTransparent(child);
            }
        }
        
        makeTransparent(scene);
    }
}
```

## Best Practices

### 1. Batch Everything
```haxe
// Good: Single texture atlas
var atlas = hxd.Res.sprites.characters.toTile();
for (i in 0...enemies.length) {
    enemies[i].setTile(atlas.sub(i * 32, 0, 32, 32));
}

// Bad: Individual textures
for (i in 0...enemies.length) {
    enemies[i].loadTexture('enemy_$i.png');
}
```

### 2. Minimize State Changes
```haxe
// Good: Group by render state
renderOpaqueObjects();
renderAdditiveObjects();
renderUIElements();

// Bad: Random order
for (obj in allObjects) {
    obj.render(); // Constant state switching
}
```

### 3. Use Appropriate Techniques
```haxe
// Few sprites: h2d.Bitmap
if (count < 100) {
    return new h2d.Bitmap(tile, parent);
}

// Many sprites: h2d.SpriteBatch
else if (count < 10000) {
    return new ParticleSystem(tile, parent);
}

// Massive amounts: GPU particles
else {
    return new GPUParticles(parent);
}
```

## Next Steps

Start building your game with the [Tutorial Series →](../tutorials/00-overview.md)!
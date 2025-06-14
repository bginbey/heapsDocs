# Entity System

Heaps uses a display list hierarchy based on `h2d.Object`. Understanding this system is key to organizing and rendering your game objects efficiently.

## Object Hierarchy

Every visual element extends `h2d.Object`:

```haxe
// Base display object
var obj = new h2d.Object(parent);

// Common display objects
var bitmap = new h2d.Bitmap(tile, parent);
var text = new h2d.Text(font, parent);
var graphics = new h2d.Graphics(parent);
var interactive = new h2d.Interactive(width, height, parent);
```

### Parent-Child Relationships

```haxe
// Create hierarchy
var world = new h2d.Object(s2d);
var player = new h2d.Object(world);
var weapon = new h2d.Object(player);

// Transform inheritance
player.x = 100;
player.y = 100;
weapon.x = 20; // Relative to player

// weapon's world position = (120, 100)
```

## Creating Entities

### Basic Entity Class

```haxe
class Entity extends h2d.Object {
    public var velocity : h2d.col.Point;
    public var bounds : h2d.col.Bounds;
    
    public function new(?parent:h2d.Object) {
        super(parent);
        velocity = new h2d.col.Point();
        bounds = new h2d.col.Bounds();
    }
    
    public function update(dt:Float) {
        // Physics
        x += velocity.x * dt;
        y += velocity.y * dt;
        
        // Update bounds
        bounds.x = x - bounds.width * 0.5;
        bounds.y = y - bounds.height * 0.5;
    }
}
```

### Composite Entity

```haxe
class Player extends Entity {
    var sprite : h2d.Anim;
    var shadow : h2d.Bitmap;
    var healthBar : h2d.Graphics;
    
    public function new(?parent) {
        super(parent);
        
        // Shadow (rendered first)
        var shadowTile = h2d.Tile.fromColor(0x000000, 32, 16, 0.3);
        shadow = new h2d.Bitmap(shadowTile, this);
        shadow.center();
        shadow.y = 20;
        
        // Animated sprite
        var tiles = hxd.Res.sprites.player_walk.toTile().split(8);
        sprite = new h2d.Anim(tiles, 10, this);
        sprite.center();
        
        // Health bar (always on top)
        healthBar = new h2d.Graphics(this);
        updateHealthBar(100, 100);
        
        // Set bounds
        bounds.set(-16, -24, 32, 48);
    }
    
    function updateHealthBar(current:Int, max:Int) {
        healthBar.clear();
        
        // Background
        healthBar.beginFill(0x333333);
        healthBar.drawRect(-16, -30, 32, 4);
        
        // Health
        var pct = current / max;
        healthBar.beginFill(0x00ff00);
        healthBar.drawRect(-16, -30, 32 * pct, 4);
        
        healthBar.endFill();
    }
}
```

## Display Properties

### Transform Properties

```haxe
var entity = new Entity();

// Position
entity.x = 100;
entity.y = 200;

// Scale
entity.scaleX = 2;
entity.scaleY = 2;
entity.scale(1.5); // Both axes

// Rotation (radians)
entity.rotation = Math.PI / 4;

// Visibility
entity.visible = false;
entity.alpha = 0.5;
```

### Blend Modes

```haxe
// Additive blending for lights/effects
entity.blendMode = Add;

// Multiply for shadows
entity.blendMode = Multiply;

// Default
entity.blendMode = Alpha;

// Other modes: None, Erase, Screen, Overlay
```

### Filters

```haxe
// Color matrix filter
var filter = new h2d.filter.ColorMatrix();
entity.filter = filter;

// Grayscale
filter.matrix = h2d.filter.ColorMatrix.grayed();

// Blur
entity.filter = new h2d.filter.Blur(2, 2);

// Glow
entity.filter = new h2d.filter.Glow(0xFF0000, 1, 10);

// Multiple filters
entity.filter = new h2d.filter.Group([
    new h2d.filter.Blur(1, 1),
    new h2d.filter.Glow(0x00FF00, 0.5, 5)
]);
```

## Component Pattern

### Component Interface

```haxe
interface IComponent {
    function update(dt:Float):Void;
    function onAdd(entity:Entity):Void;
    function onRemove():Void;
}

class Entity extends h2d.Object {
    var components : Array<IComponent> = [];
    
    public function addComponent(comp:IComponent) {
        components.push(comp);
        comp.onAdd(this);
    }
    
    public function removeComponent(comp:IComponent) {
        components.remove(comp);
        comp.onRemove();
    }
    
    public function getComponent<T:IComponent>(type:Class<T>) : T {
        for (comp in components) {
            if (Std.isOfType(comp, type)) {
                return cast comp;
            }
        }
        return null;
    }
    
    override function update(dt:Float) {
        for (comp in components) {
            comp.update(dt);
        }
    }
}
```

### Example Components

```haxe
// Health component
class Health implements IComponent {
    public var current : Int;
    public var max : Int;
    var entity : Entity;
    
    public function new(max:Int) {
        this.max = max;
        this.current = max;
    }
    
    public function onAdd(entity:Entity) {
        this.entity = entity;
    }
    
    public function takeDamage(amount:Int) {
        current -= amount;
        if (current <= 0) {
            entity.destroy();
        }
    }
    
    public function update(dt:Float) {}
    public function onRemove() {}
}

// Movement component
class Movement implements IComponent {
    public var speed = 200.0;
    public var velocity : h2d.col.Point;
    var entity : Entity;
    
    public function new() {
        velocity = new h2d.col.Point();
    }
    
    public function onAdd(entity:Entity) {
        this.entity = entity;
    }
    
    public function update(dt:Float) {
        entity.x += velocity.x * dt;
        entity.y += velocity.y * dt;
        
        // Friction
        velocity.x *= 0.9;
        velocity.y *= 0.9;
    }
    
    public function onRemove() {}
}
```

## Collision Detection

### Simple Bounds

```haxe
class CollidableEntity extends Entity {
    public var bounds : h2d.col.Bounds;
    
    public function new() {
        super();
        bounds = new h2d.col.Bounds();
    }
    
    public function checkCollision(other:CollidableEntity) : Bool {
        return bounds.intersects(other.bounds);
    }
    
    public function updateBounds() {
        bounds.x = x - bounds.width * 0.5;
        bounds.y = y - bounds.height * 0.5;
    }
}
```

### Collision Groups

```haxe
class CollisionWorld {
    var groups : Map<String, Array<CollidableEntity>> = [];
    
    public function addToGroup(entity:CollidableEntity, group:String) {
        if (!groups.exists(group)) {
            groups.set(group, []);
        }
        groups.get(group).push(entity);
    }
    
    public function checkCollisions(group1:String, group2:String, 
                                   callback:CollidableEntity->CollidableEntity->Void) {
        var g1 = groups.get(group1);
        var g2 = groups.get(group2);
        
        if (g1 == null || g2 == null) return;
        
        for (e1 in g1) {
            for (e2 in g2) {
                if (e1.checkCollision(e2)) {
                    callback(e1, e2);
                }
            }
        }
    }
}

// Usage
var collisions = new CollisionWorld();
collisions.addToGroup(player, "player");
collisions.addToGroup(enemy, "enemies");

collisions.checkCollisions("player", "enemies", (p, e) -> {
    p.takeDamage(10);
    e.knockback(p.x, p.y);
});
```

## Object Pooling

### Generic Pool

```haxe
class ObjectPool<T:h2d.Object> {
    var available : Array<T> = [];
    var active : Array<T> = [];
    var create : Void->T;
    var parent : h2d.Object;
    
    public function new(create:Void->T, parent:h2d.Object, initialSize=10) {
        this.create = create;
        this.parent = parent;
        
        // Pre-fill pool
        for (i in 0...initialSize) {
            var obj = create();
            obj.visible = false;
            available.push(obj);
        }
    }
    
    public function get() : T {
        var obj = available.pop();
        if (obj == null) {
            obj = create();
        }
        
        parent.addChild(obj);
        obj.visible = true;
        active.push(obj);
        return obj;
    }
    
    public function put(obj:T) {
        active.remove(obj);
        obj.visible = false;
        obj.remove();
        available.push(obj);
    }
    
    public function clear() {
        for (obj in active.copy()) {
            put(obj);
        }
    }
}

// Usage
var bulletPool = new ObjectPool(
    () -> new Bullet(),
    gameLayer,
    50
);

// Spawn bullet
var bullet = bulletPool.get();
bullet.reset(x, y, angle);

// Return to pool
bulletPool.put(bullet);
```

## Layer Management

### Using h2d.Layers

```haxe
class GameScene extends h2d.Layers {
    public static inline var LAYER_BG = 0;
    public static inline var LAYER_WORLD = 1;
    public static inline var LAYER_ENTITIES = 2;
    public static inline var LAYER_EFFECTS = 3;
    public static inline var LAYER_UI = 4;
    
    public function new() {
        super();
        
        // Ensure layers exist
        for (i in 0...5) {
            add(new h2d.Object(), i);
        }
    }
    
    public function addBackground(obj:h2d.Object) {
        add(obj, LAYER_BG);
    }
    
    public function addEntity(entity:Entity) {
        add(entity, LAYER_ENTITIES);
    }
    
    public function addEffect(effect:h2d.Object) {
        add(effect, LAYER_EFFECTS);
    }
}
```

## Animation

### Using h2d.Anim

```haxe
class AnimatedEntity extends Entity {
    var anim : h2d.Anim;
    var animations : Map<String, Array<h2d.Tile>>;
    
    public function new() {
        super();
        
        animations = new Map();
        loadAnimations();
        
        anim = new h2d.Anim(animations.get("idle"), 10, this);
        anim.center();
    }
    
    function loadAnimations() {
        var sheet = hxd.Res.sprites.character.toTile();
        
        animations.set("idle", sheet.gridFlatten(32, 0, 0, 4));
        animations.set("walk", sheet.gridFlatten(32, 0, 1, 8));
        animations.set("attack", sheet.gridFlatten(32, 0, 2, 6));
    }
    
    public function playAnimation(name:String, loop=true, onEnd:Void->Void=null) {
        var frames = animations.get(name);
        if (frames == null) return;
        
        anim.play(frames);
        anim.loop = loop;
        anim.onAnimEnd = onEnd;
    }
}
```

## Best Practices

### 1. Entity Lifecycle
```haxe
class Entity extends h2d.Object {
    public function new() {
        super();
        onCreate();
    }
    
    function onCreate() {
        // Initialize components
    }
    
    public function reset() {
        // Reset for pooling
    }
    
    public function destroy() {
        onDestroy();
        remove();
    }
    
    function onDestroy() {
        // Cleanup
    }
}
```

### 2. Update Order
```haxe
class GameScene {
    function update(dt:Float) {
        // 1. Input
        player.handleInput();
        
        // 2. AI
        for (enemy in enemies) {
            enemy.updateAI(dt);
        }
        
        // 3. Physics
        for (entity in entities) {
            entity.updatePhysics(dt);
        }
        
        // 4. Collisions
        checkCollisions();
        
        // 5. Animation
        for (entity in entities) {
            entity.updateAnimation(dt);
        }
    }
}
```

### 3. Memory Efficiency
```haxe
class Entity extends h2d.Object {
    // Share resources
    static var sharedTexture : h3d.mat.Texture;
    
    // Clean up references
    override function onRemove() {
        super.onRemove();
        
        // Clear references
        target = null;
        parent = null;
        
        // Remove listeners
        removeEventListeners();
    }
}
```

## Next Steps

Learn about [Rendering →](rendering.md) to understand how Heaps draws your entities.
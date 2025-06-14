# Scene Management

Scenes organize your game into logical states like menus, gameplay, and cutscenes. Heaps doesn't enforce a specific scene system, giving you flexibility to design one that fits your game.

## Basic Scene System

### Scene Base Class

```haxe
class Scene extends h2d.Object {
    public var name : String;
    
    public function new(name:String) {
        super();
        this.name = name;
    }
    
    public function onEnter() {
        // Called when scene becomes active
    }
    
    public function onExit() {
        // Called when leaving scene
    }
    
    public function update(dt:Float) {
        // Override in subclasses
    }
    
    public function dispose() {
        onExit();
        remove();
    }
}
```

### Scene Manager

```haxe
class SceneManager {
    static var current : Scene;
    static var s2d : h2d.Scene;
    
    public static function init(s2d:h2d.Scene) {
        SceneManager.s2d = s2d;
    }
    
    public static function switchTo(scene:Scene) {
        if (current != null) {
            current.dispose();
        }
        
        current = scene;
        s2d.addChild(scene);
        scene.onEnter();
    }
    
    public static function update(dt:Float) {
        if (current != null) {
            current.update(dt);
        }
    }
}
```

## Implementing Scenes

### Menu Scene

```haxe
class MenuScene extends Scene {
    var playButton : h2d.Interactive;
    
    public function new() {
        super("Menu");
    }
    
    override function onEnter() {
        // Background
        var bg = new h2d.Bitmap(hxd.Res.menu.background.toTile(), this);
        
        // Title
        var title = new h2d.Text(hxd.Res.fonts.large.toFont(), this);
        title.text = "AWESOME GAME";
        title.textAlign = Center;
        title.x = s2d.width * 0.5;
        title.y = 100;
        
        // Play button
        createPlayButton();
    }
    
    function createPlayButton() {
        var btn = new h2d.Interactive(200, 50, this);
        btn.x = s2d.width * 0.5 - 100;
        btn.y = 300;
        
        var bg = new h2d.Bitmap(h2d.Tile.fromColor(0x333333, 200, 50), btn);
        
        var text = new h2d.Text(hxd.Res.fonts.default.toFont(), btn);
        text.text = "PLAY";
        text.center();
        
        btn.onClick = (e) -> {
            SceneManager.switchTo(new GameScene());
        };
        
        btn.onOver = (e) -> {
            bg.color.set(0.5, 0.5, 0.5);
        };
        
        btn.onOut = (e) -> {
            bg.color.set(1, 1, 1);
        };
    }
}
```

### Game Scene

```haxe
class GameScene extends Scene {
    var player : Player;
    var enemies : Array<Enemy> = [];
    var paused = false;
    
    public function new() {
        super("Game");
    }
    
    override function onEnter() {
        // Create world
        createLevel();
        
        // Spawn player
        player = new Player(this);
        player.x = 400;
        player.y = 300;
        
        // UI layer
        createHUD();
    }
    
    override function update(dt:Float) {
        // Handle pause
        if (hxd.Key.isPressed(hxd.Key.ESCAPE)) {
            paused = !paused;
        }
        
        if (paused) return;
        
        // Update game
        player.update(dt);
        
        for (enemy in enemies) {
            enemy.update(dt);
            
            // Check collisions
            if (player.bounds.intersects(enemy.bounds)) {
                player.takeDamage(10);
            }
        }
    }
    
    function createLevel() {
        // Load tilemap, spawn enemies, etc.
    }
}
```

## Scene Transitions

### Fade Transition

```haxe
class FadeTransition {
    static var overlay : h2d.Bitmap;
    
    public static function fadeOut(duration:Float, onComplete:Void->Void) {
        if (overlay == null) {
            overlay = new h2d.Bitmap(
                h2d.Tile.fromColor(0x000000, s2d.width, s2d.height),
                s2d
            );
        }
        
        overlay.alpha = 0;
        
        var tween = new Tween(duration);
        tween.onUpdate = (t) -> {
            overlay.alpha = t;
        };
        tween.onComplete = onComplete;
    }
    
    public static function fadeIn(duration:Float, ?onComplete:Void->Void) {
        if (overlay == null) return;
        
        var tween = new Tween(duration);
        tween.onUpdate = (t) -> {
            overlay.alpha = 1 - t;
        };
        tween.onComplete = () -> {
            overlay.remove();
            overlay = null;
            if (onComplete != null) onComplete();
        };
    }
}

// Usage
FadeTransition.fadeOut(0.5, () -> {
    SceneManager.switchTo(new GameScene());
    FadeTransition.fadeIn(0.5);
});
```

### Advanced Transitions

```haxe
class TransitionManager {
    static var transitioning = false;
    
    public static function crossFade(to:Scene, duration=1.0) {
        if (transitioning) return;
        transitioning = true;
        
        // Add new scene under current
        var current = SceneManager.current;
        s2d.addChildAt(to, s2d.getChildIndex(current));
        to.alpha = 0;
        to.onEnter();
        
        // Fade out old, fade in new
        var t = 0.0;
        Main.instance.updates.push((dt) -> {
            t += dt / duration;
            if (t >= 1) {
                current.dispose();
                to.alpha = 1;
                SceneManager.current = to;
                transitioning = false;
                return false; // Remove update
            }
            
            current.alpha = 1 - t;
            to.alpha = t;
            return true; // Continue
        });
    }
    
    public static function slide(to:Scene, direction="left", duration=0.5) {
        if (transitioning) return;
        transitioning = true;
        
        var current = SceneManager.current;
        s2d.addChild(to);
        
        // Position based on direction
        switch(direction) {
            case "left":
                to.x = s2d.width;
            case "right":
                to.x = -s2d.width;
            case "up":
                to.y = s2d.height;
            case "down":
                to.y = -s2d.height;
        }
        
        to.onEnter();
        
        // Animate
        animateSlide(current, to, direction, duration);
    }
}
```

## Scene Stack

For games with overlays (pause menu, dialog):

```haxe
class SceneStack {
    static var stack : Array<Scene> = [];
    static var container : h2d.Layers;
    
    public static function push(scene:Scene) {
        if (stack.length > 0) {
            var current = stack[stack.length - 1];
            current.pause();
        }
        
        stack.push(scene);
        container.add(scene, stack.length);
        scene.onEnter();
    }
    
    public static function pop() : Scene {
        if (stack.length == 0) return null;
        
        var scene = stack.pop();
        scene.dispose();
        
        if (stack.length > 0) {
            var current = stack[stack.length - 1];
            current.resume();
        }
        
        return scene;
    }
    
    public static function update(dt:Float) {
        // Update only top scene
        if (stack.length > 0) {
            stack[stack.length - 1].update(dt);
        }
    }
}
```

## Modal Dialogs

```haxe
class DialogScene extends Scene {
    var blocker : h2d.Interactive;
    
    override function onEnter() {
        // Dark overlay
        blocker = new h2d.Interactive(s2d.width, s2d.height, this);
        var bg = new h2d.Bitmap(
            h2d.Tile.fromColor(0x000000, 1, 1),
            blocker
        );
        bg.scaleX = s2d.width;
        bg.scaleY = s2d.height;
        bg.alpha = 0.7;
        
        // Dialog box
        var dialog = new h2d.Object(this);
        dialog.x = s2d.width * 0.5 - 200;
        dialog.y = s2d.height * 0.5 - 100;
        
        var box = new h2d.Bitmap(
            h2d.Tile.fromColor(0x444444, 400, 200),
            dialog
        );
        
        // Content
        addContent(dialog);
    }
    
    function addContent(parent:h2d.Object) {
        var text = new h2d.Text(hxd.Res.fonts.default.toFont(), parent);
        text.text = "Are you sure?";
        text.x = 200;
        text.y = 50;
        text.textAlign = Center;
        
        // Buttons
        createButton(parent, "Yes", 100, 120, onYes);
        createButton(parent, "No", 220, 120, onNo);
    }
}
```

## Scene Loading

### Async Scene Loading

```haxe
class LoadingScene extends Scene {
    var progress : h2d.Text;
    var bar : h2d.Bitmap;
    var nextScene : Class<Scene>;
    
    public function new(nextScene:Class<Scene>) {
        super("Loading");
        this.nextScene = nextScene;
    }
    
    override function onEnter() {
        progress = new h2d.Text(hxd.Res.fonts.default.toFont(), this);
        progress.text = "Loading... 0%";
        progress.center();
        
        // Progress bar
        var barBg = new h2d.Bitmap(
            h2d.Tile.fromColor(0x333333, 400, 20),
            this
        );
        barBg.x = s2d.width * 0.5 - 200;
        barBg.y = s2d.height * 0.5 + 20;
        
        bar = new h2d.Bitmap(
            h2d.Tile.fromColor(0x00ff00, 1, 20),
            this
        );
        bar.x = barBg.x;
        bar.y = barBg.y;
        
        // Start loading
        loadAssets();
    }
    
    function loadAssets() {
        var loader = new AssetLoader();
        
        loader.onProgress = (current, total) -> {
            var pct = current / total;
            progress.text = 'Loading... ${Math.round(pct * 100)}%';
            bar.scaleX = 400 * pct;
        };
        
        loader.onComplete = () -> {
            SceneManager.switchTo(Type.createInstance(nextScene, []));
        };
        
        loader.start();
    }
}
```

## Best Practices

### 1. Scene Lifecycle
```haxe
class Scene {
    // Initialization
    public function onEnter() { }
    
    // Active updates
    public function update(dt:Float) { }
    
    // Paused but visible
    public function pause() { }
    public function resume() { }
    
    // Cleanup
    public function onExit() { }
    public function dispose() { }
}
```

### 2. Memory Management
```haxe
class GameScene extends Scene {
    var resources : Array<h3d.mat.Texture> = [];
    
    override function onEnter() {
        // Load resources
        resources.push(loadTexture("level1.png"));
    }
    
    override function dispose() {
        // Clean up
        for (tex in resources) {
            tex.dispose();
        }
        resources = [];
        
        super.dispose();
    }
}
```

### 3. Scene Communication
```haxe
// Event system
class SceneEvent {
    public static var onPlayerDeath = new Event<Void>();
    public static var onLevelComplete = new Event<Int>();
}

// In GameScene
SceneEvent.onPlayerDeath.add(() -> {
    SceneManager.switchTo(new GameOverScene());
});

// In Player
if (health <= 0) {
    SceneEvent.onPlayerDeath.trigger();
}
```

## Next Steps

Learn about the [Resource System →](resources.md) to efficiently manage game assets.
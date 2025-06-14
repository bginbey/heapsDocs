# Part 1: Foundation

Let's build the game's foundation! We'll start with an empty folder and end with a working game that has a splash screen, menu, and basic gameplay scene.

## What We're Building

- Set up the project structure
- Write `Main.hx` that serves as the entry point and the game loop
- Build a scene manager and scene class
- Polish with smooth transitions between scenes

## Step 1: Create the Project

First, let's set up the project structure. Create these folders:

```bash
mkdir my-action-rpg
cd my-action-rpg
mkdir src
mkdir res
```

The project now looks like:
```
my-action-rpg/
├── src/     # The game code goes here
└── res/     # Images and sounds go here
```

## Step 2: Configure the Build

Create a file called `build.hxml` in the project root:

```hxml
# Tells Haxe where to find the code
-cp src

# Include the Heaps library
-lib heaps
-lib hlsdl

# Output to HashLink bytecode
-hl bin/game.hl

# The entry point of the game
-main Main

# Where to find game assets
-D resourcePath=res

# Window settings
-D windowTitle=My Action RPG
-D windowSize=800x450
```

This file tells Haxe how to build the game. Think of it as a recipe.

## Step 3: Create the Entry Point

Create `src/Main.hx`:

```haxe
import hxd.App;

class Main extends App {
    static function main() {
        // This starts everything
        new Main();
    }
    
    override function init() {
        // This runs once when the game starts
        trace("Game started!");
    }
    
    override function update(dt:Float) {
        // This runs 60 times per second
        // dt = delta time (time since last frame)
    }
}
```

Test it:
```bash
haxe build.hxml
hl bin/game.hl
```

You should see a black window and "Game started!" in the console.

## Step 4: Add Game Configuration

Before we go further, let's organize our constants. Create `src/GameConfig.hx`:

```haxe
class GameConfig {
    // Window dimensions
    public static inline var GAME_WIDTH = 320;
    public static inline var GAME_HEIGHT = 180;
    
    // We want pixel-perfect graphics
    public static inline var PIXEL_SCALE = 1;
    
    // Game runs at 60 FPS internally
    public static inline var FIXED_FPS = 60;
    public static inline var FIXED_TIMESTEP = 1.0 / FIXED_FPS;
    
    // Scene names - using constants prevents typos
    public static inline var SCENE_SPLASH = "splash";
    public static inline var SCENE_MENU = "menu";
    public static inline var SCENE_GAME = "game";
}
```

## Step 5: Implement Fixed Timestep

Games need consistent timing. Let's update `Main.hx` to run at exactly 60 FPS:

```haxe
import hxd.App;

class Main extends App {
    // Track time for fixed timestep
    var accumulator = 0.0;
    var currentTime = 0.0;
    
    static function main() {
        new Main();
    }
    
    override function init() {
        // Set background color (dark blue)
        engine.backgroundColor = 0x1a1a2e;
        
        // Initialize timer
        currentTime = hxd.Timer.lastTimeStamp;
        
        trace("Game initialized at " + GameConfig.FIXED_FPS + " FPS");
    }
    
    override function update(dt:Float) {
        // Calculate how much time has passed
        var newTime = hxd.Timer.lastTimeStamp;
        var frameTime = newTime - currentTime;
        currentTime = newTime;
        
        // Add to our time accumulator
        accumulator += frameTime;
        
        // Run fixed updates until we've caught up
        while (accumulator >= GameConfig.FIXED_TIMESTEP) {
            fixedUpdate(GameConfig.FIXED_TIMESTEP);
            accumulator -= GameConfig.FIXED_TIMESTEP;
        }
        
        // Render with interpolation
        render(dt, accumulator / GameConfig.FIXED_TIMESTEP);
    }
    
    function fixedUpdate(dt:Float) {
        // Game logic goes here - always runs at 60 FPS
    }
    
    function render(dt:Float, alpha:Float) {
        // Visual updates go here - can run faster than 60 FPS
    }
}
```

Why fixed timestep? It ensures the game runs the same on all computers, whether they're running at 30, 60, or 144 FPS.

## Step 6: Create the Scene System

Games organize content into scenes (menu, gameplay, etc). Create `src/Scene.hx`:

```haxe
// Base class for all scenes
class Scene extends h2d.Object {
    public var name : String;
    
    public function new(name:String) {
        super();
        this.name = name;
    }
    
    // Called when scene becomes active
    public function onEnter() {
        trace('Entered scene: $name');
    }
    
    // Called when leaving scene
    public function onExit() {
        trace('Exited scene: $name');
    }
    
    // Update game logic
    public function update(dt:Float) {
        // Override in subclasses
    }
    
    // Clean up resources
    public function dispose() {
        onExit();
        remove(); // Remove from display
    }
}
```

## Step 7: Build the Scene Manager

The scene manager handles switching between scenes. Create `src/SceneManager.hx`:

```haxe
class SceneManager {
    var scenes : Map<String, Scene> = new Map();
    var currentScene : Scene;
    var app : Main;
    
    public function new(app:Main) {
        this.app = app;
    }
    
    // Register a scene
    public function addScene(scene:Scene) {
        scenes.set(scene.name, scene);
    }
    
    // Switch to a different scene
    public function switchTo(name:String) {
        // Make sure scene exists
        if (!scenes.exists(name)) {
            trace('Warning: Scene "$name" not found!');
            return;
        }
        
        // Exit current scene
        if (currentScene != null) {
            currentScene.dispose();
        }
        
        // Enter new scene
        currentScene = scenes.get(name);
        app.s2d.addChild(currentScene); // Add to display
        currentScene.onEnter();
    }
    
    // Update current scene
    public function update(dt:Float) {
        if (currentScene != null) {
            currentScene.update(dt);
        }
    }
}
```

## Step 8: Create the Splash Scene

Let's make our first scene! Create `src/SplashScene.hx`:

```haxe
class SplashScene extends Scene {
    var logo : h2d.Text;
    var timer = 0.0;
    var duration = 2.0; // Show for 2 seconds
    
    public function new() {
        super(GameConfig.SCENE_SPLASH);
    }
    
    override function onEnter() {
        super.onEnter();
        
        // Create logo text
        logo = new h2d.Text(hxd.res.DefaultFont.get(), this);
        logo.text = "MY GAME STUDIO";
        logo.scale(2); // Make it bigger
        logo.textAlign = Center;
        
        // Center on screen
        logo.x = GameConfig.GAME_WIDTH * 0.5;
        logo.y = GameConfig.GAME_HEIGHT * 0.5;
    }
    
    override function update(dt:Float) {
        timer += dt;
        
        // Fade in for first 0.5 seconds
        if (timer < 0.5) {
            alpha = timer / 0.5;
        }
        // Stay visible
        else if (timer < duration - 0.5) {
            alpha = 1.0;
        }
        // Fade out for last 0.5 seconds
        else if (timer < duration) {
            alpha = 1.0 - (timer - (duration - 0.5)) / 0.5;
        }
        // Switch to menu
        else {
            Main.instance.sceneManager.switchTo(GameConfig.SCENE_MENU);
        }
    }
}
```

## Step 9: Create the Menu Scene

Now for an interactive menu. Create `src/MenuScene.hx`:

```haxe
class MenuScene extends Scene {
    public function new() {
        super(GameConfig.SCENE_MENU);
    }
    
    override function onEnter() {
        super.onEnter();
        
        // Title
        var title = new h2d.Text(hxd.res.DefaultFont.get(), this);
        title.text = "ACTION RPG";
        title.scale(3);
        title.textAlign = Center;
        title.x = GameConfig.GAME_WIDTH * 0.5;
        title.y = 40;
        
        // Start button
        createButton("Start Game", 100, () -> {
            Main.instance.sceneManager.switchTo(GameConfig.SCENE_GAME);
        });
        
        // Quit button
        createButton("Quit", 130, () -> {
            hxd.System.exit();
        });
    }
    
    function createButton(text:String, y:Float, onClick:Void->Void) {
        // Button background (invisible, just for clicking)
        var button = new h2d.Interactive(100, 20, this);
        button.x = GameConfig.GAME_WIDTH * 0.5 - 50;
        button.y = y - 10;
        
        // Button text
        var label = new h2d.Text(hxd.res.DefaultFont.get(), button);
        label.text = text;
        label.textAlign = Center;
        label.x = 50; // Center in button
        label.y = 5;
        
        // Handle mouse interaction
        button.onOver = function(e) {
            label.textColor = 0xFFFF00; // Yellow on hover
        };
        
        button.onOut = function(e) {
            label.textColor = 0xFFFFFF; // White normally
        };
        
        button.onClick = function(e) {
            onClick();
        };
    }
}
```

## Step 10: Create a Simple Game Scene

Let's add a basic game scene. Create `src/GameScene.hx`:

```haxe
class GameScene extends Scene {
    var player : h2d.Bitmap;
    
    public function new() {
        super(GameConfig.SCENE_GAME);
    }
    
    override function onEnter() {
        super.onEnter();
        
        // Instructions
        var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
        text.text = "Arrow keys to move, ESC for menu";
        text.x = 10;
        text.y = 10;
        
        // Create player (green square for now)
        var tile = h2d.Tile.fromColor(0x00FF00, 16, 16);
        player = new h2d.Bitmap(tile, this);
        
        // Center player
        player.x = GameConfig.GAME_WIDTH * 0.5 - 8;
        player.y = GameConfig.GAME_HEIGHT * 0.5 - 8;
    }
    
    override function update(dt:Float) {
        // Simple movement
        var speed = 100 * dt; // 100 pixels per second
        
        if (hxd.Key.isDown(hxd.Key.LEFT))  player.x -= speed;
        if (hxd.Key.isDown(hxd.Key.RIGHT)) player.x += speed;
        if (hxd.Key.isDown(hxd.Key.UP))    player.y -= speed;
        if (hxd.Key.isDown(hxd.Key.DOWN))  player.y += speed;
        
        // Return to menu
        if (hxd.Key.isPressed(hxd.Key.ESCAPE)) {
            Main.instance.sceneManager.switchTo(GameConfig.SCENE_MENU);
        }
    }
}
```

## Step 11: Wire Everything Together

Update `src/Main.hx` to use our scene system:

```haxe
import hxd.App;

class Main extends App {
    // Make Main accessible globally
    public static var instance : Main;
    
    // Scene management
    public var sceneManager : SceneManager;
    
    // Timing
    var accumulator = 0.0;
    var currentTime = 0.0;
    
    static function main() {
        new Main();
    }
    
    override function init() {
        instance = this;
        
        // Setup
        engine.backgroundColor = 0x1a1a2e;
        currentTime = hxd.Timer.lastTimeStamp;
        
        // Create scene manager
        sceneManager = new SceneManager(this);
        
        // Register all scenes
        sceneManager.addScene(new SplashScene());
        sceneManager.addScene(new MenuScene());
        sceneManager.addScene(new GameScene());
        
        // Start with splash screen
        sceneManager.switchTo(GameConfig.SCENE_SPLASH);
    }
    
    override function update(dt:Float) {
        // Fixed timestep logic
        var newTime = hxd.Timer.lastTimeStamp;
        var frameTime = newTime - currentTime;
        currentTime = newTime;
        
        accumulator += frameTime;
        
        while (accumulator >= GameConfig.FIXED_TIMESTEP) {
            fixedUpdate(GameConfig.FIXED_TIMESTEP);
            accumulator -= GameConfig.FIXED_TIMESTEP;
        }
    }
    
    function fixedUpdate(dt:Float) {
        // Update current scene
        sceneManager.update(dt);
    }
}
```

## Step 12: Add Smooth Transitions

Let's make scene transitions look professional. Create `src/Transition.hx`:

```haxe
class Transition {
    static var overlay : h2d.Bitmap;
    static var transitioning = false;
    
    // Fade to black, switch scene, then fade back
    public static function fadeTo(nextScene:String, duration=0.3) {
        if (transitioning) return;
        transitioning = true;
        
        var app = Main.instance;
        
        // Create black overlay if needed
        if (overlay == null) {
            var tile = h2d.Tile.fromColor(0x000000, 1, 1);
            overlay = new h2d.Bitmap(tile, app.s2d);
            overlay.scaleX = GameConfig.GAME_WIDTH;
            overlay.scaleY = GameConfig.GAME_HEIGHT;
        }
        
        // Start fade out
        overlay.alpha = 0;
        var fadeTime = 0.0;
        
        // Update function for the fade
        var updateFade = null;
        updateFade = function(dt:Float) {
            fadeTime += dt;
            var progress = fadeTime / duration;
            
            if (progress < 0.5) {
                // Fading out
                overlay.alpha = progress * 2;
            }
            else if (progress < 0.6) {
                // Switch scene in the middle
                overlay.alpha = 1;
                app.sceneManager.switchTo(nextScene);
            }
            else if (progress < 1.0) {
                // Fading in
                overlay.alpha = 2 - progress * 2;
            }
            else {
                // Done
                overlay.remove();
                overlay = null;
                transitioning = false;
                return false; // Stop updating
            }
            
            return true; // Continue updating
        };
        
        // Add to update loop
        app.updates.push(updateFade);
    }
}
```

Now update scene switches to use transitions:

```haxe
// In SplashScene
Transition.fadeTo(GameConfig.SCENE_MENU);

// In MenuScene start button
Transition.fadeTo(GameConfig.SCENE_GAME);

// In GameScene ESC handler
Transition.fadeTo(GameConfig.SCENE_MENU);
```

## Testing the Game

Run the game:
```bash
haxe build.hxml && hl bin/game.hl
```

You should see:
1. Splash screen fades in, shows "MY GAME STUDIO", fades out
2. Menu appears with "Start Game" and "Quit" buttons
3. Clicking "Start Game" transitions to the game
4. Arrow keys move the green square
5. ESC returns to the menu

## Common Issues

**Black screen?**
- Check that scene names match exactly in GameConfig
- Make sure init() calls sceneManager.switchTo()

**Scenes not switching?**
- Verify scenes are registered with addScene()
- Check console for "Scene not found" warnings

**Movement too fast/slow?**
- Adjust the speed value in GameScene
- Remember to multiply by dt for frame-independent movement

## Go Further

Try these modifications to deepen understanding:

1. **Add a Credits Scene**: Create a new scene that shows game credits
   - Add a "Credits" button to the menu
   - Display the developer name and "Made with Heaps"
   - Return to menu after 3 seconds or on key press

2. **Improve the Splash**: 
   - Add a subtitle "Presents" under the studio name
   - Make the text pulse (scale up and down slightly)

3. **Better Buttons**:
   - Add a background rectangle to buttons
   - Make buttons grow slightly on hover
   - Play a sound on click (if you know how)

## What We Did

- **Project Structure**: How to organize a Heaps game project
- **Fixed Timestep**: Why consistent timing matters for games  
- **Scene Management**: How to organize game content into scenes
- **Transitions**: Making smooth fade effects between scenes
- **Input Handling**: Responding to keyboard and mouse input
- **Game Loop**: The update cycle that powers everything

## Next Steps

Congratulations! You've built a solid foundation. The game can now:

- Switch between different scenes
- Handle player input
- Run at a consistent framerate
- Transition smoothly between states

In [Part 2: Core Systems](02-core-systems.md), we'll add a tile-based game world, a camera that follows the player, collision detection, and debug visualization tools.

Next up: [Part 2: Core Systems](02-core-systems.md)
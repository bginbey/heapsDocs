# Part 3: Player Movement

Let's make the player feel amazing to control! We'll transform the simple square into a responsive character with smooth movement and abilities.

## What We're Building

- Program 8-directional movement with acceleration and friction
- Develop a dash ability with cooldown timer
- Set up animation state machine for idle, walk, and dash states
- Craft a ghost trail effect using object pooling
- Fine-tune input buffering for responsive controls

## Step 1: Create the Player Class

The player needs its own class with movement properties.

Create `src/entities/Player.hx`:

```haxe
package entities;

import utils.GameConstants;

class Player extends Entity {
    // Movement properties
    public var speed = 0.0;
    public var maxSpeed = 150.0;
    public var acceleration = 800.0;
    public var friction = 600.0;
    
    // Dash properties
    public var canDash = true;
    var dashSpeed = 400.0;
    var dashDuration = 0.2;
    var dashCooldown = 0.3;
    var dashTimer = 0.0;
    var dashCooldownTimer = 0.0;
    var isDashing = false;
    
    // Direction facing (for dash direction)
    public var facingX = 1.0;
    public var facingY = 0.0;
    
    // Visual
    var sprite : h2d.Bitmap;
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Create visual (green square for now)
        sprite = new h2d.Bitmap(h2d.Tile.fromColor(0x00FF00, 14, 14), this);
        sprite.center();
        
        // Smaller collision box for better feel
        collisionBox = {
            x: -5,
            y: -5,
            width: 10,
            height: 10
        };
    }
    
    override function update(dt:Float) {
        // Update dash timers
        updateDash(dt);
        
        // Apply physics
        super.update(dt);
        
        // Update facing direction if moving
        if (Math.abs(vx) > 10 || Math.abs(vy) > 10) {
            var len = Math.sqrt(vx * vx + vy * vy);
            facingX = vx / len;
            facingY = vy / len;
        }
    }
    
    function updateDash(dt:Float) {
        // Dash duration
        if (isDashing) {
            dashTimer -= dt;
            if (dashTimer <= 0) {
                isDashing = false;
            }
        }
        
        // Dash cooldown
        if (!canDash) {
            dashCooldownTimer -= dt;
            if (dashCooldownTimer <= 0) {
                canDash = true;
            }
        }
    }
    
    public function startDash() {
        if (!canDash || isDashing) return;
        
        isDashing = true;
        canDash = false;
        dashTimer = dashDuration;
        dashCooldownTimer = dashCooldown;
        
        // Set velocity in facing direction
        vx = facingX * dashSpeed;
        vy = facingY * dashSpeed;
    }
}
```

## Step 2: Implement Input Handling

Create a dedicated input manager for clean control handling.

Create `src/systems/InputManager.hx`:

```haxe
package systems;

class InputManager {
    // Input state
    var left = false;
    var right = false;
    var up = false;
    var down = false;
    var dashPressed = false;
    
    // Input buffering
    var dashBuffer = 0.0;
    var bufferTime = 0.1; // 100ms buffer window
    
    public function new() {}
    
    public function update(dt:Float) {
        // Read current input state
        left = hxd.Key.isDown(hxd.Key.LEFT) || hxd.Key.isDown(hxd.Key.A);
        right = hxd.Key.isDown(hxd.Key.RIGHT) || hxd.Key.isDown(hxd.Key.D);
        up = hxd.Key.isDown(hxd.Key.UP) || hxd.Key.isDown(hxd.Key.W);
        down = hxd.Key.isDown(hxd.Key.DOWN) || hxd.Key.isDown(hxd.Key.S);
        
        // Dash input with buffer
        if (hxd.Key.isPressed(hxd.Key.SPACE) || hxd.Key.isPressed(hxd.Key.SHIFT)) {
            dashPressed = true;
            dashBuffer = bufferTime;
        }
        
        // Decay buffer
        if (dashBuffer > 0) {
            dashBuffer -= dt;
            if (dashBuffer <= 0) {
                dashPressed = false;
            }
        }
    }
    
    public function getMovementVector() : {x:Float, y:Float} {
        var mx = 0.0;
        var my = 0.0;
        
        if (left) mx -= 1;
        if (right) mx += 1;
        if (up) my -= 1;
        if (down) my += 1;
        
        // Normalize diagonal movement
        if (mx != 0 && my != 0) {
            mx *= 0.707; // 1/sqrt(2)
            my *= 0.707;
        }
        
        return {x: mx, y: my};
    }
    
    public function consumeDash() : Bool {
        if (dashPressed) {
            dashPressed = false;
            dashBuffer = 0;
            return true;
        }
        return false;
    }
}
```

## Step 3: Add Smooth Movement Physics

Update the player to use acceleration-based movement.

Update `src/entities/Player.hx` (add this method):

```haxe
public function handleMovement(input:systems.InputManager, dt:Float) {
    if (isDashing) return; // No control during dash
    
    var move = input.getMovementVector();
    
    if (move.x != 0 || move.y != 0) {
        // Accelerate in input direction
        vx += move.x * acceleration * dt;
        vy += move.y * acceleration * dt;
        
        // Clamp to max speed
        var currentSpeed = Math.sqrt(vx * vx + vy * vy);
        if (currentSpeed > maxSpeed) {
            vx = (vx / currentSpeed) * maxSpeed;
            vy = (vy / currentSpeed) * maxSpeed;
        }
    } else {
        // Apply friction when no input
        var currentSpeed = Math.sqrt(vx * vx + vy * vy);
        if (currentSpeed > 0) {
            var reduction = friction * dt;
            if (reduction > currentSpeed) {
                vx = vy = 0;
            } else {
                var factor = (currentSpeed - reduction) / currentSpeed;
                vx *= factor;
                vy *= factor;
            }
        }
    }
    
    // Handle dash input
    if (input.consumeDash()) {
        startDash();
    }
}
```

## Step 4: Create Animation States

Set up a simple state machine for animations.

Create `src/systems/AnimationState.hx`:

```haxe
package systems;

enum PlayerState {
    Idle;
    Walk;
    Dash;
}

class AnimationController {
    public var currentState : PlayerState = Idle;
    var player : entities.Player;
    var stateTime = 0.0;
    
    public function new(player:entities.Player) {
        this.player = player;
    }
    
    public function update(dt:Float) {
        stateTime += dt;
        
        // Determine state based on player properties
        var newState = currentState;
        
        if (player.isDashing) {
            newState = Dash;
        } else if (Math.abs(player.vx) > 10 || Math.abs(player.vy) > 10) {
            newState = Walk;
        } else {
            newState = Idle;
        }
        
        // State changed
        if (newState != currentState) {
            currentState = newState;
            stateTime = 0;
            onStateEnter(currentState);
        }
        
        // Update current state
        updateState(currentState, dt);
    }
    
    function onStateEnter(state:PlayerState) {
        switch(state) {
            case Idle:
                player.sprite.color.set(0, 1, 0); // Green
            case Walk:
                player.sprite.color.set(0.5, 1, 0.5); // Light green
            case Dash:
                player.sprite.color.set(1, 1, 0); // Yellow
        }
    }
    
    function updateState(state:PlayerState, dt:Float) {
        switch(state) {
            case Walk:
                // Bob up and down while walking
                player.sprite.y = Math.sin(stateTime * 10) * 2 - 7;
            case _:
                player.sprite.y = -7;
        }
    }
}
```

## Step 5: Implement Ghost Trail Effect

Create a pooled ghost effect for the dash ability.

Create `src/effects/GhostTrail.hx`:

```haxe
package effects;

class GhostTrail extends h2d.Object {
    var ghosts : Array<Ghost> = [];
    var ghostPool : Array<Ghost> = [];
    var spawnTimer = 0.0;
    var spawnInterval = 0.02; // Spawn every 20ms
    
    public function new(parent:h2d.Object) {
        super(parent);
    }
    
    public function spawnGhost(x:Float, y:Float, tile:h2d.Tile) {
        spawnTimer += spawnInterval;
        
        // Get ghost from pool
        var ghost = ghostPool.pop();
        if (ghost == null) {
            ghost = new Ghost(this);
        }
        
        ghost.reset(x, y, tile);
        ghosts.push(ghost);
    }
    
    public function update(dt:Float) {
        spawnTimer -= dt;
        
        // Update all active ghosts
        var i = ghosts.length;
        while (--i >= 0) {
            var ghost = ghosts[i];
            ghost.update(dt);
            
            if (ghost.isDead()) {
                ghosts.splice(i, 1);
                ghostPool.push(ghost);
            }
        }
    }
    
    public function shouldSpawn() : Bool {
        return spawnTimer <= 0;
    }
}

class Ghost extends h2d.Bitmap {
    var life = 0.3; // Ghost lasts 300ms
    var maxLife = 0.3;
    
    public function new(parent:h2d.Object) {
        super(parent);
        blendMode = Add; // Additive blending for glow effect
    }
    
    public function reset(x:Float, y:Float, tile:h2d.Tile) {
        this.x = x;
        this.y = y;
        this.tile = tile;
        life = maxLife;
        visible = true;
        alpha = 0.5;
        color.set(0.5, 0.8, 1); // Blueish tint
    }
    
    public function update(dt:Float) {
        life -= dt;
        
        // Fade out
        alpha = (life / maxLife) * 0.5;
        scaleX = scaleY = 1 + (1 - life / maxLife) * 0.2;
    }
    
    public function isDead() : Bool {
        return life <= 0;
    }
}
```

## Step 6: Wire Everything Together

Update GameScene to use the new player system.

Update `src/scenes/GameScene.hx`:

```haxe
// Add to class properties
var player : entities.Player;
var inputManager : systems.InputManager;
var ghostTrail : effects.GhostTrail;

// Update setupPlayer method
function setupPlayer() {
    // Create ghost trail layer (behind player)
    ghostTrail = new effects.GhostTrail(world);
    
    // Create player
    player = new entities.Player(world);
    player.setTilemap(tilemap);
    
    // Start in center of level
    player.x = tilemap.widthInTiles * systems.Tilemap.TILE_SIZE * 0.5;
    player.y = tilemap.heightInTiles * systems.Tilemap.TILE_SIZE * 0.5;
    
    // Create input manager
    inputManager = new systems.InputManager();
    
    // Add animation controller
    player.animController = new systems.AnimationController(player);
    
    // Camera follows player
    camera.follow(player, 0.1);
    camera.centerOn(player.x, player.y);
}

// Replace handleInput with
override function update(dt:Float) {
    // Update input
    inputManager.update(dt);
    
    // Update player
    player.handleMovement(inputManager, dt);
    player.update(dt);
    player.animController.update(dt);
    
    // Spawn ghosts during dash
    if (player.isDashing && ghostTrail.shouldSpawn()) {
        ghostTrail.spawnGhost(player.x, player.y, player.sprite.tile);
    }
    
    // Update effects
    ghostTrail.update(dt);
    
    // Update camera
    camera.update(dt);
    
    // Debug toggle
    if (hxd.Key.isPressed(hxd.Key.TAB)) {
        debugDisplay.toggle();
    }
    debugDisplay.update(dt);
    
    // Return to menu
    if (hxd.Key.isPressed(hxd.Key.ESCAPE)) {
        Main.instance.sceneManager.switchTo(GameConfig.SCENE_MENU);
    }
}
```

## Step 7: Add Visual Feedback

Enhance the player with visual indicators for dash state.

Update `src/entities/Player.hx` (add to class):

```haxe
// Visual feedback
var dashIndicator : h2d.Graphics;

// In constructor, after creating sprite
dashIndicator = new h2d.Graphics(this);
updateDashIndicator();

// Add new method
function updateDashIndicator() {
    dashIndicator.clear();
    
    if (canDash) {
        // Draw ready indicator
        dashIndicator.lineStyle(2, 0x00FFFF, 0.5);
        dashIndicator.drawCircle(0, 0, 12);
    } else {
        // Draw cooldown arc
        var progress = 1 - (dashCooldownTimer / dashCooldown);
        dashIndicator.lineStyle(2, 0xFF0000, 0.3);
        dashIndicator.arc(0, 0, 12, -Math.PI/2, -Math.PI/2 + Math.PI * 2 * progress);
    }
}

// Call in update method
updateDashIndicator();
```

## Step 8: Fine-tune the Feel

Add final polish with screen effects.

Update `src/scenes/GameScene.hx` (add to update method):

```haxe
// Screen shake on dash start
if (player.isDashing && player.dashTimer > player.dashDuration - 0.05) {
    camera.shake(0.1, 2); // 100ms shake, 2 pixel intensity
}

// Speed lines effect during dash
if (player.isDashing) {
    // This would be implemented with a shader or particle system
    // For now, we'll just make the background slightly darker
    root.filter = new h2d.filter.ColorMatrix();
    root.filter.matrix = h2d.filter.ColorMatrix.multiply(0.8);
} else {
    root.filter = null;
}
```

## Test the Game

Build and run:
```bash
haxe build.hxml && hl bin/game.hl
```

The game should display:
- Smooth player movement with WASD or arrow keys
- Dash ability with Space or Shift
- Ghost trail effect when dashing
- Visual feedback for dash cooldown
- Different colors for idle, walk, and dash states

## Common Issues

**Player moves too fast/slow?**
- Adjust `maxSpeed`, `acceleration`, and `friction` values
- Ensure delta time is applied correctly
- Check that diagonal movement is normalized

**Dash feels unresponsive?**
- Increase `bufferTime` in InputManager
- Reduce `dashCooldown` duration
- Ensure input is checked before physics update

**Ghost trail not visible?**
- Verify ghost trail is added before player in scene
- Check that `blendMode = Add` is set
- Ensure ghosts are spawned at correct position

## Go Further

Try these modifications to deepen understanding:

1. **Multiple Dash Charges**: 
   - Store 2-3 dash charges
   - Visual indicators for each charge
   - Recharge one at a time

2. **Dash Variations**:
   - Air dash with different properties
   - Dash through enemies for damage
   - Wall bounce when dashing into walls

3. **Advanced Movement**:
   - Coyote time (jump after leaving platform)
   - Movement momentum preservation
   - Speed boost pickups

## What We Did

- **Smooth Movement**: Acceleration and friction-based physics
- **Dash Mechanic**: Direction-based ability with cooldown
- **Input Buffering**: Responsive controls with input window
- **State Machine**: Clean animation state management
- **Visual Effects**: Ghost trail and dash indicators
- **Object Pooling**: Efficient ghost effect management

## Next Steps

Excellent work! The game now has:

- Fluid, responsive player movement
- Satisfying dash ability with visual feedback
- Professional input handling
- Efficient effect system

In [Part 4: Combat System](04-combat-system.md), we'll add 3-hit combo system, hitbox components, damage and knockback, and combat effects.

Next up: [Part 4: Combat System](04-combat-system.md)
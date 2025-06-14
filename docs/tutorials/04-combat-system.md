# Part 4: Combat System

Let's add satisfying combat mechanics! We'll create a combo system with proper hitboxes and impactful visual feedback.

## What We're Building

- Design a 3-hit combo system with timing windows
- Code hitbox components for attack collision
- Calculate damage and knockback physics
- Program screen shake and hit pause for impact
- Generate particle effects for hits and combos

## Step 1: Create the Combat Component

Build a modular combat system that can be added to any entity.

Create `src/components/CombatComponent.hx`:

```haxe
package components;

class CombatComponent {
    // Combat properties
    public var damage = 10;
    public var knockbackPower = 200.0;
    public var attackCooldown = 0.3;
    public var comboWindow = 0.5;
    
    // State
    public var canAttack = true;
    public var isAttacking = false;
    public var comboCount = 0;
    
    // Timers
    var attackTimer = 0.0;
    var comboTimer = 0.0;
    var cooldownTimer = 0.0;
    
    // Current attack hitbox
    public var activeHitbox : Hitbox;
    
    // Owner reference
    var owner : entities.Entity;
    
    public function new(owner:entities.Entity) {
        this.owner = owner;
    }
    
    public function update(dt:Float) {
        // Update attack duration
        if (isAttacking) {
            attackTimer -= dt;
            if (attackTimer <= 0) {
                endAttack();
            }
        }
        
        // Update combo window
        if (comboTimer > 0) {
            comboTimer -= dt;
            if (comboTimer <= 0) {
                comboCount = 0; // Reset combo
            }
        }
        
        // Update attack cooldown
        if (!canAttack) {
            cooldownTimer -= dt;
            if (cooldownTimer <= 0) {
                canAttack = true;
            }
        }
    }
    
    public function startAttack() : Bool {
        if (!canAttack || isAttacking) return false;
        
        // Increment combo
        if (comboTimer > 0 && comboCount < 3) {
            comboCount++;
        } else {
            comboCount = 1;
        }
        
        isAttacking = true;
        canAttack = false;
        attackTimer = 0.2; // 200ms attack duration
        cooldownTimer = attackCooldown;
        comboTimer = comboWindow;
        
        // Create hitbox based on combo
        createHitbox();
        
        return true;
    }
    
    function createHitbox() {
        // Different hitbox for each combo hit
        var hitboxData = switch(comboCount) {
            case 1: {x: 20, y: -10, w: 30, h: 20, duration: 0.15};
            case 2: {x: 20, y: -15, w: 35, h: 30, duration: 0.15};
            case 3: {x: 20, y: -20, w: 40, h: 40, duration: 0.2};
            default: {x: 20, y: -10, w: 30, h: 20, duration: 0.15};
        };
        
        // Position hitbox based on owner's facing direction
        if (owner.facingX < 0) {
            hitboxData.x = -hitboxData.x - hitboxData.w;
        }
        
        activeHitbox = new Hitbox(
            owner.x + hitboxData.x,
            owner.y + hitboxData.y,
            hitboxData.w,
            hitboxData.h,
            hitboxData.duration
        );
        
        // Increase damage for combo finisher
        if (comboCount == 3) {
            activeHitbox.damage = damage * 2;
        } else {
            activeHitbox.damage = damage;
        }
    }
    
    function endAttack() {
        isAttacking = false;
        activeHitbox = null;
    }
}
```

## Step 2: Implement Hitbox System

Create a flexible hitbox system for attacks and damage areas.

Create `src/components/Hitbox.hx`:

```haxe
package components;

class Hitbox {
    public var x : Float;
    public var y : Float;
    public var width : Float;
    public var height : Float;
    public var damage : Int;
    public var knockback : Float = 200;
    public var active = true;
    
    var lifetime : Float;
    
    public function new(x:Float, y:Float, width:Float, height:Float, lifetime:Float) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.lifetime = lifetime;
    }
    
    public function update(dt:Float) : Bool {
        lifetime -= dt;
        if (lifetime <= 0) {
            active = false;
            return false;
        }
        return true;
    }
    
    public function intersects(other:Hitbox) : Bool {
        return x < other.x + other.width &&
               x + width > other.x &&
               y < other.y + other.height &&
               y + height > other.y;
    }
    
    public function intersectsEntity(entity:entities.Entity) : Bool {
        var bounds = entity.getBounds();
        return x < bounds.x + bounds.width &&
               x + width > bounds.x &&
               y < bounds.y + bounds.height &&
               y + height > bounds.y;
    }
    
    public function getCenter() : {x:Float, y:Float} {
        return {
            x: x + width * 0.5,
            y: y + height * 0.5
        };
    }
}
```

## Step 3: Add Health System

Create a health component for damage handling.

Create `src/components/HealthComponent.hx`:

```haxe
package components;

class HealthComponent {
    public var current : Int;
    public var max : Int;
    public var invulnerable = false;
    
    // Invulnerability after taking damage
    var invulnerabilityTime = 0.5;
    var invulnerabilityTimer = 0.0;
    
    // Visual feedback
    public var isHurt = false;
    var hurtTime = 0.1;
    var hurtTimer = 0.0;
    
    // Callbacks
    public var onDamage : Int->Void;
    public var onDeath : Void->Void;
    
    public function new(maxHealth:Int) {
        this.max = maxHealth;
        this.current = maxHealth;
    }
    
    public function update(dt:Float) {
        // Update invulnerability
        if (invulnerable) {
            invulnerabilityTimer -= dt;
            if (invulnerabilityTimer <= 0) {
                invulnerable = false;
            }
        }
        
        // Update hurt visual
        if (isHurt) {
            hurtTimer -= dt;
            if (hurtTimer <= 0) {
                isHurt = false;
            }
        }
    }
    
    public function takeDamage(amount:Int) : Bool {
        if (invulnerable || current <= 0) return false;
        
        current -= amount;
        current = Std.int(Math.max(0, current));
        
        // Trigger effects
        invulnerable = true;
        invulnerabilityTimer = invulnerabilityTime;
        isHurt = true;
        hurtTimer = hurtTime;
        
        if (onDamage != null) {
            onDamage(amount);
        }
        
        if (current <= 0 && onDeath != null) {
            onDeath();
        }
        
        return true;
    }
    
    public function heal(amount:Int) {
        current += amount;
        current = Std.int(Math.min(max, current));
    }
    
    public function getPercentage() : Float {
        return current / max;
    }
}
```

## Step 4: Create Combat Effects

Build visual effects for attacks and impacts.

Create `src/effects/CombatEffects.hx`:

```haxe
package effects;

class CombatEffects {
    var scene : h2d.Object;
    var hitParticles : ParticlePool;
    var slashEffects : Array<SlashEffect> = [];
    
    public function new(scene:h2d.Object) {
        this.scene = scene;
        hitParticles = new ParticlePool(scene, 50);
    }
    
    public function spawnHitEffect(x:Float, y:Float, combo:Int) {
        // More particles for higher combo
        var count = 5 + combo * 3;
        
        for (i in 0...count) {
            var particle = hitParticles.get();
            if (particle == null) continue;
            
            // Random direction
            var angle = Math.random() * Math.PI * 2;
            var speed = 100 + Math.random() * 150;
            
            particle.reset(
                x + Math.random() * 10 - 5,
                y + Math.random() * 10 - 5,
                Math.cos(angle) * speed,
                Math.sin(angle) * speed
            );
            
            // Color based on combo
            if (combo >= 3) {
                particle.color = 0xFFFF00; // Yellow for finisher
            } else {
                particle.color = 0xFF4444; // Red for normal hits
            }
        }
    }
    
    public function spawnSlash(x:Float, y:Float, angle:Float, combo:Int) {
        var slash = new SlashEffect(scene);
        slash.spawn(x, y, angle, combo);
        slashEffects.push(slash);
    }
    
    public function update(dt:Float) {
        // Update particles
        hitParticles.update(dt);
        
        // Update slashes
        var i = slashEffects.length;
        while (--i >= 0) {
            if (!slashEffects[i].update(dt)) {
                slashEffects[i].remove();
                slashEffects.splice(i, 1);
            }
        }
    }
}

class SlashEffect extends h2d.Graphics {
    var life = 0.2;
    var maxLife = 0.2;
    var angle : Float;
    var combo : Int;
    
    public function new(parent:h2d.Object) {
        super(parent);
    }
    
    public function spawn(x:Float, y:Float, angle:Float, combo:Int) {
        this.x = x;
        this.y = y;
        this.angle = angle;
        this.combo = combo;
        life = maxLife;
        
        drawSlash();
    }
    
    function drawSlash() {
        clear();
        
        // Slash arc
        var radius = 20 + combo * 5;
        var thickness = 3 + combo;
        var arcAngle = Math.PI * 0.5; // 90 degree arc
        
        lineStyle(thickness, 0xFFFFFF, 0.8);
        arc(0, 0, radius, angle - arcAngle/2, angle + arcAngle/2);
        
        // Combo 3 gets extra effects
        if (combo >= 3) {
            lineStyle(thickness + 2, 0xFFFF00, 0.5);
            arc(0, 0, radius + 5, angle - arcAngle/2, angle + arcAngle/2);
        }
    }
    
    public function update(dt:Float) : Bool {
        life -= dt;
        alpha = life / maxLife;
        scaleX = scaleY = 1 + (1 - life/maxLife) * 0.3;
        
        return life > 0;
    }
}

class ParticlePool {
    var particles : Array<HitParticle> = [];
    var pool : Array<HitParticle> = [];
    var parent : h2d.Object;
    var maxParticles : Int;
    
    public function new(parent:h2d.Object, maxParticles:Int) {
        this.parent = parent;
        this.maxParticles = maxParticles;
        
        // Pre-allocate particles
        for (i in 0...maxParticles) {
            var p = new HitParticle(parent);
            p.visible = false;
            pool.push(p);
        }
    }
    
    public function get() : HitParticle {
        var p = pool.pop();
        if (p != null) {
            particles.push(p);
            p.visible = true;
        }
        return p;
    }
    
    public function update(dt:Float) {
        var i = particles.length;
        while (--i >= 0) {
            var p = particles[i];
            if (!p.update(dt)) {
                p.visible = false;
                particles.splice(i, 1);
                pool.push(p);
            }
        }
    }
}

class HitParticle extends h2d.Bitmap {
    var vx : Float;
    var vy : Float;
    var life : Float;
    public var color : Int;
    
    public function new(parent:h2d.Object) {
        super(h2d.Tile.fromColor(0xFFFFFF, 4, 4), parent);
        center();
    }
    
    public function reset(x:Float, y:Float, vx:Float, vy:Float) {
        this.x = x;
        this.y = y;
        this.vx = vx;
        this.vy = vy;
        life = 0.5;
        alpha = 1;
        scaleX = scaleY = 1;
    }
    
    public function update(dt:Float) : Bool {
        // Physics
        x += vx * dt;
        y += vy * dt;
        vy += 300 * dt; // Gravity
        
        // Fade out
        life -= dt;
        alpha = life * 2;
        
        // Apply color
        this.color.setColor(color);
        
        return life > 0;
    }
}
```

## Step 5: Implement Hit Pause

Add impactful hit pause for combat feedback.

Create `src/systems/HitPause.hx`:

```haxe
package systems;

class HitPause {
    static var pauseTime = 0.0;
    static var intensity = 1.0;
    
    public static function trigger(duration:Float, intensity=1.0) {
        pauseTime = duration;
        HitPause.intensity = intensity;
    }
    
    public static function update(dt:Float) : Float {
        if (pauseTime > 0) {
            pauseTime -= dt;
            
            // Return scaled dt for slow motion effect
            return dt * (1 - intensity);
        }
        
        return dt;
    }
    
    public static function isActive() : Bool {
        return pauseTime > 0;
    }
}
```

## Step 6: Update Player for Combat

Add combat capabilities to the player.

Update `src/entities/Player.hx`:

```haxe
// Add to imports
import components.CombatComponent;
import components.HealthComponent;

// Add to class properties
public var combat : CombatComponent;
public var health : HealthComponent;

// Add to constructor
combat = new CombatComponent(this);
health = new HealthComponent(100);

// Set up callbacks
health.onDamage = (damage) -> {
    // Flash red when hurt
    sprite.color.set(1, 0.5, 0.5);
    
    // Knockback
    var knockbackDir = Math.atan2(y - lastDamageY, x - lastDamageX);
    vx = Math.cos(knockbackDir) * 200;
    vy = Math.sin(knockbackDir) * 200;
};

// Add to update method
combat.update(dt);
health.update(dt);

// Visual feedback for hurt state
if (health.isHurt) {
    sprite.visible = Math.floor(stateTime * 20) % 2 == 0; // Flashing
} else if (health.invulnerable) {
    sprite.alpha = 0.5;
} else {
    sprite.visible = true;
    sprite.alpha = 1;
}

// Add attack method
public function attack() {
    if (combat.startAttack()) {
        // Stop movement during attack
        if (!isDashing) {
            vx *= 0.5;
            vy *= 0.5;
        }
    }
}
```

## Step 7: Create Combat Manager

Build a system to handle all combat interactions.

Create `src/systems/CombatManager.hx`:

```haxe
package systems;

class CombatManager {
    var players : Array<entities.Player> = [];
    var enemies : Array<entities.Enemy> = [];
    var effects : effects.CombatEffects;
    var camera : Camera;
    
    public function new(effects:effects.CombatEffects, camera:Camera) {
        this.effects = effects;
        this.camera = camera;
    }
    
    public function registerPlayer(player:entities.Player) {
        players.push(player);
    }
    
    public function registerEnemy(enemy:entities.Enemy) {
        enemies.push(enemy);
    }
    
    public function update(dt:Float) {
        // Check player attacks hitting enemies
        for (player in players) {
            if (player.combat.activeHitbox != null) {
                checkHitbox(player.combat.activeHitbox, enemies, player);
            }
        }
        
        // Check enemy attacks hitting players
        for (enemy in enemies) {
            if (enemy.combat != null && enemy.combat.activeHitbox != null) {
                checkHitbox(enemy.combat.activeHitbox, players, enemy);
            }
        }
    }
    
    function checkHitbox(hitbox:components.Hitbox, targets:Array<Dynamic>, attacker:Dynamic) {
        for (target in targets) {
            if (target.health.invulnerable) continue;
            
            if (hitbox.intersectsEntity(target)) {
                // Deal damage
                var damaged = target.health.takeDamage(hitbox.damage);
                
                if (damaged) {
                    // Visual effects
                    var hitPos = hitbox.getCenter();
                    effects.spawnHitEffect(hitPos.x, hitPos.y, attacker.combat.comboCount);
                    
                    // Slash effect
                    var angle = Math.atan2(
                        target.y - attacker.y,
                        target.x - attacker.x
                    );
                    effects.spawnSlash(hitPos.x, hitPos.y, angle, attacker.combat.comboCount);
                    
                    // Hit pause
                    var pauseDuration = attacker.combat.comboCount == 3 ? 0.1 : 0.05;
                    HitPause.trigger(pauseDuration, 0.9);
                    
                    // Camera shake
                    var shakeIntensity = attacker.combat.comboCount == 3 ? 5 : 2;
                    camera.shake(0.2, shakeIntensity);
                    
                    // Knockback
                    var knockbackAngle = Math.atan2(
                        target.y - attacker.y,
                        target.x - attacker.x
                    );
                    target.vx += Math.cos(knockbackAngle) * hitbox.knockback;
                    target.vy += Math.sin(knockbackAngle) * hitbox.knockback;
                    
                    // Disable hitbox after hit
                    hitbox.active = false;
                }
            }
        }
    }
}
```

## Step 8: Integrate Combat into GameScene

Wire up all combat systems in the game scene.

Update `src/scenes/GameScene.hx`:

```haxe
// Add to class properties
var combatEffects : effects.CombatEffects;
var combatManager : systems.CombatManager;

// Add to onEnter method, after creating world
combatEffects = new effects.CombatEffects(world);
combatManager = new systems.CombatManager(combatEffects, camera);

// In setupPlayer, after creating player
combatManager.registerPlayer(player);

// Update the update method
override function update(dt:Float) {
    // Apply hit pause
    var pausedDt = systems.HitPause.update(dt);
    
    // Update input
    inputManager.update(pausedDt);
    
    // Handle attack input
    if (hxd.Key.isPressed(hxd.Key.X) || hxd.Key.isPressed(hxd.Key.J)) {
        player.attack();
    }
    
    // Update with paused dt
    player.handleMovement(inputManager, pausedDt);
    player.update(pausedDt);
    
    // Update combat
    combatManager.update(pausedDt);
    combatEffects.update(pausedDt);
    
    // Other updates...
}

// Add to setupDebug
debugDisplay.addEntity(player);
if (player.combat.activeHitbox != null) {
    // Draw attack hitboxes in debug mode
}
```

## Test the Game

Build and run:
```bash
haxe build.hxml && hl bin/game.hl
```

The game should display:
- Attack with X or J key
- 3-hit combo system with timing
- Hit effects and slash visuals
- Screen shake and hit pause on impact
- Damage numbers (if implemented)

## Common Issues

**Attacks not connecting?**
- Check hitbox positioning relative to player facing
- Verify hitbox lifetime is long enough
- Ensure targets have health components

**No visual feedback?**
- Verify effects are added to correct layer
- Check that particle pool is initialized
- Ensure hit pause isn't too long

**Combo not working?**
- Increase combo window duration
- Check attack cooldown isn't too long
- Verify combo counter resets properly

## Go Further

Try these modifications to deepen understanding:

1. **Special Attacks**:
   - Charge attack with hold button
   - Area of effect spin attack
   - Projectile attacks

2. **Combat Variety**:
   - Different weapon types
   - Elemental damage types
   - Critical hit system

3. **Advanced Effects**:
   - Damage numbers floating up
   - Blood/spark particles
   - Weapon trails

## What We Did

- **Combo System**: Timing-based 3-hit combos
- **Hitbox Detection**: Flexible collision system
- **Health Management**: Damage, invulnerability, and death
- **Visual Impact**: Particles, slashes, and screen effects
- **Game Feel**: Hit pause and camera shake
- **Combat Architecture**: Modular component system

## Next Steps

Outstanding! The game now has:

- Responsive combat with combos
- Satisfying visual and tactile feedback
- Flexible systems for expansion
- Professional game feel

In [Part 5: Enemy AI](05-enemy-ai.md), we'll add intelligent enemies, patrol behaviors, combat AI, and multiple enemy types.

Next up: [Part 5: Enemy AI](05-enemy-ai.md)
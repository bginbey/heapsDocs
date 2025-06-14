# Part 5: Enemy AI

Let's bring the game world to life with intelligent enemies! We'll create state-based AI that can patrol, chase, and attack the player.

## What We're Building

- Build AI state machines with idle, patrol, chase, and attack states
- Program line of sight detection for player awareness
- Design multiple enemy types with different behaviors
- Set up a health system with damage and healing
- Polish with death animations and loot drops

## Step 1: Create the AI State Machine

Build a flexible state machine system for enemy behaviors.

Create `src/ai/AIState.hx`:

```haxe
package ai;

enum AIStateType {
    Idle;
    Patrol;
    Chase;
    Attack;
    Hurt;
    Dead;
}

class AIState {
    public var type : AIStateType;
    public var enemy : entities.Enemy;
    public var stateTime = 0.0;
    
    public function new(type:AIStateType, enemy:entities.Enemy) {
        this.type = type;
        this.enemy = enemy;
    }
    
    public function enter() {
        stateTime = 0;
        // Override in subclasses
    }
    
    public function update(dt:Float) : AIStateType {
        stateTime += dt;
        // Override in subclasses
        return type;
    }
    
    public function exit() {
        // Override in subclasses
    }
}

class IdleState extends AIState {
    var idleDuration = 2.0;
    
    public function new(enemy:entities.Enemy) {
        super(Idle, enemy);
    }
    
    override function enter() {
        super.enter();
        enemy.vx = enemy.vy = 0;
        idleDuration = 1 + Math.random() * 2; // 1-3 seconds
    }
    
    override function update(dt:Float) : AIStateType {
        super.update(dt);
        
        // Look for player
        if (enemy.canSeePlayer()) {
            return Chase;
        }
        
        // Switch to patrol after idle time
        if (stateTime >= idleDuration) {
            return Patrol;
        }
        
        return Idle;
    }
}

class PatrolState extends AIState {
    var direction : Float;
    var patrolTime = 0.0;
    var patrolDuration = 3.0;
    
    public function new(enemy:entities.Enemy) {
        super(Patrol, enemy);
    }
    
    override function enter() {
        super.enter();
        // Random patrol direction
        direction = Math.random() * Math.PI * 2;
        patrolDuration = 2 + Math.random() * 2;
        
        // Set velocity
        enemy.vx = Math.cos(direction) * enemy.patrolSpeed;
        enemy.vy = Math.sin(direction) * enemy.patrolSpeed;
    }
    
    override function update(dt:Float) : AIStateType {
        super.update(dt);
        patrolTime += dt;
        
        // Look for player
        if (enemy.canSeePlayer()) {
            return Chase;
        }
        
        // Change direction on collision or timeout
        if (enemy.hitWall || patrolTime >= patrolDuration) {
            return Idle;
        }
        
        return Patrol;
    }
}

class ChaseState extends AIState {
    var lostPlayerTime = 0.0;
    var maxLostTime = 2.0;
    
    public function new(enemy:entities.Enemy) {
        super(Chase, enemy);
    }
    
    override function update(dt:Float) : AIStateType {
        super.update(dt);
        
        var player = enemy.getPlayer();
        if (player == null) return Idle;
        
        // Can we still see the player?
        if (enemy.canSeePlayer()) {
            lostPlayerTime = 0;
            
            // Move toward player
            var dx = player.x - enemy.x;
            var dy = player.y - enemy.y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            
            if (dist > 0) {
                enemy.vx = (dx / dist) * enemy.chaseSpeed;
                enemy.vy = (dy / dist) * enemy.chaseSpeed;
            }
            
            // Close enough to attack?
            if (dist < enemy.attackRange) {
                return Attack;
            }
        } else {
            // Lost sight of player
            lostPlayerTime += dt;
            if (lostPlayerTime >= maxLostTime) {
                return Idle;
            }
        }
        
        return Chase;
    }
}

class AttackState extends AIState {
    var attackCooldown = 1.0;
    var hasAttacked = false;
    
    public function new(enemy:entities.Enemy) {
        super(Attack, enemy);
    }
    
    override function enter() {
        super.enter();
        enemy.vx = enemy.vy = 0;
        hasAttacked = false;
    }
    
    override function update(dt:Float) : AIStateType {
        super.update(dt);
        
        var player = enemy.getPlayer();
        if (player == null) return Idle;
        
        // Attack after brief windup
        if (!hasAttacked && stateTime > 0.3) {
            enemy.performAttack();
            hasAttacked = true;
        }
        
        // Return to chase after cooldown
        if (stateTime >= attackCooldown) {
            var dist = Math.sqrt(
                Math.pow(player.x - enemy.x, 2) + 
                Math.pow(player.y - enemy.y, 2)
            );
            
            if (dist > enemy.attackRange) {
                return Chase;
            } else {
                return Attack; // Attack again
            }
        }
        
        return Attack;
    }
}
```

## Step 2: Create the Base Enemy Class

Build a flexible enemy class that uses the state machine.

Create `src/entities/Enemy.hx`:

```haxe
package entities;

import ai.*;
import components.*;

class Enemy extends Entity {
    // AI properties
    public var patrolSpeed = 50.0;
    public var chaseSpeed = 100.0;
    public var attackRange = 30.0;
    public var sightRange = 150.0;
    public var sightAngle = Math.PI * 0.5; // 90 degree cone
    
    // State machine
    var stateMachine : AIStateMachine;
    var currentState : AIState;
    
    // Components
    public var health : HealthComponent;
    public var combat : CombatComponent;
    
    // References
    var player : Player;
    
    // Visual
    var sprite : h2d.Bitmap;
    public var hitWall = false;
    
    // Loot
    var lootTable : Array<{type:String, chance:Float}> = [
        {type: "health", chance: 0.3},
        {type: "coin", chance: 0.7}
    ];
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Create visual (red square for now)
        sprite = new h2d.Bitmap(h2d.Tile.fromColor(0xFF0000, 14, 14), this);
        sprite.center();
        
        // Set up components
        health = new HealthComponent(30);
        combat = new CombatComponent(this);
        combat.damage = 5;
        
        // Health callbacks
        health.onDamage = onDamage;
        health.onDeath = onDeath;
        
        // Collision box
        collisionBox = {
            x: -6,
            y: -6,
            width: 12,
            height: 12
        };
        
        // Initialize AI
        setupStateMachine();
    }
    
    function setupStateMachine() {
        stateMachine = new AIStateMachine(this);
        
        // Add states
        stateMachine.addState(new IdleState(this));
        stateMachine.addState(new PatrolState(this));
        stateMachine.addState(new ChaseState(this));
        stateMachine.addState(new AttackState(this));
        
        // Start in idle
        stateMachine.changeState(Idle);
    }
    
    public function setPlayer(player:Player) {
        this.player = player;
    }
    
    public function getPlayer() : Player {
        return player;
    }
    
    override function update(dt:Float) {
        // Update AI
        stateMachine.update(dt);
        
        // Update components
        health.update(dt);
        combat.update(dt);
        
        // Check wall collision for patrol
        var oldX = x;
        var oldY = y;
        
        super.update(dt);
        
        // Detect if we hit a wall
        hitWall = (x == oldX && vx != 0) || (y == oldY && vy != 0);
        
        // Visual feedback
        updateVisuals();
    }
    
    function updateVisuals() {
        // Color based on state
        switch(stateMachine.currentState.type) {
            case Idle:
                sprite.color.set(0.5, 0, 0); // Dark red
            case Patrol:
                sprite.color.set(0.7, 0, 0); // Medium red
            case Chase:
                sprite.color.set(1, 0, 0); // Bright red
            case Attack:
                sprite.color.set(1, 0.5, 0); // Orange
            case _:
                sprite.color.set(0.3, 0, 0);
        }
        
        // Hurt flash
        if (health.isHurt) {
            sprite.color.set(1, 1, 1); // White flash
        }
        
        // Death fade
        if (stateMachine.currentState.type == Dead) {
            alpha = Math.max(0, 1 - stateMachine.currentState.stateTime);
        }
    }
    
    public function canSeePlayer() : Bool {
        if (player == null) return false;
        
        var dx = player.x - x;
        var dy = player.y - y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        
        // Too far?
        if (dist > sightRange) return false;
        
        // Check angle
        var angleToPlayer = Math.atan2(dy, dx);
        var facingAngle = Math.atan2(vy, vx);
        var angleDiff = Math.abs(angleToPlayer - facingAngle);
        
        // Normalize angle difference
        if (angleDiff > Math.PI) angleDiff = Math.PI * 2 - angleDiff;
        
        // Within sight cone?
        return angleDiff < sightAngle * 0.5;
    }
    
    public function performAttack() {
        combat.startAttack();
        
        // Face player
        if (player != null) {
            facingX = player.x > x ? 1 : -1;
            facingY = 0;
        }
    }
    
    function onDamage(damage:Int) {
        // Interrupt current action
        stateMachine.changeState(Chase);
        
        // Knockback handled by combat system
    }
    
    function onDeath() {
        stateMachine.changeState(Dead);
        
        // Drop loot
        dropLoot();
    }
    
    function dropLoot() {
        for (item in lootTable) {
            if (Math.random() < item.chance) {
                // Spawn loot at enemy position
                var loot = new Loot(parent, item.type);
                loot.x = x;
                loot.y = y;
                
                // Random velocity
                loot.vx = Math.random() * 100 - 50;
                loot.vy = -Math.random() * 100 - 50;
            }
        }
    }
}

class AIStateMachine {
    var states : Map<AIStateType, AIState> = new Map();
    public var currentState : AIState;
    var enemy : Enemy;
    
    public function new(enemy:Enemy) {
        this.enemy = enemy;
    }
    
    public function addState(state:AIState) {
        states.set(state.type, state);
    }
    
    public function changeState(type:AIStateType) {
        if (currentState != null) {
            currentState.exit();
        }
        
        currentState = states.get(type);
        if (currentState != null) {
            currentState.enter();
        }
    }
    
    public function update(dt:Float) {
        if (currentState == null) return;
        
        var nextState = currentState.update(dt);
        if (nextState != currentState.type) {
            changeState(nextState);
        }
    }
}
```

## Step 3: Create Enemy Variants

Design different enemy types with unique behaviors.

Create `src/entities/enemies/Goblin.hx`:

```haxe
package entities.enemies;

class Goblin extends Enemy {
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Goblin stats
        health.max = health.current = 20;
        patrolSpeed = 40;
        chaseSpeed = 80;
        attackRange = 25;
        sightRange = 120;
        combat.damage = 3;
        
        // Smaller and green
        sprite.tile = h2d.Tile.fromColor(0x00FF00, 12, 12);
        sprite.center();
        
        collisionBox = {
            x: -5,
            y: -5,
            width: 10,
            height: 10
        };
    }
    
    override function updateVisuals() {
        // Green color variations
        switch(stateMachine.currentState.type) {
            case Idle:
                sprite.color.set(0, 0.5, 0);
            case Patrol:
                sprite.color.set(0, 0.7, 0);
            case Chase:
                sprite.color.set(0, 1, 0);
            case Attack:
                sprite.color.set(0.5, 1, 0);
            case _:
                sprite.color.set(0, 0.3, 0);
        }
        
        super.updateVisuals();
    }
}

class Orc extends Enemy {
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Orc stats - tankier but slower
        health.max = health.current = 50;
        patrolSpeed = 30;
        chaseSpeed = 60;
        attackRange = 35;
        sightRange = 100;
        combat.damage = 8;
        combat.knockbackPower = 300;
        
        // Larger and darker
        sprite.tile = h2d.Tile.fromColor(0x804040, 18, 18);
        sprite.center();
        
        collisionBox = {
            x: -8,
            y: -8,
            width: 16,
            height: 16
        };
    }
}

class Archer extends Enemy {
    var projectileSpeed = 200.0;
    var shootRange = 150.0;
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Archer stats - ranged attacker
        health.max = health.current = 15;
        patrolSpeed = 35;
        chaseSpeed = 70;
        attackRange = 150; // Ranged
        sightRange = 200;
        combat.damage = 4;
        
        // Blue color
        sprite.tile = h2d.Tile.fromColor(0x4040FF, 12, 14);
        sprite.center();
    }
    
    override function performAttack() {
        // Shoot projectile instead of melee
        if (player == null) return;
        
        var dx = player.x - x;
        var dy = player.y - y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        
        if (dist > 0) {
            var projectile = new Projectile(parent);
            projectile.x = x;
            projectile.y = y;
            projectile.vx = (dx / dist) * projectileSpeed;
            projectile.vy = (dy / dist) * projectileSpeed;
            projectile.damage = combat.damage;
            projectile.owner = this;
        }
    }
}
```

## Step 4: Create Loot System

Build a simple loot drop system for defeated enemies.

Create `src/entities/Loot.hx`:

```haxe
package entities;

class Loot extends Entity {
    public var type : String;
    var sprite : h2d.Bitmap;
    var bobTime = 0.0;
    var magnetRange = 50.0;
    var collectRange = 20.0;
    var lifetime = 10.0; // Disappear after 10 seconds
    
    public function new(parent:h2d.Object, type:String) {
        super(parent);
        this.type = type;
        
        // Visual based on type
        switch(type) {
            case "health":
                sprite = new h2d.Bitmap(h2d.Tile.fromColor(0xFF0040, 8, 8), this);
            case "coin":
                sprite = new h2d.Bitmap(h2d.Tile.fromColor(0xFFD700, 6, 6), this);
            default:
                sprite = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF, 6, 6), this);
        }
        sprite.center();
        
        // No collision with walls
        collisionBox = {x: 0, y: 0, width: 0, height: 0};
    }
    
    override function update(dt:Float) {
        lifetime -= dt;
        
        // Blink when about to disappear
        if (lifetime < 2) {
            visible = Math.floor(lifetime * 10) % 2 == 0;
        }
        
        // Remove when expired
        if (lifetime <= 0) {
            remove();
            return;
        }
        
        // Physics with friction
        super.update(dt);
        vx *= 0.9;
        vy *= 0.9;
        
        // Bobbing animation
        bobTime += dt;
        sprite.y = Math.sin(bobTime * 5) * 2 - 4;
        
        // Magnet toward player
        var player = Main.instance.game.sceneManager.currentScene.player;
        if (player != null) {
            var dx = player.x - x;
            var dy = player.y - y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            
            // Magnet effect
            if (dist < magnetRange && dist > 0) {
                var force = (1 - dist / magnetRange) * 200;
                vx += (dx / dist) * force * dt;
                vy += (dy / dist) * force * dt;
            }
            
            // Collect
            if (dist < collectRange) {
                collect(player);
            }
        }
    }
    
    function collect(player:Player) {
        switch(type) {
            case "health":
                player.health.heal(10);
                // Spawn effect
                spawnCollectEffect(0xFF0040);
                
            case "coin":
                // Add to score/currency
                spawnCollectEffect(0xFFD700);
        }
        
        remove();
    }
    
    function spawnCollectEffect(color:Int) {
        // Create simple particle burst
        for (i in 0...8) {
            var angle = (i / 8) * Math.PI * 2;
            var particle = new h2d.Bitmap(
                h2d.Tile.fromColor(color, 3, 3),
                parent
            );
            particle.x = x;
            particle.y = y;
            
            // Animate outward
            var vx = Math.cos(angle) * 50;
            var vy = Math.sin(angle) * 50;
            var life = 0.5;
            
            Main.instance.updates.push((dt) -> {
                life -= dt;
                if (life <= 0) {
                    particle.remove();
                    return false;
                }
                
                particle.x += vx * dt;
                particle.y += vy * dt;
                particle.alpha = life * 2;
                
                return true;
            });
        }
    }
}
```

## Step 5: Add Line of Sight Visualization

Create debug visualization for enemy sight.

Update `src/systems/DebugDisplay.hx`:

```haxe
// Add to class properties
var showEnemySight = true;

// Add to update method, in the drawing section
if (showEnemySight) {
    drawEnemySight();
}

// Add new method
function drawEnemySight() {
    graphics.lineStyle(1, 0xFF0000, 0.3);
    
    for (entity in entities) {
        if (Std.isOfType(entity, entities.Enemy)) {
            var enemy = cast(entity, entities.Enemy);
            
            // Skip if not visible
            if (!camera.isVisible(enemy)) continue;
            
            // Draw sight cone
            var facingAngle = Math.atan2(enemy.vy, enemy.vx);
            if (enemy.vx == 0 && enemy.vy == 0) {
                facingAngle = enemy.facingX > 0 ? 0 : Math.PI;
            }
            
            var leftAngle = facingAngle - enemy.sightAngle * 0.5;
            var rightAngle = facingAngle + enemy.sightAngle * 0.5;
            
            var ex = enemy.x + camera.scene.x;
            var ey = enemy.y + camera.scene.y;
            
            // Draw cone lines
            graphics.moveTo(ex, ey);
            graphics.lineTo(
                ex + Math.cos(leftAngle) * enemy.sightRange,
                ey + Math.sin(leftAngle) * enemy.sightRange
            );
            
            graphics.moveTo(ex, ey);
            graphics.lineTo(
                ex + Math.cos(rightAngle) * enemy.sightRange,
                ey + Math.sin(rightAngle) * enemy.sightRange
            );
            
            // Draw arc
            graphics.lineStyle(1, 0xFF0000, 0.2);
            graphics.drawCircle(ex, ey, enemy.sightRange);
            
            // Highlight if seeing player
            if (enemy.canSeePlayer()) {
                graphics.lineStyle(2, 0xFF0000, 0.8);
                graphics.drawCircle(ex, ey, 10);
            }
        }
    }
}
```

## Step 6: Create Enemy Spawning System

Build a system to spawn enemies in the level.

Create `src/systems/EnemySpawner.hx`:

```haxe
package systems;

class EnemySpawner {
    var scene : h2d.Object;
    var enemies : Array<entities.Enemy> = [];
    var player : entities.Player;
    var combatManager : CombatManager;
    var debugDisplay : DebugDisplay;
    
    // Spawn data
    var spawnPoints : Array<{x:Float, y:Float, type:String}> = [];
    
    public function new(scene:h2d.Object, player:entities.Player, 
                       combatManager:CombatManager, debugDisplay:DebugDisplay) {
        this.scene = scene;
        this.player = player;
        this.combatManager = combatManager;
        this.debugDisplay = debugDisplay;
    }
    
    public function addSpawnPoint(x:Float, y:Float, type:String) {
        spawnPoints.push({x: x, y: y, type: type});
    }
    
    public function spawnAll() {
        for (point in spawnPoints) {
            spawnEnemy(point.x, point.y, point.type);
        }
    }
    
    public function spawnEnemy(x:Float, y:Float, type:String) {
        var enemy = switch(type) {
            case "goblin": new entities.enemies.Goblin(scene);
            case "orc": new entities.enemies.Orc(scene);
            case "archer": new entities.enemies.Archer(scene);
            default: new entities.Enemy(scene);
        };
        
        enemy.x = x;
        enemy.y = y;
        enemy.setPlayer(player);
        enemy.setTilemap(player.tilemap);
        
        enemies.push(enemy);
        combatManager.registerEnemy(enemy);
        debugDisplay.addEntity(enemy);
    }
    
    public function update(dt:Float) {
        // Update all enemies
        var i = enemies.length;
        while (--i >= 0) {
            var enemy = enemies[i];
            enemy.update(dt);
            
            // Remove dead enemies after fade
            if (enemy.alpha <= 0) {
                enemy.remove();
                enemies.splice(i, 1);
            }
        }
    }
    
    public function getAliveCount() : Int {
        var count = 0;
        for (enemy in enemies) {
            if (enemy.health.current > 0) count++;
        }
        return count;
    }
}
```

## Step 7: Implement Death State

Add a death state for enemies with animation.

Create `src/ai/DeadState.hx`:

```haxe
package ai;

class DeadState extends AIState {
    var deathDuration = 2.0;
    
    public function new(enemy:entities.Enemy) {
        super(Dead, enemy);
    }
    
    override function enter() {
        super.enter();
        
        // Stop movement
        enemy.vx = enemy.vy = 0;
        
        // Disable collision
        enemy.collisionBox = {x: 0, y: 0, width: 0, height: 0};
        
        // Disable combat
        enemy.combat.canAttack = false;
    }
    
    override function update(dt:Float) : AIStateType {
        super.update(dt);
        
        // Just stay dead
        return Dead;
    }
}
```

## Step 8: Wire Everything into GameScene

Integrate the enemy system into the game.

Update `src/scenes/GameScene.hx`:

```haxe
// Add to class properties
var enemySpawner : systems.EnemySpawner;
var enemyCount : h2d.Text;

// Add to onEnter, after setting up player
setupEnemies();

// Add new method
function setupEnemies() {
    enemySpawner = new systems.EnemySpawner(world, player, combatManager, debugDisplay);
    
    // Add spawn points based on level
    // These would normally come from level data
    enemySpawner.addSpawnPoint(200, 100, "goblin");
    enemySpawner.addSpawnPoint(300, 150, "goblin");
    enemySpawner.addSpawnPoint(400, 200, "orc");
    enemySpawner.addSpawnPoint(250, 300, "archer");
    
    // Spawn all enemies
    enemySpawner.spawnAll();
}

// Update the update method
override function update(dt:Float) {
    // ... existing code ...
    
    // Update enemies
    enemySpawner.update(pausedDt);
    
    // Update enemy count display
    if (enemyCount != null) {
        enemyCount.text = 'Enemies: ${enemySpawner.getAliveCount()}';
    }
}

// Add to setupUI
enemyCount = new h2d.Text(hxd.res.DefaultFont.get(), this);
enemyCount.x = GameConfig.GAME_WIDTH - 80;
enemyCount.y = 10;
enemyCount.textAlign = Right;
```

## Test the Game

Build and run:
```bash
haxe build.hxml && hl bin/game.hl
```

The game should display:
- Multiple enemy types patrolling the level
- Enemies chase when they see the player
- Different behaviors for each enemy type
- Enemies drop loot when defeated
- Debug view shows enemy sight cones

## Common Issues

**Enemies not moving?**
- Check that tilemap is set on enemies
- Verify state machine is initialized
- Ensure player reference is set

**Enemies stuck in walls?**
- Adjust patrol state wall detection
- Check collision box sizes
- Add pathfinding for smarter navigation

**No loot drops?**
- Verify loot parent is set correctly
- Check that death callback triggers
- Ensure loot lifetime is long enough

## Go Further

Try these modifications to deepen understanding:

1. **Advanced AI Behaviors**:
   - Group coordination (surround player)
   - Fleeing when low health
   - Calling for reinforcements

2. **Enemy Abilities**:
   - Shield blocking
   - Dodge rolling
   - Special attacks

3. **Spawning Systems**:
   - Wave-based spawning
   - Difficulty scaling
   - Boss enemies

## What We Did

- **State Machine AI**: Flexible behavior system
- **Line of Sight**: Realistic enemy awareness
- **Enemy Variety**: Multiple types with unique stats
- **Loot System**: Rewards for defeating enemies
- **Death Handling**: Clean enemy removal
- **Debug Visualization**: See AI decision making

## Next Steps

Congratulations! The game is now complete with:

- Smooth player movement and abilities
- Satisfying combat with visual feedback
- Intelligent enemies with varied behaviors
- Professional game architecture

The foundation is ready for expansion. Consider adding:
- More enemy types and boss battles
- Level progression and save system
- Equipment and upgrade systems
- Multiplayer support

Great work completing the Action RPG tutorial series!
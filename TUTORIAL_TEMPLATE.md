# Tutorial Template Guide

This template defines the structure and format for all Heaps documentation tutorials. Follow this guide to maintain consistency across the tutorial series.

## Tutorial Structure

```markdown
# Part [N]: [Tutorial Name]

[Brief introduction sentence explaining what will be built]

## What We're Building

- [Action verb] [specific feature/system]
- [Action verb] [specific feature/system]
- [Action verb] [specific feature/system]
- [Action verb] [specific feature/system]
```

## Section Order

1. **Title and Introduction**
2. **What We're Building**
3. **Step-by-Step Implementation** (multiple steps)
4. **Testing**
5. **Common Issues**
6. **Go Further**
7. **What We Did**
8. **Next Steps**
9. **Next up: [Link]**

## Detailed Section Templates

### 1. Title and Introduction

```markdown
# Part [N]: [Tutorial Name]

Let's [action verb] the [system/feature]! We'll [brief description of the journey].
```

### 2. What We're Building

```markdown
## What We're Building

- [Action verb] [specific feature with technical details]
- [Action verb] [specific feature with technical details]
- [Action verb] [specific feature with technical details]
- [Action verb] [specific feature with technical details]
```

**Guidelines:**
- Use varied action verbs (Create, Build, Code, Design, Implement, Program, Wire up, etc.)
- Include technical specifics (e.g., "16x16 pixel tiles" not just "tiles")
- Match exactly what's listed in the overview page

### 3. Step-by-Step Implementation

```markdown
## Step [N]: [Clear Action Title]

[Brief explanation of what this step accomplishes]. [Optional: link to Dive Deeper page].

Create `src/[path/to/File.hx]`:

```haxe
// Code with helpful inline comments
// Comments explain decisions, not obvious syntax
```

[Brief explanation of key concepts if needed]
```

**Guidelines:**
- Each step should be atomic and testable
- Use "Create" for new files, "Update" for modifications
- Include the full file path
- Comments in code should explain "why" not "what"
- Keep explanations brief and practical

### 4. Testing Section

```markdown
## Test the Game

Build and run:
```bash
haxe build.hxml && hl bin/game.hl
```

The game should display:
- [What they'll see]
- [What they can do]
- [What to verify]
```

### 5. Common Issues

```markdown
## Common Issues

**[Problem description]?**
- [Solution step 1]
- [Solution step 2]
- [Verification step]

**[Problem description]?**
- [Solution step 1]
- [Solution step 2]
```

**Guidelines:**
- Focus on actual problems beginners face
- Provide concrete solutions
- Include how to verify the fix worked

### 6. Go Further

```markdown
## Go Further

Try these modifications to deepen understanding:

1. **[Enhancement Name]**: [Brief description]
   - [Specific task]
   - [Specific task]
   - [Expected outcome]

2. **[Enhancement Name]**: [Brief description]
   - [Specific task]
   - [Specific task]

3. **[Enhancement Name]**: [Brief description]
   - [Specific task]
   - [Specific task]
```

### 7. What We Did

```markdown
## What We Did

- **[System/Concept]**: [What it does/why it matters]
- **[System/Concept]**: [What it does/why it matters]
- **[System/Concept]**: [What it does/why it matters]
- **[System/Concept]**: [What it does/why it matters]
```

**Guidelines:**
- Use bullet points with bold concept names
- Focus on what was accomplished, not how
- Keep descriptions concise

### 8. Next Steps

```markdown
## Next Steps

[Congratulatory message]. The game now has:

- [Feature achieved]
- [Feature achieved]
- [Feature achieved]
- [Feature achieved]

In [Part N: Next Tutorial](next-tutorial.md), we'll add [feature], [feature], [feature], and [feature].
```

**Guidelines:**
- Start with encouragement
- List must have blank line before it
- Future features as comma-separated sentence

### 9. Navigation Link

```markdown
Next up: [Part N: Tutorial Name](filename.md)
```

## Writing Style Guidelines

### Language
- Use "the" instead of "your" (e.g., "the game" not "your game")
- Active voice and action verbs
- Present tense for instructions
- No motivational speeches or pep talks

### Code Examples
```haxe
// Good comment: explains why
// Use fixed timestep for deterministic physics
var dt = 1.0 / 60.0;

// Bad comment: explains what
// Set dt to 1/60
var dt = 1.0 / 60.0;
```

### Formatting
- Use `inline code` for:
  - File names: `Main.hx`
  - Function names: `update()`
  - Variables: `playerSpeed`
  - Commands: `haxe build.hxml`

- Use **bold** for:
  - Emphasis on important concepts
  - Names in structured lists

- Use *italics* sparingly

## Tutorial Length Guidelines

- **Target**: 600-800 lines total
- **Steps**: 8-12 implementation steps
- **Code blocks**: Show complete, working code
- **Explanations**: Brief and practical

## Example Step Structure

```markdown
## Step 3: Create the Player Entity

The player needs physics and collision detection.

Create `src/entities/Player.hx`:

```haxe
package entities;

class Player extends Entity {
    var speed = 150.0; // Pixels per second
    
    public function new(parent:h2d.Object) {
        super(parent);
        
        // Green square for now, will add sprites later
        var visual = new h2d.Bitmap(
            h2d.Tile.fromColor(0x00FF00, 16, 16), 
            this
        );
        visual.center();
    }
    
    override function update(dt:Float) {
        // Handle input in next step
        super.update(dt);
    }
}
```

The player extends our base Entity class to inherit collision and physics behavior.
```

## Checklist for New Tutorials

- [ ] Title matches overview page exactly
- [ ] "What We're Building" matches overview bullets
- [ ] All code examples tested and working
- [ ] Comments explain decisions, not syntax
- [ ] Common issues address real problems
- [ ] "Go Further" exercises are achievable
- [ ] Language uses "the" not "your"
- [ ] Next tutorial link is correct
- [ ] No "Ready to... Let's go!" lines
- [ ] Sections in correct order

## Version Control

When updating tutorials:
1. Maintain backwards compatibility
2. Note Heaps version requirements if needed
3. Update the overview page if scope changes

---

This template ensures consistency across all tutorials while maintaining flexibility for different topics.
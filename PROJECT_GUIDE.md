# Heaps Documentation Project Guide

## Project Vision

Create a comprehensive, beginner-friendly documentation site for the Heaps game engine that teaches through practical example - building a complete action RPG inspired by Hyper Light Drifter.

## Core Principles

### 1. Simplicity First
- Use MkDocs for clean, markdown-only documentation
- Avoid complex build processes or JavaScript frameworks
- Focus on content over features

### 2. Learn by Doing
- Every concept taught through practical game development
- Real-world examples from the actionRPG project
- Progressive complexity from basics to advanced

### 3. Best Practices
- Clean, consistent code style
- Well-structured project organization
- Performance-conscious implementations
- Git workflow with semantic commits

### 4. Content Guidelines

#### Writing Style
- **Clarity First**: Write for beginners while providing depth
- **Show, Don't Tell**: Include runnable code examples
- **Visual Learning**: Use diagrams and screenshots where helpful
- **Practical Focus**: Real-world game development scenarios
- **Progressive Complexity**: Start simple, build up gradually

#### Code Style
```haxe
// Clear variable names, no abbreviations
var playerSpeed = 150.0;  // pixels per second

// Comments explain "why", not "what"
// Dash cooldown prevents spam and balances gameplay
var dashCooldown = 0.3;

// Consistent formatting, 4-space indent
class Player extends h2d.Object {
    public function new() {
        super();
    }
}
```

#### Documentation Structure
- **500-1000 words per page** - Focused, digestible content
- **Code-first approach** - Lead with examples
- **Exercises at the end** - Optional challenges
- **Clear navigation** - Logical progression

## Project Structure

```
heapsDocs/
├── docs/                    # Documentation content
│   ├── index.md            # Home page with logo
│   ├── getting-started/    # Setup and basics
│   │   ├── installation.md # Complete ✓
│   │   ├── hello-world.md  # Complete ✓
│   │   └── project-structure.md # Complete ✓
│   ├── core-concepts/      # Engine fundamentals
│   │   ├── game-loop.md    # Complete ✓
│   │   ├── scenes.md       # Complete ✓
│   │   ├── resources.md    # Complete ✓
│   │   ├── entities.md     # Complete ✓
│   │   └── rendering.md    # Complete ✓
│   ├── tutorials/          # Action RPG series
│   │   ├── 00-overview.md  # Complete ✓
│   │   ├── 01-foundation.md # Complete ✓
│   │   ├── 02-core-systems.md # TODO
│   │   ├── 03-player-movement.md # TODO
│   │   ├── 04-combat-system.md # TODO
│   │   └── 05-enemy-ai.md  # TODO
│   └── reference/          # Quick references
│       ├── api-cheatsheet.md # TODO
│       └── troubleshooting.md # TODO
├── mkdocs.yml              # Site configuration
├── requirements.txt        # Python dependencies
├── serve.sh               # Dev server script
└── actionRPG/             # Reference project

Status: 11/18 pages complete (61%)
```

## Content Roadmap

### Phase 1: Foundation (COMPLETE ✓)
- [x] Project setup and configuration
- [x] Home page with branding
- [x] Getting Started section (3 guides)
- [x] Core Concepts section (5 pages)
- [x] Tutorial overview and structure
- [x] Tutorial 1: Foundation

### Phase 2: Tutorial Series (IN PROGRESS)
- [x] Tutorial 1: Foundation - Scene management, game loop
- [ ] Tutorial 2: Core Systems - Tilemap, camera, entities
- [ ] Tutorial 3: Player Movement - Controls, dash, animations
- [ ] Tutorial 4: Combat System - Attacks, effects, game feel
- [ ] Tutorial 5: Enemy AI - State machines, behaviors

### Phase 3: Reference & Polish
- [ ] API Cheatsheet - Common patterns and snippets
- [ ] Troubleshooting Guide - Common issues and solutions
- [ ] Search optimization
- [ ] Community contributions guide

### Phase 4: Deployment
- [ ] GitHub Pages setup
- [ ] Custom domain configuration
- [ ] Analytics integration
- [ ] Community feedback incorporation

## Tutorial Series Plan

Each tutorial follows the actionRPG project phases:

### Tutorial 2: Core Systems
- Tilemap implementation (16x16 grid)
- Camera system with bounds and smooth follow
- Entity-Component architecture
- Debug overlay and tools
- Collision detection basics

### Tutorial 3: Player Movement
- 8-directional movement with acceleration
- Dash mechanic with cooldown
- Ghost trail effects using object pooling
- Input handling patterns
- Animation state machine

### Tutorial 4: Combat System
- Melee combat with 3-hit combos
- Hitbox system and damage calculation
- Particle effects for impacts
- Screen shake and hit pause
- Health system with UI

### Tutorial 5: Enemy AI & Polish
- AI state machines (patrol, chase, attack)
- Line of sight detection
- Multiple enemy types
- Visual polish (shaders, particles)
- Audio integration
- Performance optimization

## Technical Standards

### Performance Targets
- 60 FPS with 50+ enemies
- < 16ms frame time
- < 100MB memory usage
- < 1000 draw calls

### Code Quality
- No methods > 50 lines
- No classes > 300 lines
- Clear separation of concerns
- Comprehensive error handling

## Git Workflow

### Branch Strategy
```
main          # Production docs
├── develop   # Integration branch
└── feature/* # Individual features
```

### Commit Convention
```
docs: Add player movement tutorial
tutorial: Implement dash mechanic example
fix: Correct code sample in game-loop.md
chore: Update dependencies
```

### Pull Request Template
```markdown
## Summary
Brief description of changes

## Type
- [ ] Documentation
- [ ] Tutorial
- [ ] Bug fix
- [ ] Other

## Checklist
- [ ] Code samples tested
- [ ] Links verified
- [ ] Spelling checked
- [ ] Follows style guide
```

## Development Commands

```bash
# Local development
./serve.sh

# Build for production
mkdocs build

# Deploy to GitHub Pages
mkdocs gh-deploy

# Install dependencies
pip install -r requirements.txt
```

## Resources

- **Source Project**: [github.com/bginbey/actionRPG](https://github.com/bginbey/actionRPG)
- **Heaps Official**: [heaps.io](https://heaps.io)
- **Heaps GitHub**: [github.com/HeapsIO/heaps](https://github.com/HeapsIO/heaps)
- **MkDocs**: [mkdocs.org](https://www.mkdocs.org)

## Next Actions

1. **Immediate**
   - Complete Tutorial 2: Core Systems
   - Test all code examples

2. **Short Term**
   - Finish tutorial series (3-5)
   - Create API cheatsheet
   - Add troubleshooting guide

3. **Long Term**
   - Deploy to GitHub Pages
   - Gather community feedback
   - Add advanced topics
   - Create video companions

## Success Metrics

- Clear, understandable documentation
- Working code examples throughout
- Complete tutorial series
- Active community engagement
- Regular updates and improvements

---

This guide serves as the single source of truth for project direction and standards.
# Heaps Documentation Project Context

## Project Overview
Building comprehensive documentation for the Heaps game engine with a focus on learning through creating an action RPG. Using MkDocs with Material theme for simplicity.

## Current Status (As of 2025-01-14)
- ✅ MkDocs setup complete with Material theme
- ✅ Project structure established
- ✅ Getting Started section (3/3 guides complete)
- ✅ Core Concepts section (5/5 pages complete)
- ✅ Tutorial 1: Foundation complete
- ⏳ Tutorials 2-5 pending
- ⏳ Reference section pending

## Key Decisions Made
1. **Documentation Framework**: MkDocs (simple, markdown-based)
2. **Tutorial Approach**: Based on actionRPG project phases
3. **Code Style**: Clear naming, comments explain why not what
4. **Performance Targets**: 60 FPS, <16ms frame time

## Project Structure
```
/Users/beauginbey/Developer/GameDev/heapsDocs/
├── docs/           # All markdown content
├── actionRPG/      # Reference project (cloned)
├── mkdocs.yml      # Site configuration
├── serve.sh        # Local server script
└── PROJECT_GUIDE.md # Comprehensive project guide
```

## Important Context
- The actionRPG project is the basis for all tutorials
- Focus on practical, game development scenarios
- Target audience: Beginners to intermediate developers
- Each tutorial builds on the previous one
- Fixed timestep game loop is a core concept throughout

## Next Tasks Priority
1. Create Tutorial 2: Core Systems (Tilemap, Camera, Entities)
2. Create Tutorial 3: Player Movement (8-way movement, dash)
3. Create Tutorial 4: Combat System (Attacks, effects)
4. Create Tutorial 5: Enemy AI (State machines)
5. Write API Cheatsheet
6. Write Troubleshooting Guide
7. Set up GitHub Pages deployment

## Key Files to Reference
- `/actionRPG/src/` - Source code for tutorials
- `/actionRPG/DEVELOPMENT_ROADMAP.md` - Tutorial content guide
- `/docs/tutorials/01-foundation.md` - Template for tutorial style
- `PROJECT_GUIDE.md` - All project principles and standards

## Commands
- Run locally: `./serve.sh`
- Build: `mkdocs build`
- The site runs on http://localhost:8000

## Style Reminders
- Keep responses concise (game dev context)
- Use code examples liberally
- Focus on practical implementation
- Maintain consistent tutorial structure
- Test all code examples before including

## Tutorial Structure Template
See TUTORIAL_TEMPLATE.md for the complete guide. Key sections:
1. Title and Introduction
2. What We're Building (matches overview page)
3. Step-by-Step Implementation (8-12 steps)
4. Test the Game
5. Common Issues
6. Go Further (exercises)
7. What We Did (summary)
8. Next Steps
9. Next up: [Link]

Remember: The goal is to teach Heaps through building a real game, not just explaining concepts.
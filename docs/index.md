# Heaps Game Engine Guide

<div align="center">
  <img src="assets/logo.svg" alt="Heaps Logo" width="200" style="margin: 2rem 0;" class="theme-adaptive-logo">
</div>

Welcome to the comprehensive guide for **Heaps.io** - a mature, cross-platform graphics engine designed for high-performance games.

## What is Heaps?

Heaps is a game engine built with [Haxe](https://haxe.org) that leverages modern GPU capabilities for both 2D and 3D games. It's the technology behind successful indie games like Dead Cells, Northgard, and Evoland.

## Why Choose Heaps?

- **Performance First**: GPU-accelerated rendering with automatic batching
- **Cross-Platform**: Deploy to PC, mobile, consoles, and web from a single codebase
- **Modern Architecture**: Component-based entities, shader system, and resource pipeline
- **Battle-Tested**: Used in commercial games with millions of players
- **Open Source**: MIT licensed with active community

## Quick Start

```haxe
class Main extends hxd.App {
    override function init() {
        var text = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        text.text = "Hello Heaps!";
        text.center();
    }
    
    static function main() {
        new Main();
    }
}
```

[Get Started →](getting-started/installation.md){ .md-button .md-button--primary }

## What You'll Learn

### Getting Started
Learn to set up your development environment and create your first Heaps application.

### Core Concepts
Understand the fundamental systems: game loop, scenes, resources, entities, and rendering pipeline.

### Build an Action RPG
Follow our step-by-step tutorial series to create a complete top-down action game inspired by Hyper Light Drifter.

## Tutorial Preview

Throughout this guide, you'll build a fully-featured action RPG with:

- ⚡ **Fluid Movement**: 8-directional movement with dash mechanics
- ⚔️ **Combat System**: Combo attacks, hitboxes, and visual effects
- 🤖 **Enemy AI**: State machines, pathfinding, and varied behaviors
- ✨ **Polish**: Particles, screen shake, and shader effects
- 🎮 **Game Feel**: Responsive controls and satisfying feedback

## Community

- [Heaps Website](https://heaps.io)
- [GitHub Repository](https://github.com/HeapsIO/heaps)
- [Showcase](https://heaps.io/showcase)

## Prerequisites

- Basic programming knowledge (preferably Haxe, but JavaScript/TypeScript experience helps)
- Understanding of game development concepts
- A code editor (VS Code recommended)
- Enthusiasm for making games!

---

Ready to start building? Head to the [Installation Guide](getting-started/installation.md) →
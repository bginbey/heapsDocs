# Installation

Setting up Heaps for game development requires three components: Haxe (the language), Heaps (the engine), and a runtime (HashLink or JavaScript).

## Prerequisites

### 1. Install Haxe

Haxe is the programming language that Heaps is built with.

=== "Windows"

    Download and run the installer from [haxe.org](https://haxe.org/download/)

=== "macOS"

    ```bash
    # Using Homebrew
    brew install haxe
    ```

=== "Linux"

    ```bash
    # Ubuntu/Debian
    sudo apt install haxe
    
    # Or download from haxe.org
    ```

Verify installation:
```bash
haxe --version  # Should show 4.x.x
```

### 2. Install Visual Studio Code

While any editor works, VS Code offers the best Heaps development experience.

1. Download from [code.visualstudio.com](https://code.visualstudio.com/)
2. Install the **Haxe Extension Pack** from the marketplace

### 3. Install HashLink (Recommended)

HashLink is a virtual machine designed for Haxe, providing native performance.

=== "Windows"

    Download the installer from [hashlink.haxe.org](https://hashlink.haxe.org/)

=== "macOS"

    ```bash
    brew install hashlink
    ```

=== "Linux"

    Build from source or use the provided binaries at [hashlink.haxe.org](https://hashlink.haxe.org/)

!!! note "Apple Silicon Users"
    HashLink doesn't fully support ARM64 yet. Use the web target for development on M1/M2/M3 Macs.

## Install Heaps

Install Heaps and its dependencies using haxelib (Haxe's package manager):

```bash
haxelib install heaps
haxelib install hlsdl     # For native builds
haxelib install hxnodejs  # For Node.js builds (optional)
```

## Create Your First Project

1. Create a new directory:
```bash
mkdir my-heaps-game
cd my-heaps-game
```

2. Create `build.hxml` for HashLink:
```hxml
-cp src
-lib heaps
-lib hlsdl
-hl bin/game.hl
-main Main
```

3. Create `build-web.hxml` for web builds:
```hxml
-cp src
-lib heaps
-js bin/game.js
-main Main
-dce full
```

4. Create `src/Main.hx`:
```haxe
class Main extends hxd.App {
    override function init() {
        // Your game starts here
    }
    
    static function main() {
        new Main();
    }
}
```

5. Build and run:
```bash
# For HashLink
haxe build.hxml
hl bin/game.hl

# For Web
haxe build-web.hxml
# Open bin/index.html in browser
```

## IDE Setup

### VS Code Configuration

1. Create `.vscode/tasks.json`:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build HashLink",
            "type": "shell",
            "command": "haxe build.hxml",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "label": "Run HashLink",
            "type": "shell",
            "command": "hl bin/game.hl",
            "dependsOn": "Build HashLink"
        }
    ]
}
```

2. Create `.vscode/launch.json` for debugging:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "HashLink",
            "type": "hl",
            "request": "launch",
            "program": "${workspaceFolder}/bin/game.hl",
            "preLaunchTask": "Build HashLink"
        }
    ]
}
```

## Verify Installation

Create this test file as `src/Main.hx`:

```haxe
class Main extends hxd.App {
    override function init() {
        var text = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        text.text = "Heaps is working!";
        text.scale(3);
        text.center();
    }
    
    override function update(dt:Float) {
        // dt is in seconds
    }
    
    static function main() {
        new Main();
    }
}
```

If you see "Heaps is working!" on screen, you're ready to build games!

## Troubleshooting

### Common Issues

**"Library heaps not found"**
: Run `haxelib install heaps` again

**"Type not found: hxd.App"**
: Make sure `-lib heaps` is in your build.hxml

**HashLink crashes on launch**
: Ensure hlsdl is installed: `haxelib install hlsdl`

**Black screen on web build**
: Create an HTML file that includes your JS:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Heaps Game</title>
    <style>
        body { margin: 0; padding: 0; }
        canvas { width: 100%; height: 100vh; }
    </style>
</head>
<body>
    <script src="game.js"></script>
</body>
</html>
```

## Next Steps

You're ready to create your first game! Continue to [Hello World →](hello-world.md)
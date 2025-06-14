# Heaps Game Engine Documentation

A comprehensive documentation site for the Heaps.io game engine, featuring getting started guides, core concepts, and a complete tutorial series for building an action RPG.

🌐 **Live Documentation**: [https://bginbey.github.io/heapsDocs](https://bginbey.github.io/heapsDocs)

## Features

- 📚 **Getting Started Guide** - Installation, Hello World, and project structure
- 🎮 **Core Concepts** - Game loop, scenes, resources, entities, and rendering
- 🎯 **Tutorial Series** - Build a complete action RPG step-by-step
- 📖 **API Reference** - Quick reference and troubleshooting

## Local Development

### Prerequisites

- Python 3.8+
- pip

### Setup

1. Clone the repository:
```bash
git clone https://github.com/bginbey/heapsDocs.git
cd heapsDocs
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the development server:
```bash
./serve.sh
# or
mkdocs serve
```

4. Open http://localhost:8000 in your browser

## Building for Production

Build the static site:
```bash
mkdocs build
```

The built site will be in the `site/` directory.

## Project Structure

```
heapsDocs/
├── docs/                    # Documentation source files
│   ├── index.md            # Home page
│   ├── getting-started/    # Installation and basics
│   ├── core-concepts/      # Engine fundamentals
│   ├── tutorials/          # Action RPG tutorial series
│   └── reference/          # API reference
├── mkdocs.yml              # MkDocs configuration
├── requirements.txt        # Python dependencies
└── serve.sh               # Development server script
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Writing Guidelines

- Write for clarity and beginners
- Include code examples
- Use proper markdown formatting
- Test all code samples

## Tutorial Series

The tutorial series builds a complete action RPG game:

1. **Foundation** - Project setup and scene management
2. **Core Systems** - Tilemap, camera, and entities
3. **Player Movement** - Controls and dash mechanics
4. **Combat System** - Attacks, damage, and effects
5. **Enemy AI** - State machines and behaviors

## License

This documentation is licensed under the MIT License.

## Acknowledgments

- Heaps.io development team
- Tutorial based on the actionRPG project
- MkDocs and Material theme developers
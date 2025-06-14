#!/bin/bash

# Install dependencies if needed
if ! command -v mkdocs &> /dev/null; then
    echo "Installing MkDocs and dependencies..."
    pip install -r requirements.txt
fi

# Serve the documentation
echo "Starting MkDocs server..."
echo "Documentation will be available at http://localhost:8000"
mkdocs serve
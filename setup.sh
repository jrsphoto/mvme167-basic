#!/bin/bash
# Setup VS Code for MVME167 Enhanced BASIC project

PROJECT_DIR="${1:-.}"

if [ ! -f "$PROJECT_DIR/Makefile" ]; then
    echo "Error: Makefile not found in $PROJECT_DIR"
    echo "Usage: $0 [project_directory]"
    exit 1
fi

echo "Setting up VS Code configuration in: $PROJECT_DIR"

# Create .vscode directory
mkdir -p "$PROJECT_DIR/.vscode"

# settings.json
cat > "$PROJECT_DIR/.vscode/settings.json" << 'EOF'
{
    "files.exclude": {
        "**/.git": true,
        "**/build": false,
        "**/*.o": false
    },
    "files.watcherExclude": {
        "**/build/**": true,
        "**/.git/**": true
    },
    "search.exclude": {
        "**/build": true,
        "**/.git": true
    },
    "editor.formatOnSave": false,
    "editor.insertSpaces": false,
    "editor.detectIndentation": true,
    "[asm]": {
        "editor.insertSpaces": false,
        "editor.tabSize": 8
    },
    "files.associations": {
        "*.s": "asm",
        "*.asm": "asm",
        "*.x68": "asm"
    },
    "workbench.colorCustomizations": {
        "editorLineNumber.foreground": "#858585"
    }
}
EOF
echo "✓ Created .vscode/settings.json"

# extensions.json
cat > "$PROJECT_DIR/.vscode/extensions.json" << 'EOF'
{
    "recommendations": [
        "ms-vscode.makefile-tools",
        "prb28.better-makefile",
        "moxnr.vasm",
        "ms-vscode.serial-monitor"
    ]
}
EOF
echo "✓ Created .vscode/extensions.json"

# tasks.json
cat > "$PROJECT_DIR/.vscode/tasks.json" << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "make: build (RAM)",
            "type": "shell",
            "command": "make",
            "args": ["clean", "all"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "shared",
                "clear": false
            }
        },
        {
            "label": "make: build ROM",
            "type": "shell",
            "command": "make",
            "args": ["rom"],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "make: clean",
            "type": "shell",
            "command": "make",
            "args": ["clean"],
            "group": "build",
            "presentation": {
                "reveal": "silent",
                "panel": "shared"
            }
        },
        {
            "label": "make: disasm",
            "type": "shell",
            "command": "make",
            "args": ["disasm"],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "make: test",
            "type": "shell",
            "command": "make",
            "args": ["test"],
            "group": "test",
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "show: help",
            "type": "shell",
            "command": "make",
            "args": ["help"],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "show: S-record info",
            "type": "shell",
            "command": "bash",
            "args": ["-c", "file build/*.srec && echo '' && wc -l build/*.srec && echo '' && ls -lh build/*.srec"],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        }
    ]
}
EOF
echo "✓ Created .vscode/tasks.json"

# launch.json
cat > "$PROJECT_DIR/.vscode/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "GDB: MVME167 Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/enhanced_basic_ram.elf",
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "MIMode": "gdb",
            "miDebuggerPath": "m68k-elf-gdb",
            "preLaunchTask": "make: build (RAM)"
        }
    ]
}
EOF
echo "✓ Created .vscode/launch.json"

echo ""
echo "✅ VS Code setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open VS Code: code $PROJECT_DIR"
echo "  2. Install recommended extensions (Ctrl+Shift+X)"
echo "  3. Build: Ctrl+Shift+B"
echo "  4. View tasks: Terminal → Run Task"
echo ""
echo "Quick reference:"
echo "  Ctrl+Shift+B  Build (default)"
echo "  Ctrl+Shift+P  Command palette"
echo "  Ctrl+\`        Toggle terminal"
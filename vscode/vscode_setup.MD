VS Code Setup for 68k Cross-Development on MVME167
====================================================

YES, you can absolutely integrate the m68k cross tools into VS Code.
It's actually the recommended way to work because:
- Integrated terminal for build commands
- Syntax highlighting for assembly
- Task automation (build, clean, load)
- Debugging helpers
- Git integration for version control

PREREQUISITES
--------------
You need:
1. VS Code installed
2. m68k-elf toolchain installed (binutils, gcc, etc.)
3. vasm (optional but recommended)
4. A terminal that can reach your MVME167 (serial connection)

STEP 1: INSTALL THE CROSS-TOOLCHAIN (if not already done)
-----------------------------------------------------------

On Linux (Ubuntu/Debian):
  sudo apt-get install binutils-m68k-linux-gnu gcc-m68k-linux-gnu

On macOS (with Homebrew):
  brew install m68k-elf-binutils

On Windows (WSL or MinGW):
  Same as Linux above, or use Windows native MinGW

Verify installation:
  m68k-elf-as --version
  m68k-elf-ld --version
  m68k-elf-objcopy --version

Note: Your tools might be named:
  - m68k-elf-* (standard)
  - m68k-linux-gnu-* (Linux variant)
  - m68k-none-elf-* (bare-metal variant)
All work; just adjust the CROSS prefix in your Makefile accordingly.

STEP 2: VS CODE EXTENSIONS
---------------------------

Open VS Code and install these extensions:

1. "m68k" by prb28
   - Motorola 68k assembly syntax highlighting
   - Search: m68k in Extensions marketplace
   - Provides color-coding for 68k syntax

2. "C/C++ Tools" by Microsoft (optional)
   - Useful even for assembly projects
   - Provides IntelliSense for header files
   - Good for editing .h files

3. "Makefile Tools" by Microsoft
   - Auto-detects Makefile targets
   - Provides build UI in Explorer
   - Run targets from command palette

4. "Serial Monitor" by DeviceChip
   - Integrates serial terminal into VS Code
   - Talk to your MVME167 without external terminal
   - Search: serial monitor

5. "Better Comments" by Aaron Bond (optional)
   - Color-codes comment blocks
   - Makes assembly code easier to read

Install these from Extensions (Ctrl+Shift+X or Cmd+Shift+X):
  - Type extension name
  - Click Install

STEP 3: PROJECT STRUCTURE
--------------------------

Create a folder structure for your project:

mvme167-basic/
├── .vscode/
│   ├── settings.json          (editor settings)
│   ├── tasks.json             (build tasks)
│   ├── launch.json            (debugging, if needed)
│   └── extensions.json        (recommended extensions)
├── src/
│   ├── enhanced_basic.s       (main BASIC code)
│   ├── cd2401_io_68k.s        (serial I/O routines)
│   └── mvme167.inc            (includes/definitions)
├── include/
│   └── cd2401_registers.h     (register definitions)
├── build/                      (generated files - add to .gitignore)
├── Makefile                    (your build commands)
├── .gitignore
└── README.md

STEP 4: VSCODE SETTINGS (.vscode/settings.json)
------------------------------------------------

Create .vscode/settings.json:

{
  "editor.defaultFormatter": "ms-vscode.makefile-tools",
  "editor.formatOnSave": false,
  "[m68k-asm]": {
    "editor.defaultFormatter": null
  },
  "editor.rulers": [80, 120],
  "editor.insertSpaces": true,
  "editor.tabSize": 8,
  "files.exclude": {
    "**/build": true,
    "**/.DS_Store": true,
    "**/*.o": true,
    "**/*.elf": true,
    "**/*.srec": true
  },
  "search.exclude": {
    "**/build": true,
    "**/node_modules": true
  },
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "args": ["-l"]
    }
  }
}

STEP 5: BUILD TASKS (.vscode/tasks.json)
-----------------------------------------

Create .vscode/tasks.json to automate builds:

{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build BASIC (RAM, 400000)",
      "type": "shell",
      "command": "make",
      "args": ["clean", "all"],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Build BASIC ROM (FF800000)",
      "type": "shell",
      "command": "make",
      "args": ["rom"],
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Clean",
      "type": "shell",
      "command": "make",
      "args": ["clean"],
      "problemMatcher": []
    },
    {
      "label": "Hex Dump (for verification)",
      "type": "shell",
      "command": "hexdump",
      "args": ["-C", "build/enhanced_basic.srec"],
      "problemMatcher": []
    }
  ]
}

Now you can:
  - Press Ctrl+Shift+B to run default build
  - Press Ctrl+Shift+P, type "Tasks: Run Task" to see all tasks
  - Select "Build BASIC (RAM, 400000)" or "Build BASIC ROM"

STEP 6: COMPLETE MAKEFILE
--------------------------

Create/update your Makefile:

```makefile
# m68k Enhanced BASIC for MVME167
# Cross-compiler toolchain paths

CROSS ?= m68k-elf-
AS = $(CROSS)as
LD = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

# Compiler flags
ASFLAGS = -m68040 --register-prefix-optional --bitwise-or

# Memory layout
RAM_BASE = 0x00400000
ROM_BASE = 0xFF800000

# Source files
SOURCES = src/enhanced_basic.s src/cd2401_io_68k.s
HEADERS = include/cd2401_registers.h

# Output directory
BUILD_DIR = build
OBJS = $(BUILD_DIR)/enhanced_basic.o

# Targets
.PHONY: all clean rom test

all: $(BUILD_DIR)/enhanced_basic.srec

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/enhanced_basic.o: $(SOURCES) $(HEADERS) | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $(SOURCES)

$(BUILD_DIR)/enhanced_basic.elf: $(BUILD_DIR)/enhanced_basic.o
	$(LD) --oformat elf32-m68k -Ttext $(RAM_BASE) -o $@ $^

$(BUILD_DIR)/enhanced_basic.srec: $(BUILD_DIR)/enhanced_basic.elf
	$(OBJCOPY) -O srec $< $@
	@echo "S-record created: $@"
	@ls -lh $@

rom: $(BUILD_DIR)/enhanced_basic_rom.elf

$(BUILD_DIR)/enhanced_basic_rom.elf: $(BUILD_DIR)/enhanced_basic.o
	$(LD) --oformat elf32-m68k -Ttext $(ROM_BASE) -o $@ $^
	$(OBJCOPY) -O srec $@ $(BUILD_DIR)/enhanced_basic_rom.srec
	@echo "ROM S-record created: $(BUILD_DIR)/enhanced_basic_rom.srec"
	@ls -lh $(BUILD_DIR)/enhanced_basic_rom.srec

disasm: $(BUILD_DIR)/enhanced_basic.elf
	$(OBJDUMP) -d $(BUILD_DIR)/enhanced_basic.elf > $(BUILD_DIR)/enhanced_basic.asm
	@echo "Disassembly: $(BUILD_DIR)/enhanced_basic.asm"

test: $(BUILD_DIR)/enhanced_basic.srec
	@echo "Build successful!"
	@ls -lh $(BUILD_DIR)/

clean:
	rm -rf $(BUILD_DIR)/*
	@echo "Clean complete"

help:
	@echo "Targets:"
	@echo "  make all       - Build RAM version (default)"
	@echo "  make rom       - Build ROM version"
	@echo "  make disasm    - Generate disassembly"
	@echo "  make clean     - Remove generated files"
	@echo "  make test      - Verify build"
```

Copy this as your Makefile (no .txt extension).

STEP 7: LAUNCH CONFIGURATION (optional debugging)
--------------------------------------------------

Create .vscode/launch.json for GDB debugging (if you want):

{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "GDB MVME167",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/build/enhanced_basic.elf",
      "args": [],
      "stopAtEntry": true,
      "cwd": "${workspaceFolder}",
      "environment": [],
      "externalConsole": false,
      "MIMode": "gdb",
      "miDebuggerPath": "m68k-elf-gdb",
      "setupCommands": [
        {
          "description": "Enable pretty-printing for gdb",
          "text": "-enable-pretty-printing",
          "ignoreFailures": true
        }
      ]
    }
  ]
}

(This requires m68k-elf-gdb installed, which is optional)

STEP 8: GIT CONFIGURATION (recommended)
---------------------------------------

Create .gitignore:

# Build artifacts
build/
*.o
*.elf
*.srec
*.bin
*.asm

# Editor/IDE
.vscode/
.DS_Store
*.swp
*~

# Archives
*.zip
*.tar.gz

This keeps your repo clean of generated files.

STEP 9: EXTENSIONS MANIFEST (.vscode/extensions.json)
-----------------------------------------------------

Create .vscode/extensions.json:

{
  "recommendations": [
    "prb28.m68k",
    "ms-vscode.cpptools",
    "ms-vscode.makefile-tools",
    "devicechip.serial-monitor",
    "aaron-bond.better-comments"
  ]
}

When someone (or you on another machine) opens the project,
VS Code will suggest these extensions.

STEP 10: README.md
------------------

Create README.md:

# Enhanced BASIC for MVME167

Port of Lee Davison's Enhanced 68k BASIC to Motorola MVME167-02.

## Building

```bash
# Build for RAM testing
make clean all

# Build for ROM
make rom

# View disassembly
make disasm
```

Or use VS Code:
- Press Ctrl+Shift+B for default build (RAM)
- Press Ctrl+Shift+P, search "Tasks: Run Task" for ROM build

## Loading into MVME167

### Via Motorola Monitor (RAM testing)
```
> LOAD
[send enhanced_basic.srec file]
> GO 400000
```

### Via EPROM (final ROM version)
1. Generate ROM S-record: `make rom`
2. Program EPROM chips with enhanced_basic_rom.srec
3. Replace OS9 ROM chips in MVME167
4. Reset board

## Tools Required

- m68k-elf-binutils (as, ld, objcopy, objdump)
- GNU make
- m68k-elf-gdb (optional, for debugging)

## Project Structure

```
src/                    - Assembly source code
include/               - Header files (.h)
build/                 - Generated files (gitignored)
.vscode/              - Editor configuration
Makefile              - Build configuration
```

WORKFLOW IN VS CODE
-------------------

1. Open the project folder: File > Open Folder > [mvme167-basic]

2. Edit source files in VS Code
   - Syntax highlighting for m68k assembly
   - Better Comments colors code blocks
   - Integrated terminal for git

3. Build with Ctrl+Shift+B (uses "Build BASIC (RAM, 400000)" task)
   - Automatic compilation
   - Output appears in Terminal panel
   - Errors click-able (jump to source)

4. Load to MVME167:
   - Use Serial Monitor extension to connect to board
   - Send S-record file over serial
   - Jump to BASIC with monitor command

5. Iterate:
   - Edit code
   - Press Ctrl+Shift+B to rebuild
   - Test on board

KEYBOARD SHORTCUTS (add to .vscode/keybindings.json if desired)
---------------------------------------------------------------

For rapid iteration:
  Ctrl+Shift+B        Build (default)
  Ctrl+` (backtick)   Toggle terminal
  Ctrl+Shift+P        Command Palette (tasks, etc)
  F5                  Debug (if configured)

OPTIONAL: Custom Keybindings

Create .vscode/keybindings.json:

[
  {
    "key": "ctrl+shift+m",
    "command": "workbench.action.tasks.runTask",
    "args": "Build BASIC ROM"
  },
  {
    "key": "ctrl+shift+c",
    "command": "workbench.action.tasks.runTask",
    "args": "Clean"
  }
]

INTEGRATION WITH SERIAL MONITOR
-------------------------------

If you install the Serial Monitor extension (devicechip.serial-monitor):

1. Click Serial Monitor icon in left sidebar
2. Select your MVME167 serial port (usually /dev/ttyUSB0 on Linux)
3. Set baud rate to 9600
4. You now have integrated terminal to your board
5. Can send/receive data without external terminal program

This is very convenient for:
- Sending S-record files
- Typing monitor commands (LOAD, GO, etc)
- Seeing BASIC output

TROUBLESHOOTING
---------------

Q: "m68k-elf-as: command not found"
A: Toolchain not installed or not in PATH
   - Check: which m68k-elf-as
   - Install if needed
   - May need to adjust CROSS variable in Makefile

Q: Build task doesn't appear
A: .vscode/tasks.json might have JSON syntax error
   - Check: Ctrl+Shift+P > "Tasks: Run Task"
   - Look for error in VS Code output
   - Validate JSON (use jsonlint)

Q: Syntax highlighting not working
A: m68k extension not installed
   - Extensions > search "m68k" > install prb28.m68k
   - Reload VS Code (Ctrl+R)

Q: Makefile not recognized
A: Save as "Makefile" not "Makefile.txt"
   - Check file extension in Explorer
   - Rename if needed

Q: Terminal commands not working
A: Terminal not in project directory
   - Click in terminal
   - Type: cd [your project path]
   - Or restart VS Code

NEXT STEPS
----------

1. Install VS Code extensions (m68k, Serial Monitor, etc)
2. Create project structure as shown above
3. Copy your Makefile and .vscode configs
4. Add your assembly source files
5. Press Ctrl+Shift+B to test build
6. Use Serial Monitor to connect to MVME167
7. Load and test!

This setup gives you a professional development environment
for embedded 68k work. You'll have:
- Integrated build (no command line)
- Syntax highlighting
- Serial port access
- Git version control
- Clean project organization

Good luck with the BASIC port!

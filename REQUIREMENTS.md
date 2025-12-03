# Build Requirements

## Required Tools

### Assembler
- **vasm** (Motorola 68k syntax variant)
  - Binary: `vasmm68k_mot`
  - Version: 1.8 or later recommended
  - Download: http://sun.hasenbraten.de/vasm/
  - Build flags used: `-m68040 -Fsrec`

### Standard Unix Tools
- `make` - GNU Make or compatible
- `rm` - File removal
- `mkdir` - Directory creation

## Installation Instructions

### Debian/Ubuntu
```bash
# Install build essentials
sudo apt-get update
sudo apt-get install build-essential

# Download and build vasm
wget http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
tar -xzf vasm.tar.gz
cd vasm
make CPU=m68k SYNTAX=mot
sudo cp vasmm68k_mot /usr/local/bin/
sudo chmod +x /usr/local/bin/vasmm68k_mot
```

### macOS
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Download and build vasm
curl -O http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
tar -xzf vasm.tar.gz
cd vasm
make CPU=m68k SYNTAX=mot
sudo cp vasmm68k_mot /usr/local/bin/
sudo chmod +x /usr/local/bin/vasmm68k_mot
```

### Verify Installation
```bash
# Check vasm version
vasmm68k_mot -v

# Expected output similar to:
# vasm 1.9c (c) in 2002-2023 Volker Barthelmann
# vasm M68k/CPU32/ColdFire cpu backend 2.5c (c) 2002-2023 Frank Wille
# vasm motorola syntax module 3.17c (c) 2002-2023 Frank Wille
# vasm Motorola S-Record output module 1.5b (c) 2002,2008,2010,2012 Frank Wille
```

## Build Process

Once dependencies are installed:

```bash
make              # Build S-record file
make clean        # Remove build artifacts
```

Output will be in `build/enhanced_basic_ram.srec`

## Target Hardware Requirements

- Motorola MVME167-02 single-board computer (or compatible)
- 68040 CPU (68030/68020 may work with minor modifications)
- 167-Bug ROM monitor firmware
- Serial terminal connection (9600 baud or higher)

## Optional Tools

- Serial terminal emulator (minicom, screen, PuTTY, etc.)
- Text editor for BASIC programs
- Git for version control

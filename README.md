# Enhanced 68k BASIC for MVME167

A port of Enhanced 68k BASIC (originally for EASy68k simulator) to the Motorola MVME167-02 single-board computer with 167-Bug ROM monitor.

## Overview

This is a working implementation of Lee Davison's Enhanced 6800 BASIC interpreter, adapted to run on real 68040 hardware. The interpreter runs entirely in RAM and uses the 167-Bug TRAP #15 interface for I/O.

## Hardware Requirements

- Motorola MVME167-02 (or compatible) single-board computer
- 68040 CPU (or 68030/68020 with modifications)
- 167-Bug ROM monitor firmware
- Serial terminal connection

## Memory Map

- **Code Load Address:** `0x00401000`
- **Program Storage:** `0x00500000` - `0x01FFFFFF` (32MB BASIC program space)
- **Stack:** `0x00500000` (grows downward from program start)

## Build Instructions

### Prerequisites

- `vasmm68k_mot` assembler (vasm for Motorola syntax)
- Standard Unix tools (make, rm, mkdir)

### Building

```bash
make              # Build S-record file
make clean        # Remove build artifacts
```

Output: `build/enhanced_basic_ram.srec`

## Loading and Running

1. Connect to MVME167 via serial terminal
2. Enter 167-Bug monitor
3. Load the S-record:
   ```
   167-Bug> lo 0
   [Paste contents of build/enhanced_basic_ram.srec]
   ```
4. Start BASIC:
   ```
   167-Bug> go 401000
   ```

## Features

### Working Features

- ✅ Interactive command line with prompt
- ✅ Line entry and editing
- ✅ `LIST` - Display program
- ✅ `RUN` - Execute program
- ✅ `NEW` - Clear program
- ✅ `PRINT` - Output text and variables
- ✅ `FOR`/`NEXT` loops (including nested loops)
- ✅ `IF`/`THEN` conditionals
- ✅ `GOTO` and `GOSUB`/`RETURN`
- ✅ `DIM` - Array declarations
- ✅ Array operations (single and multi-dimensional)
- ✅ Arithmetic operations (+, -, *, /)
- ✅ Comparison operators (=, <, >, <=, >=, <>)
- ✅ Variable assignments
- ✅ Ctrl-C to exit to 167-Bug

### Known Limitations

- ⚠️ `TI` (timer) function returns 0 (not yet implemented)
- ⚠️ `INPUT` statement untested
- ⚠️ String operations untested
- ⚠️ File I/O not implemented (simulator-only feature)
- ⚠️ Graphics commands not implemented

## Example Programs

### Hello World
```basic
10 PRINT "HELLO WORLD"
RUN
```

### Simple Loop
```basic
10 FOR I = 1 TO 10
20   PRINT "COUNT: "; I
30 NEXT I
RUN
```

### Sieve of Eratosthenes
See [Sieve.BAS](Sieve.BAS) for a complete benchmark program.

## Technical Details

### TRAP #15 I/O Functions

The interpreter uses 167-Bug's TRAP #15 interface:

- **$0020** `.OUTCHR` - Output character (stack-based)
- **$0000** `.INCHR` - Input character (stack-based)
- **$0001** `.INSTAT` - Check input status
- **$0063** `.RETURN` - Exit to 167-Bug

### Memory Layout

BASIC program lines are stored as:
```
[4-byte next pointer][2-byte line number][tokens...][0x00 terminator]
```

### Big-Endian Architecture

The 68040 is big-endian (MSB first). All multi-byte values are stored with the most significant byte at the lowest address.

### Performance Optimizations

- **Ctrl-C Throttling:** VEC_CC only checks for input every 64 BASIC statements to avoid TRAP storm
- **Memory Alignment:** Program storage forced to even addresses for 68040 compatibility

## Major Fixes and Modifications

### Porting Changes from EASy68k

1. **Line Numbers:** Changed from 32-bit to 16-bit storage
2. **I/O System:** Replaced EASy68k TRAP #15 with 167-Bug TRAP #15
3. **Memory Alignment:** Added EVEN directives and runtime checks for 68040
4. **GOTO Execution:** Fixed execution flow to preserve FOR/NEXT stack
5. **Big-Endian Support:** Corrected byte ordering for line number storage/retrieval
6. **Performance:** Throttled Ctrl-C checking to prevent ROM monitor overload

### Critical Bug Fixes

- Fixed line number storage using wrong word in big-endian longword
- Fixed GOTO skipping incorrect number of bytes (was 2, needed 6)
- Fixed GOTO stack corruption when called from IF statement
- Fixed VEC_CC TRAP storm causing system crashes
- Fixed memory alignment issues causing odd-address faults

## BASIC Language Notes

From Lee Davison's original documentation:

- Keywords must be in **ALL UPPERCASE**
- Variable names can be mixed case (first 3 letters determine uniqueness)
- `RND(0)` generates random numbers (not `RND(1)` like Microsoft BASIC)
- Arrays must be explicitly dimensioned with `DIM`
- Empty `INPUT` responses cause program break (by default)
- `PRINT` does not add spaces between items
- Undefined variables generate errors (by default)

## Credits

- **Original BASIC:** Lee Davison's Enhanced 6800 BASIC
- **EASy68k Port:** Original EASy68k simulator version
- **MVME167 Port:** John (2024)
- **AI Assistant:** Claude (Anthropic) - debugging and optimization

## License

EhBASIC is copyright Lee Davison 2002-2012 and free for educational or personal use only. For commercial use please contact the original author.

## Contributing

Contributions welcome! Areas needing work:

- Implement proper TI timer function using 167-Bug `.TIME`
- Test and fix INPUT statement
- Test string operations
- Optimize floating-point math routines
- Add graphics support (Tektronix 4010, Sixel, or ASCII art)

## Development Status

**Current Status:** Working for integer arithmetic, loops, arrays, and control flow

**Last Updated:** December 2024

## References

1. [EhBASIC Manual](http://www.sunrise-ev.com/photos/6502/EhBASIC-manual.pdf)
2. [Lee Davison's Website](http://retro.hansotten.nl/home/lee-davison-web-site/)
3. [EASy68k](http://www.easy68k.com/applications.htm)
4. [VASM Assembler](http://sun.hasenbraten.de/vasm/)

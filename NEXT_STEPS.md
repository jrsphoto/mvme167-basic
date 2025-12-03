# MVME167 Enhanced BASIC - Next Steps

## Current Status

✅ **Successfully Running!** The BASIC interpreter now executes programs on MVME167 hardware.

### Working Features
- ✅ Program entry and storage with correct line number handling
- ✅ LIST command displays programs correctly
- ✅ RUN command executes programs
- ✅ Line number display in error messages
- ✅ GOTO/GOSUB navigation
- ✅ FOR/NEXT loops
- ✅ PRINT statements
- ✅ Multi-line programs
- ✅ String literals in PRINT
- ✅ Basic arithmetic and expressions

## Known Issues Fixed

All critical alignment and line number bugs have been resolved:
- Big-endian word storage (Itemp+2)
- Line number read operations (word vs longword)
- Memory allocation sizing (6 bytes instead of 8)
- Address alignment (EVEN directive and runtime checks)
- GOTO/GOSUB pointer arithmetic
- **GOTO execution flow** - Fixed to jump directly to LAB_15F6 instead of returning to loop checker, preventing syntax errors when GOTO is the last statement on a line

## Potential Areas Requiring Testing/Fixes

### High Priority

#### 1. String Operations
- **String variables** - Assignment and retrieval
- **String concatenation** - Combining strings with `+`
- **String functions** - LEFT$, RIGHT$, MID$, LEN, etc.
- **String comparisons** - Equality and ordering

**Test Program:**
```basic
10 A$ = "HELLO"
20 B$ = "WORLD"
30 C$ = A$ + " " + B$
40 PRINT C$
50 PRINT LEFT$(C$, 5)
60 IF A$ = "HELLO" THEN PRINT "MATCH"
```

#### 2. INPUT Statement
- **Numeric input** - Reading integers and floats
- **String input** - Reading text with quotes
- **Prompt display** - "? " prompt behavior
- **Multiple inputs** - INPUT A, B, C

**Test Program:**
```basic
10 INPUT "Enter your name"; N$
20 INPUT "Enter your age"; A
30 PRINT N$; " is "; A; " years old"
```

#### 3. Arrays
- **DIM statement** - Array declaration
- **Array indexing** - Reading/writing elements
- **Bounds checking** - Subscript out of range errors
- **Multi-dimensional arrays** - DIM A(10,10)

**Test Program:**
```basic
10 DIM A(100)
20 FOR I = 1 TO 100
30 A(I) = I * I
40 NEXT I
50 PRINT A(50)
```

### Medium Priority

#### 4. Floating-Point Math
- **Basic operations** - +, -, *, /
- **Exponentiation** - ^
- **Math functions** - SIN, COS, TAN, ATN, LOG, EXP, SQR
- **Rounding** - INT, ABS, SGN

**Test Program:**
```basic
10 PI = 3.14159265
20 PRINT SIN(PI/2)
30 PRINT SQR(144)
40 PRINT 2^8
```

#### 5. READ/DATA Statements
- **DATA storage** - Multiple DATA lines
- **READ sequencing** - Reading in order
- **RESTORE** - Resetting data pointer
- **Type mismatches** - Reading string as number

**Test Program:**
```basic
10 READ A, B$, C
20 PRINT A, B$, C
30 DATA 42, "TEST", 3.14
```

#### 6. Control Structures
- **WHILE/WEND** - While loops (if implemented)
- **DO/LOOP** - Do loops with UNTIL/WHILE
- **IF/THEN/ELSE** - Conditional branching
- **ON GOTO/GOSUB** - Computed branches

**Test Program:**
```basic
10 X = 1
20 WHILE X < 10
30 PRINT X
40 X = X + 1
50 WEND
```

### Low Priority / Enhancement

#### 7. ANSI Graphics & Terminal Features

**Current State:** Graphics commands (LINE, CIRCLE, FILL, etc.) are stubbed out for EASy68k compatibility.

**Enhancement Options:**

##### Option A: Tektronix 4010 Graphics
Map vector graphics to Tektronix 4010 escape sequences. Many terminal emulators support this.

**Commands to implement:**
- `LINE(x1,y1)-(x2,y2)` → Draw line using Tek4010 sequences
- `CIRCLE(x,y,r)` → Approximate with line segments
- `POINT(x,y)` → Single pixel

**Advantages:**
- Widely supported (xterm, iTerm2, others)
- True vector graphics
- Simple protocol

**Example escape sequence:**
```
ESC FF           # Clear screen and enter graphics mode
<encode x,y>     # Move to position
<encode x,y>     # Draw to position
ESC ETX          # Exit graphics mode
```

##### Option B: Sixel Graphics
Modern approach using Sixel protocol (VT340 compatible).

**Advantages:**
- Raster graphics with color support
- Good modern terminal support (mintty, iTerm2, mlterm)
- Can render arbitrary shapes

**Disadvantages:**
- More complex encoding
- Requires framebuffer management
- Higher memory usage

##### Option C: ASCII/ANSI Art
Fallback using box-drawing characters.

**Commands:**
- `LINE` → Use ─│┌┐└┘├┤┬┴┼ characters
- `CIRCLE` → Approximate with ○ or block characters
- `PLOT` → Use █ or ░▒▓ for shading

**Advantages:**
- Universal compatibility
- No special terminal required
- Low overhead

**Disadvantages:**
- Low resolution
- Limited visual quality

**Recommended Approach:**
1. Start with Option C (ASCII art) for basic functionality
2. Add Tektronix 4010 support as optional enhanced mode
3. Detect terminal capabilities at startup

**Implementation Plan:**
```basic
' User detection or configuration
GRAPHICS 0   ' ASCII mode (default)
GRAPHICS 1   ' Tektronix 4010 mode
GRAPHICS 2   ' Sixel mode (future)
```

**Files to modify:**
- Search for TK_LINE, TK_CIRCLE, TK_PLOT handlers
- Currently branch to LAB_FCER (function call error)
- Implement actual drawing routines

#### 8. Advanced Features

##### Error Handling
- **ON ERROR GOTO** - Error trapping
- **RESUME** - Continue after error
- **ERR and ERL** - Error number and line

##### Subroutines & Functions
- **GOSUB/RETURN** - Subroutine calls (likely working)
- **DEF FN** - User-defined functions
- **Parameter passing** - Function arguments

##### File I/O (if 167-Bug supports it)
- **OPEN** - Open file
- **PRINT#** - Write to file
- **INPUT#** - Read from file
- **CLOSE** - Close file

Currently uses vectors V_LOAD and V_SAVE which point to VEC_LD and VEC_SV. These would need implementation for 167-Bug file system (if available).

## Testing Strategy

### 1. Systematic Feature Testing
Create a test suite with numbered programs:

```
TEST001.BAS - String variables
TEST002.BAS - String concatenation
TEST003.BAS - INPUT numeric
TEST004.BAS - INPUT string
TEST005.BAS - Arrays basic
TEST006.BAS - Arrays multidimensional
TEST007.BAS - Math functions
TEST008.BAS - READ/DATA
... etc
```

### 2. Regression Testing
After each fix, re-run working programs to ensure nothing broke:
```basic
' REGRESS.BAS - Quick regression test
10 PRINT "Testing FOR/NEXT..."
20 FOR I = 1 TO 10: NEXT I
30 PRINT "OK"
40 PRINT "Testing GOTO..."
50 GOTO 70
60 PRINT "FAIL"
70 PRINT "OK"
80 END
```

### 3. Stress Testing
```basic
' STRESS.BAS - Test limits
10 DIM A(1000)
20 FOR I = 1 TO 1000
30 FOR J = 1 TO 10
40 A(I) = I * J
50 NEXT J
60 NEXT I
70 PRINT "Complete"
```

## Performance Optimization (Future)

- Profile execution with 167-Bug timing functions
- Optimize inner loops
- Consider assembly implementations of math functions
- Memory allocation efficiency

## Documentation Needed

1. **User Manual** - BASIC command reference for MVME167
2. **Technical Manual** - Porting guide and architecture
3. **Examples** - Sample programs demonstrating features
4. **Limitations** - Known differences from EASy68k version

## Hardware Integration Ideas

### Serial I/O
- Direct access to MVME167 serial ports
- PEEK/POKE for hardware registers
- Interrupt handling (advanced)

### Real-Time Clock
- Access to 167-Bug time functions
- DATE$ and TIME$ variables

### Memory Management
- PEEK/POKE for direct memory access
- FRE() function for available memory
- Memory-mapped I/O access

## Build System Enhancements

- Add version numbering to builds
- Create debug vs release builds (with/without assertions)
- Automated testing framework
- CI/CD pipeline (if applicable)

## Community & Distribution

- Create GitHub repository (if desired)
- Share on vintage computing forums
- Document the porting process
- Create demo videos
- Write blog posts about the debugging journey

## Long-Term Vision

- Port to other 68k platforms (MVME162, Sun-3, Amiga?)
- Create IDE/editor for program development
- Add debugger features (TRACE, BREAK commands)
- Implement BASIC compiler for performance

---

## Quick Reference - Files Modified

All changes in: `src/enhanced_basic.s`

**Key modifications:**
- Line 945: Store line number (Itemp+2)
- Line 929: Memory allocation (ADDQ.w #6)
- Lines 898-901: Address alignment check
- Lines 1301-1302: LIST read line number
- Lines 1420-1423: Execution read line number
- Lines 2709-2712: DATA read line number
- Line 1192: Line search comparison
- Lines 2046-2054: GOTO skip line number and execution flow fix
- Lines 1956-1957: RUN initialization
- Lines 1216-1222: NEW alignment check
- Line 8672: prg_strt EVEN directive

**Build command:** `make`

**Load command:**
```
167-Bug> lo 0
[paste build/enhanced_basic_ram.srec]
167-Bug> go 401000
```

---

*Last Updated: December 2, 2024*
*Status: Core functionality working, testing phase*

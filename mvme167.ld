/* Linker script for MVME167 BASIC
 * Maps vasm sections to correct memory addresses
 */

OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(START_ENTRY)

SECTIONS
{
    /* Code section at 0x401000 */
    . = 0x00401000;
    .text : {
        *(seg401000)
    }

    /* Data/BSS section at 0x500000 */
    . = 0x00500000;
    .data : {
        *(seg500000)
    }
    .bss : {
        *(seg500000)
    }
}

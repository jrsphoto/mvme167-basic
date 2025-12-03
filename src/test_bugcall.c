/*
 * Test calling 167-Bug I/O routines directly
 *
 * Compile: m68k-elf-gcc -m68040 -nostdlib -Wl,-Ttext=0x400400 -o build/test_bugcall.elf src/test_bugcall.c
 * Convert: m68k-elf-objcopy -O srec build/test_bugcall.elf build/test_bugcall.srec
 */

#define BUG_OUTCHR ((void (*)(char))0xFFE00AD0)

void _start(void)
{
    /* Set up stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Try calling 167-Bug output routine */
    /* Character should be in D0 based on standard 68k calling conventions */

    __asm__ volatile (
        "moveq  #65,%%d0\n"      /* 'A' */
        "jsr    0xFFE00AD0\n"     /* Call 167-Bug OUTCHR */
        "moveq  #13,%%d0\n"       /* CR */
        "jsr    0xFFE00AD0\n"
        "moveq  #10,%%d0\n"       /* LF */
        "jsr    0xFFE00AD0\n"
        : : : "d0", "d1", "a0", "a1"
    );

    /* Hang */
    while(1) {
        __asm__ volatile ("nop");
    }
}

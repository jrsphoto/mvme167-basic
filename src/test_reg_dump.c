/*
 * CD2401 Register Dump for MVME167
 * Dumps key registers to see how 167-Bug has configured the CD2401
 *
 * Compile: m68k-elf-gcc -m68040 -nostdlib -Wl,-Ttext=0x400400 -o build/test_reg_dump.elf src/test_reg_dump.c
 * Convert: m68k-elf-objcopy -O srec build/test_reg_dump.elf build/test_reg_dump.srec
 */

#define CD2401_BASE 0xFFF45000
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

/* Register offsets */
#define CyGFRCR 0x81
#define CyCAR   0xEE
#define CyCCR   0x13
#define CyIER   0x11
#define CyCMR   0x1B
#define CyTISR  0x8A
#define CyCOR1  0x08
#define CyCOR2  0x09
#define CyCOR3  0x0A

/* Memory location to write results */
#define RESULT_BASE 0x405000

void _start(void)
{
    volatile unsigned char *result = (volatile unsigned char *)RESULT_BASE;
    int i = 0;

    /* Set up stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Write marker */
    result[i++] = 0xDE;
    result[i++] = 0xAD;
    result[i++] = 0xBE;
    result[i++] = 0xEF;

    /* Read GFRCR (firmware version) */
    result[i++] = CD2401_REG(CyGFRCR);

    /* Save current CAR */
    result[i++] = CD2401_REG(CyCAR);

    /* For each channel, dump key registers */
    int chan;
    for (chan = 0; chan < 4; chan++) {
        /* Select channel */
        CD2401_REG(CyCAR) = chan;

        /* Channel marker */
        result[i++] = 0xCC;
        result[i++] = '0' + chan;

        /* Read key registers */
        result[i++] = CD2401_REG(CyCCR);   /* Channel Command Register */
        result[i++] = CD2401_REG(CyIER);   /* Interrupt Enable Register */
        result[i++] = CD2401_REG(CyCMR);   /* Channel Mode Register */
        result[i++] = CD2401_REG(CyTISR);  /* Transmit Interrupt Status */
        result[i++] = CD2401_REG(CyCOR1);  /* Channel Option Register 1 */
        result[i++] = CD2401_REG(CyCOR2);  /* Channel Option Register 2 */
        result[i++] = CD2401_REG(CyCOR3);  /* Channel Option Register 3 */
    }

    /* End marker */
    result[i++] = 0xCA;
    result[i++] = 0xFE;
    result[i++] = 0xBA;
    result[i++] = 0xBE;

    /* Hang */
    while(1) {
        __asm__ volatile ("nop");
    }
}

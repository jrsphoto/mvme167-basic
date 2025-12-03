/*
 * CD2401 Serial Output Test Program for MVME167
 * Tests various output methods to find what works
 *
 * Compile with: m68k-elf-gcc -m68040 -nostdlib -Wl,-Ttext=0x400400 -o build/test_serial.elf src/test_serial.c
 * Convert: m68k-elf-objcopy -O srec build/test_serial.elf build/test_serial.srec
 */

/* CD2401 Register definitions - with byte-swapping correction */
#define CD2401_BASE     0xFFF45000

/*
 * Use register offsets directly from Linux serial167 driver
 * Testing shows these work correctly on MVME167
 */
#define CyGFRCR     0x81    /* Global Firmware Revision Code Register */
#define CyCCR       0x13    /* Channel Command Register */
#define CyCAR       0xEE    /* Channel Access Register */
#define CyIER       0x11    /* Interrupt Enable Register */
#define CyTISR      0x8A    /* Transmit Interrupt Status Register */
#define CyTDR       0xF8    /* Transmit Data Register */
#define CyRDR       0xF8    /* Receive Data Register */
#define CySCHR4     0x1C    /* Special Character Register 4 */
#define CySTCR      0x0C    /* Special Transmit Command Register */
#define CyRFOC      0x30    /* Receive FIFO Output Count */

/* Register access macros */
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

/* Function prototypes */
void putchar_schr4(char c);
void putchar_tdr(char c);
void print_string(const char *s);
void delay(int count);

/* Test message */
const char msg_hello[] = "Hello World from CD2401!\r\n";

/* Entry point - called from 167-Bug */
void _start(void)
{
    /* Set up stack pointer */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Test all 4 channels using TDR instead of SCHR4 */
    int chan;
    for (chan = 0; chan < 4; chan++) {
        /* Select channel */
        CD2401_REG(CyCAR) = chan;

        /* Send channel number as character using TDR */
        putchar_tdr('0' + chan);
        putchar_tdr(' ');
    }

    /* Hang in infinite loop */
    while(1) {
        __asm__ volatile ("nop");
    }
}

/* Print null-terminated string */
void print_string(const char *s)
{
    while (*s) {
        putchar_schr4(*s);
        s++;
    }
}

/* Output character using Special Character Register 4 method */
void putchar_schr4(char c)
{
    /* Don't change channel - caller sets it */

    /* Write character to Special Character Register 4 */
    CD2401_REG(CySCHR4) = c;

    /* Send Special Character 4 command (0x98) */
    CD2401_REG(CySTCR) = 0x98;

    /* Wait for command to complete (STCR clears to 0) */
    while (CD2401_REG(CySTCR) != 0) {
        /* Wait */
    }
}

/* Output character using TDR directly */
void putchar_tdr(char c)
{
    /* Don't change channel - caller sets it */

    /* Write directly to TDR */
    CD2401_REG(CyTDR) = c;

    /* Small delay */
    delay(0x1000);
}

/* Simple delay loop */
void delay(int count)
{
    volatile int i;
    for (i = 0; i < count; i++) {
        /* Wait */
    }
}

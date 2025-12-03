/*
 * Test SCHR4/STCR without touching CAR
 * Don't change channel - use whatever 167-Bug has selected
 */

#define CD2401_BASE 0xFFF45000
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

#define CySCHR4 0x1C
#define CySTCR  0x0C

void _start(void)
{
    /* Set stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Send "Hello" without touching CAR */
    const char *msg = "Hello World!\r\n";
    while (*msg) {
        /* Write to SCHR4 */
        CD2401_REG(CySCHR4) = *msg;

        /* Send command */
        CD2401_REG(CySTCR) = 0x98;

        /* Wait for completion */
        while (CD2401_REG(CySTCR) != 0);

        msg++;
    }

    /* Hang */
    while(1) {
        __asm__ volatile ("nop");
    }
}

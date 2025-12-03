/*
 * Test enabling transmitter before output
 * Based on CD2401 manual - transmitter must be enabled
 */

#define CD2401_BASE 0xFFF45000
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

#define CyCAR   0xEE
#define CyCCR   0x13
#define CySCHR4 0x1C
#define CySTCR  0x0C

/* CCR Commands */
#define CyENB_XMTR  0x08    /* Enable transmitter */

void _start(void)
{
    /* Set stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Select channel 0 */
    CD2401_REG(CyCAR) = 0;

    /* Enable transmitter - this might be the missing piece! */
    CD2401_REG(CyCCR) = CyENB_XMTR;

    /* Wait for CCR command to complete */
    while (CD2401_REG(CyCCR) != 0);

    /* Now try sending via SCHR4/STCR */
    const char *msg = "Hello World!\r\n";
    while (*msg) {
        CD2401_REG(CySCHR4) = *msg;
        CD2401_REG(CySTCR) = 0x98;
        while (CD2401_REG(CySTCR) != 0);
        msg++;
    }

    /* Hang */
    while(1) {
        __asm__ volatile ("nop");
    }
}

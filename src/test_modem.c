/*
 * Test with modem signals (RTS/DTR) asserted
 * Maybe flow control is blocking transmission?
 */

#define CD2401_BASE 0xFFF45000
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

#define CyCAR   0xEE
#define CyCCR   0x13
#define CyMSVR1 0xDE    /* Modem Signal Value Register 1 */
#define CyMSVR2 0xDF    /* Modem Signal Value Register 2 */
#define CySCHR4 0x1C
#define CySTCR  0x0C

/* Modem signal bits */
#define CyRTS   0x02
#define CyDTR   0x04

/* CCR Commands */
#define CyENB_XMTR  0x08

void _start(void)
{
    /* Set stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Select channel 0 */
    CD2401_REG(CyCAR) = 0;

    /* Assert RTS and DTR - maybe this is needed for flow control! */
    CD2401_REG(CyMSVR1) = CyRTS;
    CD2401_REG(CyMSVR2) = CyDTR;

    /* Enable transmitter */
    CD2401_REG(CyCCR) = CyENB_XMTR;
    while (CD2401_REG(CyCCR) != 0);

    /* Send test message */
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

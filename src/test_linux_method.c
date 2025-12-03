/*
 * CD2401 Serial Output using Linux kernel method
 * Based on arch/m68k/mvme16x/config.c mvme16x_cons_write()
 */

/* PCC2 Registers */
#define PCC2CHIP    0xFFF42000
#define PCCSCCTICR  (PCC2CHIP + 0x1E)  /* SCC Transmit Interrupt Control */
#define PCCTPIACKR  (PCC2CHIP + 0x25)  /* Transmit Pseudo IACK Register */

/* CD2401 Registers */
#define CD2401_BASE 0xFFF45000
#define CD2401_REG(offset) (*(volatile unsigned char *)(CD2401_BASE + (offset)))

#define CyCAR   0xEE
#define CyCCR   0x13
#define CyIER   0x11
#define CyLICR  0x26
#define CyTDR   0xF8
#define CyTEOIR 0x85

/* Commands and bits */
#define CyENB_XMTR  0x08
#define CyTxMpty    0x02
#define CyNOTRANS   0x08

#define in_8(addr) (*(volatile unsigned char *)(addr))

void putchar_linux(char c)
{
    int port = 0;
    unsigned char saved_ier;

    /* Select channel 0 */
    CD2401_REG(CyCAR) = port;

    /* Wait for CCR to clear */
    while (CD2401_REG(CyCCR));

    /* Enable transmitter */
    CD2401_REG(CyCCR) = CyENB_XMTR;

    /* Save and set interrupt enable for TxEmpty */
    saved_ier = CD2401_REG(CyIER);
    CD2401_REG(CyIER) = CyTxMpty;

    /* Wait for transmit interrupt */
    while (1) {
        if (in_8(PCCSCCTICR) & 0x20) {  /* Check interrupt bit */
            /* Read PIACK register - triggers interrupt ack to CD2401 */
            in_8(PCCTPIACKR);

            /* Verify it's our channel */
            if ((CD2401_REG(CyLICR) >> 2) == port) {
                /* Write character */
                CD2401_REG(CyTDR) = c;

                /* Signal end of interrupt */
                CD2401_REG(CyTEOIR) = 0;
                break;
            } else {
                /* Not our channel */
                CD2401_REG(CyTEOIR) = CyNOTRANS;
            }
        }
    }

    /* Restore interrupt enable register */
    CD2401_REG(CyIER) = saved_ier;
}

void _start(void)
{
    /* Set stack */
    __asm__ volatile ("move.l #0x420000,%%sp" : : : "sp");

    /* Send test message using Linux method */
    const char *msg = "Hello from Linux method!\r\n";
    while (*msg) {
        putchar_linux(*msg++);
    }

    /* Hang */
    while(1) {
        __asm__ volatile ("nop");
    }
}

/*
 * CD2401 Register Definitions for MVME167
 * Based on Linux serial167.h and serial167.c
 * 
 * This is a simplified header for minimal serial I/O operations
 * suitable for a BASIC interpreter ROM
 */

#ifndef __CD2401_H__
#define __CD2401_H__

/* Base address of CD2401 chip on MVME167 */
#define CD2401_BASE     0xFFF45000

/* CD2401 Register Offsets (as byte indices from base) */
#define CyGFRCR         0x81    /* Global Flags & Reset */
#define CyCCR           0x13    /* Channel Control Register */
#define CyCLR_CHAN      0x40    /* Clear channel */
#define CyINIT_CHAN     0x20    /* Initialize channel */
#define CyCHIP_RESET    0x10    /* Chip reset */
#define CyENB_XMTR      0x08    /* Enable transmitter */
#define CyDIS_XMTR      0x04    /* Disable transmitter */
#define CyENB_RCVR      0x02    /* Enable receiver */
#define CyDIS_RCVR      0x01    /* Disable receiver */

#define CyCAR           0xEE    /* Channel Address Register */
#define CyIER           0x11    /* Interrupt Enable Register */
#define CyMdmCh         0x80
#define CyRxExc         0x20
#define CyRxData        0x08
#define CyTxMpty        0x02
#define CyTxRdy         0x01

#define CyLICR          0x26    /* Local Interrupt Channel Register */
#define CyRISR          0x89    /* Receiver Interrupt Status Register */
#define CyTIMEOUT       0x80
#define CySPECHAR       0x70
#define CyOVERRUN       0x08
#define CyPARITY        0x04
#define CyFRAME         0x02
#define CyBREAK         0x01

#define CyREOIR         0x84    /* Receiver End Of Interrupt */
#define CyTEOIR         0x85    /* Transmitter End Of Interrupt */
#define CyMEOIR         0x86    /* Modem End Of Interrupt */
#define CyNOTRANS       0x08

#define CyRFOC          0x30    /* Receive FIFO Output Count */
#define CyRDR           0xF8    /* Receive Data Register */
#define CyTDR           0xF8    /* Transmit Data Register */

#define CyMISR          0x8B    /* Modem Interrupt Status Register */
#define CyTISR          0x8A    /* Transmitter Interrupt Status Register */

#define CyMSVR1         0xDE    /* Modem Signal Value Register 1 */
#define CyMSVR2         0xDF    /* Modem Signal Value Register 2 */
#define CyRTS           0x02    /* Request To Send */
#define CyDTR           0x04    /* Data Terminal Ready */

#define CyCMR           0x02    /* Channel Mode Register */
#define CyASYNC         0x02    /* Asynchronous mode */

#define CyTCOR          0x26    /* Transmit Clock Option Register */
#define CyTBPR          0x28    /* Transmit Baud Rate Period Register */
#define CyRCOR          0x27    /* Receive Clock Option Register */
#define CyRBPR          0x29    /* Receive Baud Rate Period Register */

#define CySCHR1         0x1F    /* Special Character Register 1 */
#define CySCHR2         0x20    /* Special Character Register 2 */
#define CySCRL          0x21    /* Special Character Range Low */
#define CySCRH          0x22    /* Special Character Range High */
#define CyCOR1          0x08    /* Channel Option Register 1 */
#define Cy_8_BITS       0x03
#define CyPARITY_NONE   0x00
#define CyCOR2          0x09    /* Channel Option Register 2 */
#define CyCOR3          0x0A    /* Channel Option Register 3 */
#define Cy_1_STOP       0x02
#define CyCOR4          0x0B    /* Channel Option Register 4 */
#define CyCOR5          0x0C    /* Channel Option Register 5 */
#define CyCOR6          0x0D    /* Channel Option Register 6 */
#define CyCOR7          0x0E    /* Channel Option Register 7 */

#define CyRTPRL         0x18    /* Request To Send Time-out Period Register Low */
#define CyRTPRH         0x19    /* Request To Send Time-out Period Register High */

#endif
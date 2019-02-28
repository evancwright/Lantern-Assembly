/*  defs.h

    By Pierre Sarrazin <http://sarrazip.com/>
    This file is in the public domain.
*/


enum
{
    STACK_SPACE = 1 * 1024,  // must be divisible by 512, because PMODE 4
                             // screen address depends on this
    GRAPHICS_SPACE = 0,  // PMODE 4 buffer size


    RAM_END = 0xFE00,
    STACK_BOTTOM = RAM_END,
    STACK_TOP = STACK_BOTTOM - STACK_SPACE,
    GRAPHICS_START = STACK_TOP - GRAPHICS_SPACE,

    PMODE4_IMAGE_SIZE = 4 * 1536,  // size in bytes of one PMODE 4 screen

//    APP_START = 0x0C00,  // address where the application is loaded
//	APP_START = 0x4400,
	APP_START = 0x0C00,

    NUM_DISK_DRIVES = 1,  // only drives 0..NUM_DISK_DRIVES-1 are accessed

    IRQ_VECTOR = 0xFFF8,
    NMI_VECTOR = 0xFFFC,
};


#define disableInterrupts() asm("ORCC",  "#$50")
#define enableInterrupts()  asm("ANDCC", "#$AF")


typedef interrupt void (*ISR)(void);

// vector: e.g., 0xFFF8 for IRQ.
//
void setISR(void *vector, ISR newRoutine)
{
    byte *isr = * (byte **) vector;
    *isr = 0x7E;  // JMP extended
    * (ISR *) (isr + 1) = newRoutine;
}

.section .text
.globl _start
.align  2

_start:

// GPIO Control Registers Memory Mapping

.equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
.equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
.equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
.equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

.equ GPIO_7SEGLED_PINS, 0x0000023F      // Seven Segment LED Display Pins (7)
.equ GPIO_LEDBAR_PINS,  0x00FC0C00      // LED Bar Pins (8)
.equ GPIO_ALL_LED_PINS, 0x00FC0E3F      // All LED Pins (15)
.equ GPIO_LEDBAR_LED_1, 0x00000800      // LEDBAR LED1 (Bit 11)
// -------------------------------------------------------------------------------------
// Initialize the GPIO control registers and run the delay loop code
// -------------------------------------------------------------------------------------


    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
  
    li t5, GPIO_LEDBAR_LED_1     // Load LED_1 Address into t5 (Bit 11)
    lw t3, GPIO_OUTPUT_VAL(t0)   // Read GPIO output values into t3
    xor t3, t5, t3               // XOR the GPIO output value (all zeroes to the LEDs)
    sw t3, GPIO_OUTPUT_VAL(t0)   // Store this new value in GPIO output register

loop:
    li t4, 0x003d0900  

    xor t3, t5, t3              // Toggle LED
    sw t3, GPIO_OUTPUT_VAL(t0)  // Write updated value
    
loop1:

    addi t4, t4, -1  // Decrement
    bnez t4, loop1   // Branch after 8000000 operations

    j loop           // Jump back to loop and start over


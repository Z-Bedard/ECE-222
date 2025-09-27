.section .text
.align 2
.globl _start

// -------------------------------------------------------------------------------------
// Name:        Lab_2.S
// Purpose:     This code will convert a string of ASCII chracters into Morse code
//              and flash a single LED (Led Bar LED_7) in Morse code with a time base
//		        of approximately 500ms.
// Author:      Zachary Bedard and Jonathan Lyashko
// -------------------------------------------------------------------------------------

_start:

// -------------------------------------------------------------------------------------
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
    .equ GPIO_LEDBAR_LED_1, 0x00000800      // LEDBAR LED1
    .equ GPIO_LED7, 0x00800000               // LEDBAR LED7 (bit 23)
    .equ ON_FILTER, 0x00800000               // Filter for LED ON
    .equ OFF_FILTER, 0x00000000              // Filter for LED OFF
// -------------------------------------------------------------------------------------
// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
    la t3, MorseLUT                     // Load MorseLUT to register t3
    li a3, GPIO_LED7                    // Load LED7 into address at a3
    li t4, ON_FILTER                    // Load ON filter to t4
    li t5, OFF_FILTER                   // Load OFF filter to t5

// Reset s1 to the starting address of the input string

ResetLUT:
    la s1, InputLUT           // assign s1 to the address at label LUT

// Start processing each character byte by byte

NextChar:
    lbu a0, 0(s1)             // Read a character to convert to Morse
    addi s1, s1, 1            // point to next value for number of delays, jump by 1 byte
    snez a1, a0               // If we hit 0 (null at end of the string) then reset to the start of lookup table
    bnez a1, ProcessChar      // If we have a character process it

    li a5, 0x4                //Set next delay between words to 2.0s
    jal ra, DELAY_2000MS
    j ResetLUT

// Display the converted character to the LED BAR LED_7

ProcessChar:
    jal ra, CHAR2MORSE        // convert ASCII to Morse pattern in a1
    jal LED_OFF               //Set LED to be off at the start of char
    li a5, 0x3                //Set delay between chars to be 1.5s
    jal DELAY_2000MS          //Jump to delay function

    j NextChar
        

// Turn the LED On
LED_ON:
    addi sp, sp, -16
    sw ra, 12(sp)

    lw a3, GPIO_OUTPUT_VAL(t0)  //Take the current value of the LED (on or off) and load it into a3
    or a3, a3, t4               //Flip the bit if needed to either turn LED on or keep it on
    sw a3, GPIO_OUTPUT_VAL(t0)  //Load the value at a3 into the bit that controls the LED
//    .....Insert Your Code Here.....

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

// Turn the LED Off

LED_OFF:
    addi sp, sp, -16
    sw ra, 12(sp)

    lw a3, GPIO_OUTPUT_VAL(t0)  //Take the current value of the LED (on or off) and load it into a3
    and a3, a3, t5              
    sw a3, GPIO_OUTPUT_VAL(t0)  //Load the value at a3 into the bit that controls the LED
//    .....Insert Your Code Here.....

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

//  Delay Routines
DELAY_2000MS:
    addi a5, a5, 1          // a5 has iterations, add 1 to it so it loops properly (starting at 5 going down to 1 has a difference of 4, our loop is based off the difference)

    loop:
        li s0, 0x003d0900   // Load half-second value
        addi a5, a5, -1     // Decrement the counter (number of multiples of 500ms we want)
        bnez a5, loop1      // If we haven't finished the counter (a5 != 0) delay another 500ms
        ret                 // Return to the function called from
    loop1:
        addi s0, s0, -1     // Decrement
        bnez s0, loop1      // Branch after 0.5s
        j loop              // Jump back to the loop to see if we need to decrement again

//    .....Insert Your Code Here.....

// Subroutines
// Convert ASCII character to Morse pattern
// Pass ASCII character in a0, output in a1
// Index into MorseLUT must be by steps of 2 bytes

// Convert the ASCII character to Morse Code

CHAR2MORSE:
    addi sp, sp, -16		// Set-up the stack
    sw ra, 12(sp)

    la a4, MorseLUT         //Load the address from MorseLUT into a4
    li s3, 0x41             //Immediate value of 0x41 used to find the desired address 
    sub a0, a0, s3          //Save the value of desired address to a0
    slli a0, a0, 1          //Double the value at a0 to increment halfwords properly
    add a4, a4, a0          //From the base of MorseLUT shift over using the offset in a0
    lhu a1, 0(a4)           //Load the appropriate value from the offset of MorseLUT to a1 to be passed through the values

    li s2, 0x80000000       //Filter for removing leading 0's
    leadingfix:
        and t1, a1, s2      //Filter out leading zero using and with the value stored at s2
        bnez t1, MorseDisp  //If the result was not a zero then jump to display function 
        slli a1, a1, 1      //Shift the value over so the leading zeros are discarded
        j leadingfix        //Go back to the start as we've already determined that there are no leading 0's

    MorseDisp:
        beqz a1, Done       //If the value stored at a1 is zero (shifted through every bit) jump to the end

        and a2, a1, s2      //Check if leading bit is zero
        bnez a2, Turn_ON    //If the leading bit is not zero turn the light on
        beqz a2, Turn_OFF   //If the leading bit is zero turn the light off
        Turn_ON:
            jal LED_ON      //Turn the LED on
            li a5, 0x1      //Number of times delay should be used
            jal DELAY_2000MS//Jump to the delay function after setting the value of a5
            slli a1, a1, 1  //Shift the value as the MSB has already been displayed accordingly
            j MorseDisp     //Check leading bit again by going back to the start of the display function
        Turn_OFF:
            jal LED_OFF     //Turn LED off
            li a5, 0x1      //Number of times delay should be used
            jal DELAY_2000MS//Jump to the delay function after setting the value of a5
            slli a1, a1, 1  //Shift the value as the MSB has already been displayed accordingly
            j MorseDisp     //Check leading bit again by going back to the start of the display function


    Done:
        lw ra, 12(sp)		// read stack
        addi sp, sp, 16		
        ret

// Data used in the program

.align 2

// Character input string

InputLUT:
    .asciz "ZBJLW"


// Morse Code Look Up Table

.align 2
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75   // A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55    // E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175  // I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD   // M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7    // Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757  // U, V, W, X
    .half 0x1D77, 0x775              // Y, Z

End:
  .end
// -------------------------------------------------------------------------------------
// Name:        Lab_4.S
// Purpose:     This code has 2 parts: the first part is to flash all 8 LED's on and off
//              at a rate between 1 - 10Hz while the random number generator is called
//              continuosly. The random number generated will generate a number that
//              gives a time delay of 5.0 to 25.0 seconds. with a resolution of 0.1s.
//              Pressing pushbutton S1 will create an interrupt in the microprocessor, 
//              forcing the interrupt service routine (ISR) to run.
//              The ISR program displays this random number (without a decimal) on 
//              the 8 LED's.  The program delays for 1 second (count of 10) and the
//              new count (time left) is diplayed. This continues until the count is
//              equal to or less than 0.  The program then exits the ISR and returns to
//              the main program and flashes all 8 LED's again as before.  
//              The program then waits for another press of pushbutton S1 and everything
//              repeats.

// Author:      Julius Olajos
// -------------------------------------------------------------------------------------

.section .text
.align 2
.globl _start

// Constants
GPIO_BASE                   = 0x10012000      // GPIO base address
GPIO_OUTPUT                 = 0x0C            // GPIO output register offset
GPIO_OUTPUT_ENABLE           = 0x08            // GPIO output enablr register offset
GPIO_INPUT                  = 0x00            // GPIO input register offset
GPIO_INPUT_ENABLE           = 0x04            // GPIO input enable register offset
GPIO_7SEGLED_PINS           = 0x0000023F      // Seven Segment LED Display Pins (7)
GPIO_LEDBAR_PINS            = 0x00FC0C00      // LED Bar Pins (8)
GPIO_ALL_LED_PINS           = 0x00FC0E3F      // All LED Pins (15)
GPIO_FALL_INTERRUPT_ENABLE  = 0x20            // Falling edge interrupt enable register offset
GPIO_FALL_INTERRUPT_PENDING = 0x24            // Falling Edge interrupt pending register offset
GPIO_IO_FUNCTION_ENABLE     = 0x028           // I/O function enable register offset
GPIO_IO_FUNCTION_SELECT     = 0x02C           // I/O function select register offset
PLIC_BASE                   = 0x0C000000      // PLIC base address
PLIC_ENABLE                 = 0x2000          // PLIC interrupt enable register offset
PLIC_PRIORITY               = 0x0004          // PLIC priority register offset
PLIC_THRESHOLD              = 0x200000        // PLIC threshold register offset
PLIC_CLAIM                  = 0x200004        // PLIC claim/complete register offset
PLIC_INT_PEND               = 0x1000          // PLIC Interrupt pending register 1 offset
S1_GPIO_PIN                 = 12              // S1 pushbutton pin number (active low)
S1_IRQ                      = 12              // IRQ number for GPIO pin 12
S1_PLIC_ID                  = 20              // PLIC Interrupt source ID for GPIO pin 12
S1_PRIORITY                 = 7               // Interrupt priority for S1

// --------------------------------------------------------------------------------------------------------------
// This is the setup for the interrupt functionality of the RISC-V processor
//
// --------------------------------------------------------------------------------------------------------------

_start:
    // Set up mtvec with the address of the interrupt vector (S1_interrupt)
    la t0, S1_interrupt
    csrw mtvec, t0

    // Enable external machine interrupts in the mie register
    li t0, (1 << 11)                      // Enable machine external interrupts (MEIE)
    csrs mie, t0

    // Enable global interrupts in the mstatus register
    csrr t0, mstatus
    li t1, (1 << 3)                       // Set MIE (Machine Interrupt Enable) bit mask in mstatus
    or t0, t0, t1
    csrw mstatus, t0

    li t0, GPIO_BASE                      //Initialize t0 so everything else can be based

// You need to set up the pushbutton S1 in the GPIO pins as an input. Refer to your Lab 3 code.

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for setting up the S1 pushbutton input
      li t1, (1 << S1_GPIO_PIN)              //Sets the value of the status pin to 1. 
      sw t1, GPIO_INPUT_ENABLE(t0)           //Enable t1 as an input
      sw t1, GPIO_FALL_INTERRUPT_ENABLE(t0)  //Enable the interrupt signal on the falling edge

// --------------------------------------------------------------------------------------------------------------

// You need to set up the LED's in the GPIO pins as outputs. Refer to your Lab 3 code.

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for setting up the LED outputs
      li t1, GPIO_ALL_LED_PINS               //Load values of all LED pins into t1
      sw t1, GPIO_OUTPUT_ENABLE(t0)          //Store the value from all LEDs to OUTPUT_ENABLE to make those pins outputs
      sw t1, GPIO_OUTPUT(t0)                 //Set initial value of LED outs


// --------------------------------------------------------------------------------------------------------------

// You need to configure the GPIO interrupt to trigger when S1 (GPIO pin 12) is on a falling edge.


//                   ;This is where you put your code for setting up the S1 pushbutton input interrupt
//                   ;trigger on a falling edge.


// --------------------------------------------------------------------------------------------------------------

    // Enable PLIC for S1 interrupt  
    li t1, PLIC_BASE + PLIC_ENABLE         // Calculate address of PLIC interrupt enable register
    li t2, (1 << 20)                       // Set bit 20 for PLIC Interrupt Source ID = 20 (GPIO pin 12)
    sw t2, 0(t1)

    // Set PLIC priority for S1 interrupt  // Set PLIC priority 
    li t1, PLIC_BASE
    li t2, 4*(S1_PLIC_ID)                  // Calculate address of Interrupt Priority Register
    add t2, t2, t1
    li t3, S1_PRIORITY                     // Set interrup priority = 7
    sw t3, 0(t2)

    // Set PLIC threshold to 6 (allow all interrupts)
    li t1, PLIC_BASE + PLIC_THRESHOLD      // Calculate address of PLIC threshold register
    li t2, 6                               // Set threshold to 6.  Masks all interrups of priority 6 or less
    sw t2, 0(t1) 

// --------------------------------------------------------------------------------------------------------------
 
// Main Program: Keep looping, let the interrupt handle events

// Initialize random number generator
 	li a7, 0xABCD

main_program:

//                   ;This is where you put your code for flashing LED's 
      li t4, 0x00FC0C00               //Load value to turn on aLL LEDs
      sw t4, GPIO_OUTPUT(t0)          //Send value to the display
      li a5, 1                        //Load Argument for Delay function (We decided to have the display frequency be 5Hz)
      jal DELAY                       //Jump to the delay function

      jal RandomNum                   //  Generate random number

      li t4, 0x0                      //Load value to turn off all LEDs
      sw t4, GPIO_OUTPUT(t0)          //Send value to the display
      li a5, 1                        //Load argument for the Delay function
      jal DELAY                       //Jump to the delay function
      j main_program


// Random Number generator Subroutine
// Register a7 holds the random number.
// You can read this value anywhere in the code, but this register can only be written to by this subroutine
// Or Else!

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)

     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits

     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, s4		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret


// --------------------------------------------------------------------------------------------------------------
// Interrupt Service Routine (ISR) for S1 interrupt
S1_interrupt:
      addi sp, sp, -16
      sw ra, 12(sp)

      // Acknowledge the interrupt in the PLIC (write the IRQ number to PLIC claim/complete register)
      li t1, PLIC_BASE + PLIC_CLAIM          // Calculate address of PLIC claim/complete register
      lw t5, 0(t1)                           // Read the PLIC Interrupt ID


//                   ;This is where you put your code:
//                   ;Calculate the time from the randomly generated number in register a7. You will have to scale the random number. Perhaps a7 mod 200 + 50 would work?
      li a4, 200        //Store 200 in a4 to start shifting a7 around to find desired value
      rem a4, a7, a4    //First step in scaling is findinging a7 mod 200
      addi a4, a4, 50   //Add 50 to a4
//                   ;Display this number on the 8 LED's
//                   ;Subtract 10 (Hex A) and display the number again until it is less than or equal to 0
//                   ;Reset counter to 0 before exiting the subroutine so it's ready to be used again
      Output_Num:
            mv a3, a4   //a3 is the argument register for the DISPLAY subroutine
            jal DISPLAY_NUM //Jump to the DISPLAY function
            addi a4, a4, -10 //Decrement a4 by 10
            bge x0, a4, EXITNUM
            li a5, 10        //Load 10 into a5 to send to delay function to display for 1 second
            jal DELAY_1S
            j Output_Num

      EXITNUM:
// You need to clear the interrupt pending flag for S1 (GPIO pin 12). Refer to Appendix I in the lab manual

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for clearing the interrupt pending flag for S1

      li t1, (1 << S1_GPIO_PIN)     //Store the value to clear the desired interrupt bit
      lw t2, GPIO_FALL_INTERRUPT_PENDING(t0) //Get the current value of the interrupt
      or t1, t1, t2                 //Set the bit that corresponds to the interrupt to 1 since the button is active low (Interrupt is active when the value is 0)
      sw t1, GPIO_FALL_INTERRUPT_PENDING(t0) //Write the new value back to the current status of the interrupt to say it's done



// You need to acknowledge the interrupt is complete in the PLIC Refer to Appendix I in the lab manual

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for acknowledging the interrupt in the PLIC

      // Acknowledge the interrupt in the PLIC (write the IRQ number to PLIC claim/complete register)
      li t1, PLIC_BASE + PLIC_CLAIM          
      sw t5, 0(t1)                           //Write back to the PLIC to say that it's completed 

      end_interrupt:
            lw ra, 12(sp)                            
            addi sp, sp, 16
            mret                                   // Return from interrupt

DISPLAY_NUM: //Arguement register is a3
      addi sp, sp, -16
      sw ra, 12(sp)
    
      andi a1, a3, 0x3    // Mask to leave last two bits (Need these in 10 and 11)
      andi a2, a3, 0xFC   // Mask to leave first 6 digits in number (Need these in 18 to 23)
      slli a1, a1, 10     // Store first 2 LED bits in a1 after isolating
      slli a2, a2, 16     // Store last 6 LED bits in a2 after isolating
      add a3, a1, a2      // Put the values together to create the output signal
      sw a3, GPIO_OUTPUT(t0) //Send values to the LED
      
      lw ra, 12(sp)
      addi sp, sp, 16
      ret

DELAY:
    addi a5, a5, 1          // a5 has iterations, add 1 to it so it loops properly (starting at 5 going down to 1 has a difference of 4, our loop is based off the difference)

    loop:
        li s0, 0xc3500      // Load 0.1 second value
        addi a5, a5, -1     // Decrement the counter (number of multiples of 500ms we want)
        bnez a5, loop1      // If we haven't finished the counter (a5 != 0) delay another 500ms
        ret                 // Return to the function called from
    loop1:
        addi s0, s0, -1     // Decrement
        bnez s0, loop1      // Branch after 0.5s
        j loop              // Jump back to the loop to see if we need to decrement again

DELAY_1S:
      li a6, 0x7A1200       //Set value for one second
      Delay1s_inner:
            addi a6, a6, -1
            bnez a6, Delay1s_inner
            ret
/******************************************************************************
  Filename    : etm_demo.c
  
  Core        : ARM Cortex-M33
  
  MCU         : RP2350
    
  Author      : Educational Demo
 
  Date        : 15.08.2025
  
  Description : ETM demo functions for college students
                Compatible with czietz/etm-trace-rp2350
  
******************************************************************************/

#include "etm_demo.h"
#include "Gpio.h"

#ifdef CORE_FAMILY_ARM
// RP2350 Clock and Reset Control (adapt addresses from datasheet)
#define SYS_CLOCK_CTRL_BASE   0x40008000
#define TRACE_CLOCK_ENABLE    (SYS_CLOCK_CTRL_BASE + 0x20)
#define TRACE_RESET_CTRL      (SYS_CLOCK_CTRL_BASE + 0x24)

void etm_enable_hardware(void) {
    // Correct RP2350 base addresses from datasheet
    volatile uint32_t *psm_frce_on = (volatile uint32_t *)0x40018000;   // PSM_BASE
    volatile uint32_t *psm_done = (volatile uint32_t *)0x4001800C;      // PSM_BASE + 0x0C
    volatile uint32_t *resets_reset = (volatile uint32_t *)0x40020000;  // RESETS_BASE
    volatile uint32_t *resets_done = (volatile uint32_t *)0x40020008;   // RESETS_BASE + 0x08
    volatile uint32_t *clk_sys_ctrl = (volatile uint32_t *)0x4001003C;  // CLOCKS_BASE + 0x3C
    volatile uint32_t *clk_peri_ctrl = (volatile uint32_t *)0x40010048; // CLOCKS_BASE + 0x48
    
    // ETM/CoreSight specific registers
    volatile uint32_t *etm_unlock = (volatile uint32_t *)0x50000FB0;    // ETM Lock Access
    volatile uint32_t *etm_lock_status = (volatile uint32_t *)0x50000FB4; // ETM Lock Status
    volatile uint32_t *dbgauthstatus = (volatile uint32_t *)0xE000EFB8;  // Debug Authentication Status
    volatile uint32_t *dhcsr = (volatile uint32_t *)0xE000EDF0;          // Debug Halting Control
    
    // 1. Enable debug authentication and halt control
    *dhcsr = 0xA05F0001;  // Enable debug, halt if needed
    
    // 2. Configure debug authentication (allow non-secure debug)
    *dbgauthstatus = 0x0000000F;  // Enable all debug authentication bits
    
    // 3. Force power on ALL required power domains for ETM
    // Bits: 0=SYS, 1=PROC0, 2=PROC1, 3=SIO, 4=VREG_AND_CHIP_RESET, 5=XIP, 6=SRAM0-5
    *psm_frce_on |= (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6);

    // 4. Wait until ALL power domains are ready
    uint32_t required_domains = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6);
    while((*psm_done & required_domains) != required_domains) {
        __asm__("nop");
    }

    // 5. Release resets for ALL debug and trace peripherals
    // Bits: 2=DMA, 8=TRNG, 24=SYSCFG, plus any debug-related resets
    *resets_reset &= ~((1 << 2) | (1 << 8) | (1 << 24));

    // 6. Wait until reset release is confirmed
    uint32_t required_resets = (1 << 2) | (1 << 8) | (1 << 24);
    while ((*resets_done & required_resets) != required_resets) {
       __asm__("nop");
    }

    // 7. Enable ALL required clocks for trace system
    *clk_sys_ctrl |= (1 << 11);   // System clock enable
    *clk_peri_ctrl |= (1 << 11);  // Peripheral clock enable
    
    // 8. Unlock ETM registers using CoreSight unlock sequence
    *etm_unlock = 0xC5ACCE55;  // CoreSight unlock key
    
    // 9. Verify ETM is unlocked
    volatile uint32_t lock_status = *etm_lock_status;
    if (lock_status & 0x1) {
        // ETM still locked - try alternative unlock
        *etm_unlock = 0xC5ACCE55;
        __asm__("dsb");
        __asm__("isb");
    }

    // 10. Extended stabilization delay for all subsystems
    // REDUCED for ETM tracing - was 50000
    for (volatile int i = 0; i < 100; i++) {
        __asm__("nop");
    }
    
    // 11. Memory barriers to ensure all writes complete
    __asm__("dsb");
    __asm__("isb");
}






// ETM buffer in SRAM4 with proper alignment
__attribute__((aligned(8192))) 
uint32 etm_buffer[8192] __attribute__((section(".sram4"))) = {0};


//=============================================================================
// Demo Functions for ETM Educational Tracing
//=============================================================================

void demo_delay(uint32 cycles) {
    volatile uint32 count = cycles;
    while(count--) {
        __asm volatile("nop");
    }
}

void demo_function_a(void) {
    // Function with multiple branches - creates rich ETM trace
    volatile int x = 1;
    
    LED_GREEN_ON();
    
    if(x > 0) {
        x = x + 2;
        //demo_delay(50000);  // Disabled for ETM trace
    }
    
    for(int i = 0; i < 2; i++) {
        x = x * 2;
        if(i % 2) {
            LED_GREEN_TOGGLE();
        }
    }
    
    //demo_delay(100000);  // Disabled for ETM trace
    LED_GREEN_OFF();
    
    // ETM captures: function entry, conditional branches, loop iterations, returns
}

void demo_function_b(void) {
    // Different branching pattern for comparison
    volatile int y = 5;
    
    LED_GREEN_ON();
    //demo_delay(30000);  // Disabled for ETM trace
    
    while(y > 0) {
        LED_GREEN_TOGGLE();
        //demo_delay(20000);
        y--;
        
        if(y == 2) {
            break;  // ETM captures this early loop exit
        }
    }
    
    LED_GREEN_OFF();
    
    // ETM captures: function entry, while loop, conditional break, return
}

void demo_branch_example(int condition) {
    // Classic conditional branch - fundamental for trace analysis
    volatile int result = 0;
    
    if(condition > 5) {
        result = 1;
        demo_function_a();  // ETM traces function call decision
    } else if(condition > 2) {
        result = 2; 
        demo_function_b();  // ETM traces alternative path
    } else {
        result = 3;
        LED_GREEN_ON();
        //demo_delay(150000);  // Disabled for ETM trace
        //LED_GREEN_OFF();
    }
    
    // ETM captures: all branch decisions and function calls based on condition
}

void demo_loop_example(void) {
    // Loop with varying patterns - shows iteration behavior
    
    for(int i = 0; i < 5; i++) {
        LED_GREEN_ON();
        //demo_delay(100000);  // Disabled for ETM trace
        
        if(i % 3 == 0) {
            demo_function_a();  // Called on iterations 0, 3
        } else if(i % 3 == 1) {
            demo_function_b();  // Called on iterations 1, 4  
        } else {
            // i % 3 == 2: iteration 2
            LED_GREEN_TOGGLE();
            //demo_delay(200000);  // Disabled for ETM trace
            LED_GREEN_TOGGLE();
        }
        
        LED_GREEN_OFF();
        //demo_delay(50000);  // Disabled for ETM trace
    }
    
    // ETM captures: loop structure, modulo conditions, function call patterns
}

void demo_recursive_function(int depth) {
    // Recursive calls create nested trace patterns
    volatile int local_var = depth;
    
    LED_GREEN_TOGGLE();
    //demo_delay(30000 * depth);  // Disabled for ETM trace  // Variable delay based on depth
    
    if(depth > 0) {
        local_var = local_var - 1;
        demo_recursive_function(depth - 1);  // ETM traces recursive calls
    }
    
    LED_GREEN_TOGGLE();
    
    // ETM captures: recursive call stack, parameter passing, return sequence
}

void demo_nested_calls(void) {
    // Complex call graph for advanced trace analysis
    
    demo_branch_example(1);   // Will take path 3 (condition <= 2)
    //demo_delay(300000);  // Disabled for ETM trace
    
    demo_branch_example(4);   // Will take path 2 (2 < condition <= 5) 
    //demo_delay(300000);  // Disabled for ETM trace
    
    demo_branch_example(8);   // Will take path 1 (condition > 5)
    //demo_delay(300000);  // Disabled for ETM trace
    
    demo_recursive_function(3); // 4 levels of recursion (3,2,1,0)
    
    // ETM captures: complete call graph with different execution paths
}

#endif // CORE_FAMILY_ARM

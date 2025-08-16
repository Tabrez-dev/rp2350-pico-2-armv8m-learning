/******************************************************************************
  Filename    : etm_demo.h
  
  Core        : ARM Cortex-M33
  
  MCU         : RP2350
    
  Author      : Educational Demo
 
  Date        : 15.08.2025
  
  Description : ETM (Embedded Trace Macrocell) demo for college students
                Compatible with czietz/etm-trace-rp2350
  
******************************************************************************/

#ifndef ETM_DEMO_H
#define ETM_DEMO_H

#include "Platform_Types.h"

#ifdef CORE_FAMILY_ARM

//=============================================================================
// ETM Trace Buffer Configuration - Compatible with czietz implementation
//=============================================================================

// ETM trace buffer - must be in SRAM for DMA access
// Using 32KB aligned buffer to match GDB configuration
#define ETM_BUFFER_SIZE  32768  // 32KB buffer (8192 words)
extern uint32 etm_buffer[8192] __attribute__((aligned(8192)));

//=============================================================================
// Function Prototypes
//=============================================================================

// Educational demo functions that generate interesting trace patterns
void demo_function_a(void);
void demo_function_b(void); 
void demo_branch_example(int condition);
void demo_loop_example(void);
void demo_nested_calls(void);
void demo_recursive_function(int depth);

// Helper function for visible delays
void demo_delay(uint32 cycles);
void etm_enable_hardware(void);
#endif // CORE_FAMILY_ARM

#endif // ETM_DEMO_H

// /******************************************************************************************
//   Filename    : main.c
  
//   Core        : ARM Cortex-M33 / RISC-V Hazard3
  
//   MCU         : RP2350
    
//   Author      : Chalandi Amine
 
//   Owner       : Chalandi Amine
  
//   Date        : 04.09.2024
  
//   Description : Application main function
  
// ******************************************************************************************/

// //=============================================================================
// // Includes
// //=============================================================================
// #include "Platform_Types.h"
// #include "Cpu.h"
// #include "Gpio.h"
// #include "SysTickTimer.h"

// //=============================================================================
// // Macros
// //=============================================================================

// //=============================================================================
// // Prototypes
// //=============================================================================
// void main_Core0(void);
// void main_Core1(void);
// void BlockingDelay(uint32 delay);

// //=============================================================================
// // Globals
// //=============================================================================
// #ifdef DEBUG
//   volatile boolean boHaltCore0 = TRUE;
//   volatile boolean boHaltCore1 = TRUE;
// #endif

// //-----------------------------------------------------------------------------------------
// /// \brief  main function
// ///
// /// \param  void
// ///
// /// \return void
// //-----------------------------------------------------------------------------------------
// int main(void)
// {
//   /* Run the main function of the core 0, it will start the core 1 */
//   main_Core0();

//   /* Synchronize with core 1 */
//   RP2350_MulticoreSync((uint32_t)HW_PER_SIO->CPUID.reg);

//   /* endless loop on the core 0 */
//   for(;;);

//   /* never reached */
//   return(0);
// }

// //-----------------------------------------------------------------------------------------
// /// \brief  main_Core0 function
// ///
// /// \param  void
// ///
// /// \return void
// //-----------------------------------------------------------------------------------------
// void main_Core0(void)
// {
// #ifdef DEBUG
//   while(boHaltCore0);
// #endif

// #ifdef CORE_FAMILY_ARM
//   /* Disable interrupts on core 0 */
//   __asm volatile("CPSID i");
// #endif

//   /* Output disable on pin 25 */
//   LED_GREEN_CFG();


//   /* Start the Core 1 and turn on the led to be sure that we passed successfully the core 1 initiaization */
//   if(TRUE == RP2350_StartCore1())
//   {
//     LED_GREEN_ON();
//   }
//   else
//   {
//     /* Loop forever in case of error */
//     while(1)
//     {
//       __asm volatile("NOP");
//     }
//   }

// }

// //-----------------------------------------------------------------------------------------
// /// \brief  main_Core1 function
// ///
// /// \param  void
// ///
// /// \return void
// //-----------------------------------------------------------------------------------------
//   volatile uint64_t* pMTIMECMP = (volatile uint64_t*)&(HW_PER_SIO->MTIMECMP.reg);
//   volatile uint64_t* pMTIME    = (volatile uint64_t*)&(HW_PER_SIO->MTIME.reg);

// void main_Core1(void)
// {
// #ifdef DEBUG
//   while(boHaltCore1);
// #endif

//   /* Note: Core 1 is started with interrupt enabled by the BootRom */

//   /* Clear the stiky bits of the FIFO_ST on core 1 */
//   HW_PER_SIO->FIFO_ST.reg = 0xFFu;

// #ifdef CORE_FAMILY_ARM

//   /*Setting EXTEXCLALL allows external exclusive operations to be used in a configuration with no MPU.
//   This is because the default memory map does not include any shareable Normal memory.*/
//   SCnSCB->ACTLR |= (1ul<<29);

//   __asm volatile("DSB");

//   /* Clear all pending interrupts on core 1 */
//   NVIC->ICPR[0] = (uint32)-1;

// #endif

//   /* Synchronize with core 0 */
//   RP2350_MulticoreSync((uint32_t)HW_PER_SIO->CPUID.reg);


// #ifdef CORE_FAMILY_RISC_V

//   /* configure the machine timer for 1Hz interrupt window */
//   #include "riscv.h"

//   /* enable machine timer interrupt */
//   riscv_set_csr(RVCSR_MIE_OFFSET, 0x80ul);

//   /* enable global interrupt */
//   riscv_set_csr(RVCSR_MSTATUS_OFFSET, 0x08ul);

//   /* configure machine timer to use 150 MHz */
//   HW_PER_SIO->MTIME_CTRL.bit.FULLSPEED = 1;

//   /* set next timeout (machine timer is enabled by default) */
//   *pMTIMECMP = *pMTIME + 150000000ul; //1s

// #else

//   /* configure ARM systick timer */
//   SysTickTimer_Init();
//   SysTickTimer_Start(SYS_TICK_MS(100));

// #endif

//   while(1)
//   {
//     __asm("nop");
//   }
// }


// #ifdef CORE_FAMILY_RISC_V
//   __attribute__((interrupt)) void Isr_MachineTimerInterrupt(void);
  
//   void Isr_MachineTimerInterrupt(void)
//   {
//     *pMTIMECMP = *pMTIME + 150000000ul;
  
//     LED_GREEN_TOGGLE();
//   }

// #else

//   void SysTickTimer(void);

//   void SysTickTimer(void)
//   {
//     static uint32_t cpt = 0;

//     SysTickTimer_Reload(SYS_TICK_MS(100));
    
//     if(++cpt >= 10ul)
//     {
//       LED_GREEN_TOGGLE();
//       cpt = 0;
//     }
//   }
// #endif



/******************************************************************************
  Filename    : main.c
  
  Core        : ARM Cortex-M33 / RISC-V Hazard3
  
  MCU         : RP2350
    
  Author      : Chalandi Amine
 
  Owner       : Chalandi Amine
  
  Date        : 04.09.2024
  
  Description : Application main function with ETM demo
  
******************************************************************************/

//=============================================================================
// Includes
//=============================================================================
#include "Platform_Types.h"
#include "Cpu.h"
#include "Gpio.h"
#include "SysTickTimer.h"

#ifdef CORE_FAMILY_ARM
#include "etm_demo.h"
#endif

//=============================================================================
// Macros
//=============================================================================

//=============================================================================
// Prototypes
//=============================================================================
void main_Core0(void);
void main_Core1(void);
void BlockingDelay(uint32 delay);

//=============================================================================
// Globals
//=============================================================================
#ifdef DEBUG
  volatile boolean boHaltCore0 = TRUE;
  volatile boolean boHaltCore1 = TRUE;
#endif

//-----------------------------------------------------------------------------------------
/// \brief  main function
///
/// \param  void
///
/// \return void
//-----------------------------------------------------------------------------------------
int main(void)
{
  /* Run the main function of the core 0, it will start the core 1 */
  main_Core0();

  /* Synchronize with core 1 */
  RP2350_MulticoreSync((uint32_t)HW_PER_SIO->CPUID.reg);

#ifdef CORE_FAMILY_ARM
  /*=================================================================
   * ETM EDUCATIONAL DEMO SECTION
   * 
   * Students will use GDB ETM commands to trace these functions:
   * 
   * 1. (gdb) source etm-scripts/trace.gdb  
   * 2. (gdb) trc_setup etm_buffer sizeof(etm_buffer) 12 0 1 1 0
   * 3. (gdb) trc_start
   * 4. (gdb) c  (continue - runs demos below)
   * 5. (gdb) trc_save etm_trace.bin
   * 6. ptm2human -e etm_trace.bin > readable_trace.txt
   *================================================================*/
  
  // Demo 1: Simple conditional branching
  demo_branch_example(3);   // Takes middle path (calls demo_function_b)
  //BlockingDelay(1000000);   // 1 second pause between demos
  
  // Demo 2: Loop with multiple patterns  
  demo_loop_example();      // 5 iterations with different call patterns
  //BlockingDelay(1000000);   // Disabled for ETM trace capture
  
  // Demo 3: Different conditional path
  demo_branch_example(7);   // Takes first path (calls demo_function_a) 
  //BlockingDelay(1000000);   // Disabled for ETM trace capture
  
  // Demo 4: Complex nested calls and recursion
  demo_nested_calls();      // Multiple function calls + recursion
  
  /* 
   * STUDENTS: Set breakpoint here to analyze ETM trace
   * 
   * The ETM will have captured:
   * - All function calls and returns
   * - Branch decisions (if/else/while/for)
   * - Loop iterations and exit conditions  
   * - Recursive call patterns
   * - Exception handling (if any interrupts occur)
   */
#endif

  /* endless loop on the core 0 */
  for(;;) {
    __asm volatile("NOP");  // <-- Set GDB breakpoint here for trace analysis
  }

  /* never reached */
  return(0);
}

//-----------------------------------------------------------------------------------------
/// \brief  main_Core0 function
///
/// \param  void
///
/// \return void
//-----------------------------------------------------------------------------------------
void main_Core0(void)
{
#ifdef DEBUG
  while(boHaltCore0);
#endif

#ifdef CORE_FAMILY_ARM
  /* Disable interrupts on core 0 */
  __asm volatile("CPSID i");
  etm_enable_hardware();

#endif

  /* Output disable on pin 25 */
  LED_GREEN_CFG();

  /* Start the Core 1 and turn on the led to be sure that we passed successfully the core 1 initialization */
  if(TRUE == RP2350_StartCore1())
  {
    LED_GREEN_ON();
    BlockingDelay(500000);  // Brief indication
    LED_GREEN_OFF();
  }
  else
  {
    /* Loop forever in case of error */
    while(1)
    {
      __asm volatile("NOP");
    }
  }
}

//-----------------------------------------------------------------------------------------
/// \brief  main_Core1 function
///
/// \param  void
///
/// \return void
//-----------------------------------------------------------------------------------------
volatile uint64_t* pMTIMECMP = (volatile uint64_t*)&(HW_PER_SIO->MTIMECMP.reg);
volatile uint64_t* pMTIME    = (volatile uint64_t*)&(HW_PER_SIO->MTIME.reg);

void main_Core1(void)
{
#ifdef DEBUG
  while(boHaltCore1);
#endif

  /* Note: Core 1 is started with interrupt enabled by the BootRom */

  /* Clear the sticky bits of the FIFO_ST on core 1 */
  HW_PER_SIO->FIFO_ST.reg = 0xFFu;

#ifdef CORE_FAMILY_ARM

  /*Setting EXTEXCLALL allows external exclusive operations to be used in a configuration with no MPU.
  This is because the default memory map does not include any shareable Normal memory.*/
  SCnSCB->ACTLR |= (1ul<<29);

  __asm volatile("DSB");

  /* Clear all pending interrupts on core 1 */
  NVIC->ICPR[0] = (uint32)-1;

#endif

  /* Synchronize with core 0 */
  RP2350_MulticoreSync((uint32_t)HW_PER_SIO->CPUID.reg);

#ifdef CORE_FAMILY_RISC_V

  /* configure the machine timer for 1Hz interrupt window */
  #include "riscv.h"

  /* enable machine timer interrupt */
  riscv_set_csr(RVCSR_MIE_OFFSET, 0x80ul);

  /* enable global interrupt */
  riscv_set_csr(RVCSR_MSTATUS_OFFSET, 0x08ul);

  /* configure machine timer to use 150 MHz */
  HW_PER_SIO->MTIME_CTRL.bit.FULLSPEED = 1;

  /* set next timeout (machine timer is enabled by default) */
  *pMTIMECMP = *pMTIME + 150000000ul; //1s

#else

  /* configure ARM systick timer */
  SysTickTimer_Init();
  SysTickTimer_Start(SYS_TICK_MS(100));

#endif

  while(1)
  {
    __asm("nop");
  }
}

#ifdef CORE_FAMILY_RISC_V
  __attribute__((interrupt)) void Isr_MachineTimerInterrupt(void);
  
  void Isr_MachineTimerInterrupt(void)
  {
    *pMTIMECMP = *pMTIME + 150000000ul;
  
    LED_GREEN_TOGGLE();
  }

#else

  void SysTickTimer(void);

  void SysTickTimer(void)
  {
    static uint32_t cpt = 0;

    SysTickTimer_Reload(SYS_TICK_MS(100));
    
    if(++cpt >= 10ul)
    {
      LED_GREEN_TOGGLE();
      cpt = 0;
    }
  }
#endif

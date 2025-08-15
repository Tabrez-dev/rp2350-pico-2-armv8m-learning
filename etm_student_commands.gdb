# Complete ETM Educational Demo for RP2350 Pico 2
# Compatible with czietz/etm-trace-rp2350

define etm_student_demo
    printf "\n========================================\n"
    printf "ETM EDUCATIONAL DEMO - RP2350 Pico 2\n" 
    printf "========================================\n\n"
    
    printf "Step 1: Loading ETM trace system...\n"
    source etm-scripts/trace.gdb
    
    printf "Step 2: Setting up 8KB trace buffer...\n"
    printf "Buffer location: etm_buffer (0x%08x)\n", &etm_buffer
    printf "Buffer size: %d bytes\n", sizeof(etm_buffer)
    
    # Setup ETM with czietz parameters:
    # trc_setup [addr] [size] [dmachan] [ccount] [bbroadc] [formatter] [tstamp]
    #   addr      = etm_buffer address  
    #   size      = 8192 bytes
    #   dmachan   = 12 (DMA channel)
    #   ccount    = 0 (no cycle counting for simplicity)  
    #   bbroadc   = 1 (enable branch broadcasting)
    #   formatter = 1 (enable formatter)
    #   tstamp    = 0 (no timestamps for simplicity)
    trc_setup etm_buffer sizeof(etm_buffer) 12 0 1 1 0
    
    printf "\nStep 3: Starting ETM trace capture...\n"
    printf "The demo will now run and capture all program execution.\n"
    printf "When it stops at the breakpoint, use 'etm_save_trace'\n\n"
    
    trc_start
    
    printf "\n*** ETM IS NOW TRACING ALL EXECUTION ***\n"
    printf "Continue program execution with 'c' command\n"
    printf "========================================\n\n"
end

define etm_save_trace
    printf "\n========================================\n"
    printf "SAVING ETM TRACE DATA\n"
    printf "========================================\n\n"
    
    trc_save student_etm_trace.bin
    
    printf "✓ ETM trace saved as: student_etm_trace.bin\n\n"
    
    printf "========================================\n"
    printf "NEXT STEPS FOR ANALYSIS:\n"
    printf "========================================\n"
    printf "1. Decode trace to readable format:\n"
    printf "   ptm2human -e student_etm_trace.bin > readable_trace.txt\n\n"
    printf "2. Open readable_trace.txt to see:\n"
    printf "   - Every function call and return\n"
    printf "   - All branch decisions (if/else/loops)\n"  
    printf "   - Exact instruction addresses\n"
    printf "   - Program execution timeline\n\n"
    printf "3. Compare trace with your source code to understand:\n"
    printf "   - Which branches were taken\n"
    printf "   - How loops executed\n"
    printf "   - Function call sequences\n"
    printf "========================================\n\n"
end

define etm_complete_demo
    etm_student_demo
    printf "Program will now run. When it stops, type: etm_save_trace\n"
end

printf "\n============================================\n"
printf "ETM STUDENT COMMANDS LOADED\n" 
printf "============================================\n"
printf "etm_complete_demo  - Run full ETM demo\n"
printf "etm_student_demo   - Setup and start tracing\n"  
printf "etm_save_trace     - Save trace after execution\n"
printf "============================================\n\n"
printf "USAGE:\n"
printf "1. Set breakpoint at main() infinite loop\n"
printf "2. Run: etm_complete_demo\n" 
printf "3. Continue with 'c' until breakpoint\n"
printf "4. Run: etm_save_trace\n"
printf "5. Decode: ptm2human -e student_etm_trace.bin > trace.txt\n"
printf "============================================\n\n"

# Simplified ETM Function Tracing for RP2350
# Streamlined for quick function analysis workflow

# Quick setup and start - single command
define etm_quick_start
    dont-repeat
    
    printf "Starting ETM trace for function analysis...\n"
    
    # Load the core trace system
    source C:/Users/tabre/Desktop/Pico 2/Blinky_Pico2_dual_core_nosdk/etm-scripts/trace.gdb
    
    # Standard configuration for function tracing
    # Buffer: 8KB, DMA channel 12, cycle counting off, branch broadcast on
    trc_setup 0x20040000 8192 12 0 1 1 0
    
    # Start tracing
    trc_start
    
    printf "✓ ETM tracing active. Continue execution with 'c'\n"
    printf "  Set breakpoints after functions you want to trace\n"
    printf "  Use 'etm_quick_save' to save and analyze\n"
end

# Quick save with automatic analysis
define etm_quick_save
    dont-repeat
    
    printf "Saving ETM trace...\n"
    
    # Create trace directory
    shell mkdir -p trace
    
    # Save trace
    trc_save trace/etm_trace.bin
    
    printf "✓ Trace saved to: trace/etm_trace.bin\n"
    printf "\nTo analyze with Python script:\n"
    printf "cd trace && python ../../etm_raw_analyzer.py etm_trace.bin --tarmac --viewer\n"
end

# Function-specific tracing helper
define trace_function
    dont-repeat
    
    if $argc == 0
        printf "Usage: trace_function <function_name>\n"
        printf "Example: trace_function demo_1\n"
        return
    end
    
    printf "Setting up trace for function: %s\n", $arg0
    
    # Set breakpoint at function entry
    eval "break %s", $arg0
    
    # Start tracing when we hit the breakpoint
    commands
        printf "Entered %s - starting trace\n", $arg0
        etm_quick_start
        continue
    end
    
    printf "✓ Breakpoint set. Run program to start tracing at %s\n", $arg0
end

# Ultra-simple 2-command workflow
define etm_start
    dont-repeat
    # Clear old trace files from both locations to ensure fresh capture
    shell rm -f trace/etm_trace.bin trace/etm_ptm2human.txt trace/etm_ptm2human_annotated.txt ../trace/etm_trace.bin 2>/dev/null || del /Q trace\etm_trace.bin trace\etm_ptm2human.txt trace\etm_ptm2human_annotated.txt ..\trace\etm_trace.bin 2>nul || echo "Clearing old traces..."
    source C:/Users/tabre/Desktop/Pico 2/Blinky_Pico2_dual_core_nosdk/etm-scripts/trace.gdb
    trc_setup 0x20040000 32768 12 0 1 1 0
    trc_start 
    printf "✓ Tracing started (circular buffer)\n"
end

define etm_save
    dont-repeat
    shell if not exist trace mkdir trace
    trc_save trace/etm_trace.bin
    printf "✓ Saved: trace/etm_trace.bin\n"
end

# Endless (circular buffer) start helper
define etm_start_endless
    dont-repeat
    source C:/Users/tabre/Desktop/Pico 2/Blinky_Pico2_dual_core_nosdk/etm-scripts/trace.gdb
    # For endless mode, it's recommended to disable the formatter
    # Buffer: 8KB aligned at 0x20040000, DMA 12, cycle counting off, BB on, formatter off, no timestamp
    trc_setup 0x20040000 8192 12 0 1 0 0
    trc_start 1
    printf "✓ Endless tracing started (circular buffer)\n"
end

# Decode hint helper (prints command you can run)
define etm_decode
    dont-repeat
    if $argc == 0
        printf "Usage: etm_decode <binfile>\n"
        printf "Example: etm_decode trace/etm_trace.bin\n"
        printf "\nDecoding command:\n"
        printf "./ptm2human.exe -e -i trace/etm_trace.bin > etm_ptm2human.txt\n"
        return
    end
    printf "Decode with: ./ptm2human.exe -e -i %s > etm_ptm2human.txt\n", $arg0
end

# Auto-decode and annotate trace
define etm_analyze
    dont-repeat
    printf "🔍 Running ETM trace analysis...\n"
    # Use dedicated batch script to handle working directory and paths properly
    shell "c:/Users/tabre/Desktop/Pico 2/Blinky_Pico2_dual_core_nosdk/etm_analyze.bat"
    printf "✅ Analysis complete!\n"
    printf "📄 Files created in trace/ folder:\n"
    printf "   - trace/etm_trace.bin (raw ETM data)\n"
    printf "   - trace/etm_ptm2human.txt (decoded trace)\n"
    printf "   - trace/etm_ptm2human_annotated.txt (with C source mapping)\n"
end

# Complete workflow: save + decode + annotate
define etm_complete
    dont-repeat
    printf "💾 Saving trace...\n"
    etm_save
    printf "🔍 Analyzing trace...\n"
    etm_analyze
    printf "🎉 Complete ETM analysis finished!\n"
end

printf "\n===========================================\n"
printf "SIMPLIFIED ETM FUNCTION TRACING LOADED\n"
printf "===========================================\n"
printf "QUICK COMMANDS:\n"
printf "etm_start           - Start tracing (replaces etm_enhanced_start)\n"
printf "etm_start_endless   - Start endless circular tracing (8/16/32 KiB buffer)\n"
printf "etm_save            - Save trace to trace/etm_trace.bin\n"
printf "etm_decode <file>   - Print decoder command for saved trace\n"
printf "\nAUTOMATED ANALYSIS:\n"
printf "etm_analyze         - Decode and annotate saved trace\n"
printf "etm_complete        - Save + decode + annotate in one command\n"
printf "\nOPTIONAL HELPERS:\n"
printf "etm_quick_start     - Start with status messages\n"
printf "etm_quick_save      - Save with instructions\n"
printf "trace_function <fn> - Auto-breakpoint and trace function\n"
printf "\nYOUR WORKFLOW:\n"
printf "1. b demo_1         # Set breakpoint after function\n"
printf "2. run              # Start program\n"
printf "3. etm_start        # Start tracing at breakpoint\n"
printf "   - or - etm_start_endless   # for circular buffer tracing\n"
printf "4. c                # Continue to trace function\n"
printf "5. etm_complete     # Save + decode + annotate automatically\n"
printf "   - or - etm_save + etm_analyze   # Step by step\n"
printf "===========================================\n"
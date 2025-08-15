# Enhanced ETM tracing for RP2350 - Educational Version
# Fixes peripheral access issues and adds debugging capabilities

# Enhanced setup with proper error checking
define etm_enhanced_setup
    printf "\n========================================\n"
    printf "ENHANCED ETM SETUP - RP2350 Pico 2\n"
    printf "========================================\n\n"
    
    # Step 1: Verify debug connection
    printf "Step 1: Verifying debug connection...\n"
    set $dhcsr = {long}0xE000EDF0
    if ($dhcsr & 0x1) == 0
        printf "ERROR: Debug not enabled. Enabling now...\n"
        set {long}0xE000EDF0 = 0xA05F0001
    else
        printf "✓ Debug connection verified\n"
    end
    
    # Step 2: Check and configure power domains
    printf "\nStep 2: Configuring power domains...\n"
    set $psm_frce_on = {long}0x40018000
    set $psm_done = {long}0x4001800C
    
    printf "Current PSM_FRCE_ON: 0x%08x\n", $psm_frce_on
    printf "Current PSM_DONE: 0x%08x\n", $psm_done
    
    # Force all required power domains
    set {long}0x40018000 = $psm_frce_on | 0x7F
    
    # Wait with timeout
    set $timeout = 10000
    while (({long}0x4001800C & 0x7F) != 0x7F) && ($timeout > 0)
        set $timeout = $timeout - 1
    end
    
    if $timeout == 0
        printf "WARNING: Power domain timeout. Current PSM_DONE: 0x%08x\n", {long}0x4001800C
    else
        printf "✓ All power domains ready\n"
    end
    
    # Step 3: Configure resets
    printf "\nStep 3: Releasing peripheral resets...\n"
    set $resets_reset = {long}0x40020000
    set $resets_done = {long}0x40020008
    
    printf "Current RESETS_RESET: 0x%08x\n", $resets_reset
    printf "Current RESETS_DONE: 0x%08x\n", $resets_done
    
    # Release required resets
    set {long}0x40020000 = $resets_reset & ~0x1000104
    
    # Wait for reset release
    set $timeout = 10000
    while (({long}0x40020008 & 0x1000104) != 0x1000104) && ($timeout > 0)
        set $timeout = $timeout - 1
    end
    
    if $timeout == 0
        printf "WARNING: Reset release timeout. Current RESETS_DONE: 0x%08x\n", {long}0x40020008
    else
        printf "✓ Peripheral resets released\n"
    end
    
    # Step 4: Enable clocks
    printf "\nStep 4: Enabling trace clocks...\n"
    set {long}0x4001003C = {long}0x4001003C | (1<<11)
    set {long}0x40010048 = {long}0x40010048 | (1<<11)
    printf "✓ Clocks enabled\n"
    
    # Step 5: Unlock ETM registers
    printf "\nStep 5: Unlocking ETM registers...\n"
    
    # Try to read ETM ID register first
    set $etm_base = 0x50000000
    printf "Attempting to read ETM base registers...\n"
    
    # Check if we can access the ETM region at all
    set $test_read = 0
    set $access_ok = 1
    
    # Try to read a safe register
    monitor halt
    
    # Unlock sequence
    printf "Sending ETM unlock sequence...\n"
    set {long}0x50000FB0 = 0xC5ACCE55
    
    # Check lock status
    set $lock_status = {long}0x50000FB4
    printf "ETM Lock Status: 0x%08x\n", $lock_status
    
    if ($lock_status & 0x1) == 0
        printf "✓ ETM registers unlocked successfully\n"
    else
        printf "WARNING: ETM may still be locked\n"
    end
    
    # Step 6: Test ETM register access
    printf "\nStep 6: Testing ETM register access...\n"
    
    # Try to read ETM configuration register
    set $etm_config = {long}0x50000010
    printf "ETM Configuration: 0x%08x\n", $etm_config
    
    # Try to write to a safe register (programming control)
    set $old_prgctrl = {long}0x50000004
    printf "Current ETM PRGCTRL: 0x%08x\n", $old_prgctrl
    
    # Try to write 0 (stop tracing)
    set {long}0x50000004 = 0
    set $new_prgctrl = {long}0x50000004
    printf "After write ETM PRGCTRL: 0x%08x\n", $new_prgctrl
    
    if $new_prgctrl == 0
        printf "✓ ETM register write successful\n"
        set $etm_accessible = 1
    else
        printf "ERROR: ETM register write failed\n"
        set $etm_accessible = 0
    end
    
    printf "\n========================================\n"
    if $etm_accessible == 1
        printf "ETM SETUP COMPLETE - READY FOR TRACING\n"
    else
        printf "ETM SETUP FAILED - DEBUGGING REQUIRED\n"
    end
    printf "========================================\n\n"
    
    # Return status
    set $etm_setup_status = $etm_accessible
end

# Enhanced trace start with better error handling
define etm_enhanced_start
    printf "\n========================================\n"
    printf "STARTING ENHANCED ETM TRACE\n"
    printf "========================================\n\n"
    
    # First run enhanced setup
    etm_enhanced_setup
    
    if $etm_setup_status == 0
        printf "ERROR: Cannot start tracing - setup failed\n"
        printf "Run 'etm_debug_registers' for detailed analysis\n"
        return
    end
    
    # Load the original trace script
    printf "Loading czietz trace system...\n"
    source Blinky_Pico2_dual_core_nosdk/etm-scripts/trace.gdb
    
    # Configure for our buffer
    printf "Configuring trace buffer...\n"
    trc_setup etm_buffer 8192 12 0 1 1 0
    
    # Set trace output directory
    set $trace_output_dir = "Output/"
    printf "Trace files will be saved to: %s\n", $trace_output_dir
    
    # Start tracing
    printf "Starting trace capture...\n"
    trc_start
    
    printf "✓ ETM tracing started successfully\n"
    printf "Continue execution with 'c' command\n"
    printf "========================================\n\n"
end

# Debug helper to analyze register access issues
define etm_debug_registers
    printf "\n========================================\n"
    printf "ETM REGISTER ACCESS DEBUGGING\n"
    printf "========================================\n\n"
    
    printf "=== POWER MANAGEMENT ===\n"
    printf "PSM_FRCE_ON (0x40018000): 0x%08x\n", {long}0x40018000
    printf "PSM_DONE    (0x4001800C): 0x%08x\n", {long}0x4001800C
    
    printf "\n=== RESET CONTROL ===\n"
    printf "RESETS_RESET (0x40020000): 0x%08x\n", {long}0x40020000
    printf "RESETS_DONE  (0x40020008): 0x%08x\n", {long}0x40020008
    
    printf "\n=== CLOCK CONTROL ===\n"
    printf "CLK_SYS_CTRL  (0x4001003C): 0x%08x\n", {long}0x4001003C
    printf "CLK_PERI_CTRL (0x40010048): 0x%08x\n", {long}0x40010048
    
    printf "\n=== DEBUG AUTHENTICATION ===\n"
    printf "DHCSR         (0xE000EDF0): 0x%08x\n", {long}0xE000EDF0
    printf "DBGAUTHSTATUS (0xE000EFB8): 0x%08x\n", {long}0xE000EFB8
    
    printf "\n=== ETM REGISTERS ===\n"
    printf "ETM Lock Access (0x50000FB0): Attempting write...\n"
    set {long}0x50000FB0 = 0xC5ACCE55
    printf "ETM Lock Status (0x50000FB4): 0x%08x\n", {long}0x50000FB4
    
    printf "\n=== ETM CORE REGISTERS ===\n"
    printf "ETM PRGCTRL (0x50000004): 0x%08x\n", {long}0x50000004
    printf "ETM STATUS  (0x5000000C): 0x%08x\n", {long}0x5000000C
    printf "ETM CONFIG  (0x50000010): 0x%08x\n", {long}0x50000010
    
    printf "\n=== CORESIGHT TRACE ===\n"
    printf "Coresight Access (0x40060058): 0x%08x\n", {long}0x40060058
    
    printf "\n========================================\n"
    printf "ANALYSIS COMPLETE\n"
    printf "========================================\n\n"
end

# Quick test function
define etm_quick_test
    printf "Quick ETM accessibility test...\n"
    
    # Test basic register read
    set $test1 = {long}0x50000FB4
    printf "ETM Lock Status: 0x%08x\n", $test1
    
    # Test unlock
    set {long}0x50000FB0 = 0xC5ACCE55
    set $test2 = {long}0x50000FB4
    printf "After unlock: 0x%08x\n", $test2
    
    # Test register write
    set {long}0x50000004 = 0
    set $test3 = {long}0x50000004
    printf "PRGCTRL write test: 0x%08x\n", $test3
    
    if $test3 == 0
        printf "✓ ETM registers accessible\n"
    else
        printf "✗ ETM register access failed\n"
    end
end

printf "\n============================================\n"
printf "ENHANCED ETM COMMANDS LOADED\n"
printf "============================================\n"
printf "etm_enhanced_start    - Complete setup and start\n"
printf "etm_enhanced_setup    - Setup with error checking\n"
printf "etm_debug_registers   - Debug register access\n"
printf "etm_quick_test        - Quick accessibility test\n"
printf "============================================\n\n"
printf "RECOMMENDED USAGE:\n"
printf "1. Set breakpoint: b main\n"
printf "2. Run program: run\n"
printf "3. Setup ETM: etm_enhanced_start\n"
printf "4. Continue: c\n"
# Enhanced trace save with organized file management
define etm_save_organized
    dont-repeat
    
    printf "\n========================================\n"
    printf "SAVING ETM TRACE DATA\n"
    printf "========================================\n\n"
    
    # Create trace directory if it doesn't exist
    shell mkdir -p trace
    
    # Save trace using original trc_save function
    trc_save trace/etm_trace.bin
    
    printf "✓ ETM trace saved as: trace/etm_trace.bin\n\n"
    
    printf "========================================\n"
    printf "NEXT STEPS FOR ANALYSIS:\n"
    printf "========================================\n"
    printf "1. Navigate to trace directory:\n"
    printf "   cd trace/\n\n"
    printf "2. Decode trace to readable format:\n"
    printf "   ../Tools/ptm2human/ptm2human -e -i etm_trace.bin > etm_trace_readable.txt\n\n"
    printf "3. View decoded trace:\n"
    printf "   head -50 etm_trace_readable.txt\n\n"
    printf "4. Search for demo functions:\n"
    printf "   grep -i 'demo_function' etm_trace_readable.txt\n"
    printf "========================================\n\n"
end

printf "5. Save trace: etm_save_organized\n"
printf "============================================\n\n"

# RP2350 ETM Tracing - Complete Debug Workflow

## Prerequisites
- ✅ .uf2 file flashed to Pico 2
- ✅ Raspberry Pi Debug Probe connected
- ✅ VSCode with Cortex-Debug extension
- ✅ OpenOCD server running

## Step-by-Step Debugging Workflow

### 1. Start Debug Session
```
Press F5 in VSCode
```
- This loads your firmware and connects to the target
- Debugger will stop at `main()` function

### 2. Initialize ETM Hardware
In the **Debug Console**, run:
```gdb
etm_enhanced_start
```
**What this does:**
- Loads the enhanced trace system
- Configures ETM hardware with proper initialization
- Sets up trace buffer (8KB in SRAM4)
- Starts ETM tracing
- Shows success confirmation

### 3. Execute Your Code
```gdb
c
```
- Continues execution to run your demo functions
- ETM captures instruction trace data
- Let it run for a few seconds to capture meaningful trace

### 4. Stop and Save Trace
```gdb
Ctrl+C
etm_save_organized
```
**What this does:**
- Stops execution
- Creates `trace/` directory
- Saves ETM data as `trace/etm_trace.bin`
- Shows next steps for analysis

### 5. Analyze Trace Data
Open terminal and navigate to trace directory:
```bash
cd "C:/Users/tabre/Desktop/Pico 2/Blinky_Pico2_dual_core_nosdk/trace"
```

### 6. Generate TARMAC Format
```bash
python ../Tools/etm_raw_analyzer.py etm_trace.bin --tarmac --viewer
```
**Output files created:**
- `etm_trace_tarmac.txt` - TARMAC format trace
- Console shows analysis and preview

### 7. View Results
```bash
# View TARMAC trace
head -20 etm_trace_tarmac.txt

# Search for specific patterns
grep "branch" etm_trace_tarmac.txt
grep "0x2000" etm_trace_tarmac.txt
```

## Expected TARMAC Output Format
```
# TARMAC Format ETM Trace - Educational Demo
# Generated from RP2350 ETM raw trace data
# Format: cycle instruction_address opcode disassembly
#
       0 20000000 e92d4800 <raw:0xe92d4800>
       1 20000004 f7ff0001 b 0x00000004
       2 20000008 46204611 mov r1, #0x20
       3 2000000c e8bd8800 ldr r8, [sp]
```

## Troubleshooting

### If ETM initialization fails:
```gdb
etm_debug_registers
```
- Shows register access status
- Helps identify hardware issues

### If trace file is empty:
- Check if code actually executed (`c` command)
- Verify ETM hardware initialization succeeded
- Try shorter execution time

### If TARMAC output looks wrong:
- This is educational demonstration format
- Real instruction decoding requires symbol table
- Focus on the process, not perfect accuracy

## Educational Value
Students learn:
- Professional ETM hardware initialization
- Systematic debugging methodology
- Trace data capture and analysis
- TARMAC format understanding
- Raw data interpretation skills

## Quick Reference Commands
```gdb
# Essential GDB commands
etm_enhanced_start    # Initialize and start ETM
c                     # Continue execution
Ctrl+C               # Stop execution
etm_save_organized   # Save trace to organized location
```

```bash
# Analysis commands
python ../Tools/etm_raw_analyzer.py etm_trace.bin --tarmac --viewer
head -20 etm_trace_tarmac.txt
grep "branch" etm_trace_tarmac.txt
```

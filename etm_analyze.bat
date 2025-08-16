@echo off
REM ETM Trace Analysis Script for Windows
REM This script ensures proper working directory and paths

cd /d "c:\Users\tabre\Desktop\Pico 2\Blinky_Pico2_dual_core_nosdk"

REM Create trace directory if it doesn't exist
if not exist "trace" mkdir "trace"

REM Always copy fresh trace file from workspace root (GDB saves there)
if exist "..\trace\etm_trace.bin" (
    echo Copying fresh trace file from workspace root...
    copy "..\trace\etm_trace.bin" "trace\etm_trace.bin"
) else (
    if not exist "trace\etm_trace.bin" (
        echo Error: etm_trace.bin not found in either location
        echo Please run etm_save first to capture trace data
        exit /b 1
    ) else (
        echo Using existing trace file in project directory...
    )
)

echo Decoding ETM trace...
REM Use the trace file that was copied to project directory
Tools\ptm2human\ptm2human.exe -e -i trace\etm_trace.bin > trace\etm_ptm2human.txt 2>&1

REM Check if decoder produced output (ptm2human returns error code but still works)
if not exist "trace\etm_ptm2human.txt" (
    echo Error: No decoder output file created
    exit /b 1
)

REM Check if output file has reasonable content (more than just error messages)
for %%A in (trace\etm_ptm2human.txt) do set size=%%~zA
if %size% LSS 1000 (
    echo Warning: Decoder output is very small (%size% bytes^), but continuing...
) else (
    echo Decoder output: %size% bytes
)

echo Creating annotated trace...
python map_trace_addresses.py trace\etm_ptm2human.txt
if %errorlevel% neq 0 (
    echo Error: Failed to annotate trace with Python script
    exit /b 1
)

echo Analysis complete!
echo Files created in trace\ folder:
echo    - trace\etm_trace.bin (raw ETM data)
echo    - trace\etm_ptm2human.txt (decoded trace)
echo    - trace\etm_ptm2human_annotated.txt (with C source mapping)

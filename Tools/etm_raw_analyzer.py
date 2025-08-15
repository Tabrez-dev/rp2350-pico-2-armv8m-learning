#!/usr/bin/env python3
"""
RP2350 ETM Raw Trace Analyzer
Educational tool for analyzing raw ETM trace data when standard decoders fail
"""

import sys
import struct
import argparse

def analyze_raw_trace(filename):
    """Analyze raw ETM trace data and extract basic information"""
    
    print(f"Analyzing raw ETM trace: {filename}")
    print("=" * 60)
    
    try:
        with open(filename, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: File {filename} not found")
        return
    
    print(f"File size: {len(data)} bytes ({len(data)/1024:.1f} KB)")
    
    if len(data) == 0:
        print("Error: Empty trace file")
        return
    
    # Check for common ETM synchronization patterns
    sync_patterns = [
        b'\x00\x00\x00\x00\x00\x00\x00\x80',  # ETM sync pattern
        b'\x7f\xff\xff\xff',                    # Common sync
        b'\x00\x80',                            # Short sync
    ]
    
    print("\nSynchronization Pattern Analysis:")
    print("-" * 40)
    
    for i, pattern in enumerate(sync_patterns):
        count = data.count(pattern)
        if count > 0:
            print(f"Pattern {i+1} ({pattern.hex()}): {count} occurrences")
            # Find first occurrence
            pos = data.find(pattern)
            if pos >= 0:
                print(f"  First occurrence at offset: 0x{pos:08x}")
    
    # Analyze data distribution
    print("\nData Distribution Analysis:")
    print("-" * 40)
    
    zero_bytes = data.count(0)
    non_zero_bytes = len(data) - zero_bytes
    
    print(f"Zero bytes: {zero_bytes} ({zero_bytes/len(data)*100:.1f}%)")
    print(f"Non-zero bytes: {non_zero_bytes} ({non_zero_bytes/len(data)*100:.1f}%)")
    
    # Show first 64 bytes as hex dump
    print("\nFirst 64 bytes (hex dump):")
    print("-" * 40)
    
    for i in range(0, min(64, len(data)), 16):
        hex_part = ' '.join(f'{b:02x}' for b in data[i:i+16])
        ascii_part = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data[i:i+16])
        print(f"{i:08x}: {hex_part:<48} |{ascii_part}|")
    
    # Check for potential trace data patterns
    print("\nPotential ETM Packet Analysis:")
    print("-" * 40)
    
    # Look for common ETM packet headers
    packet_types = {
        0x00: "Async packet",
        0x01: "Trace info",
        0x02: "Timestamp",
        0x04: "Exception",
        0x08: "Address",
        0x10: "Context ID",
        0x20: "Data sync",
        0x40: "Instruction",
        0x80: "Sync packet"
    }
    
    byte_counts = {}
    for b in data:
        byte_counts[b] = byte_counts.get(b, 0) + 1
    
    # Show most common bytes
    most_common = sorted(byte_counts.items(), key=lambda x: x[1], reverse=True)[:10]
    
    print("Most common bytes:")
    for byte_val, count in most_common:
        percentage = count / len(data) * 100
        packet_type = packet_types.get(byte_val & 0xF0, "Unknown")
        print(f"  0x{byte_val:02x}: {count:6d} times ({percentage:5.1f}%) - {packet_type}")

def create_tarmac_format(filename, output_filename=None):
    """Create TARMAC format trace output for educational purposes"""
    
    if output_filename is None:
        output_filename = filename.replace('.bin', '_tarmac.txt')
    
    print(f"\nGenerating TARMAC format trace: {output_filename}")
    print("=" * 60)
    
    try:
        with open(filename, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: File {filename} not found")
        return
    
    tarmac_lines = []
    tarmac_lines.append("# TARMAC Format ETM Trace - Educational Demo")
    tarmac_lines.append("# Generated from RP2350 ETM raw trace data")
    tarmac_lines.append("# Format: cycle instruction_address opcode disassembly")
    tarmac_lines.append("#")
    
    cycle_count = 0
    instruction_count = 0
    
    # Analyze data in 4-byte chunks looking for potential instructions
    for i in range(0, len(data) - 4, 4):
        try:
            # Read potential instruction word
            instr = struct.unpack('<I', data[i:i+4])[0]
            
            # Skip obvious padding/sync patterns
            if instr == 0x00000000 or instr == 0xFFFFFFFF:
                continue
                
            # Generate simulated TARMAC entry for educational purposes
            # Note: This is a simplified demonstration - real TARMAC requires full decode
            
            # Simulate instruction address (educational - not real addresses)
            addr = 0x20000000 + (instruction_count * 4)
            
            # Basic instruction type detection for demo
            instr_type = "unknown"
            disasm = f"<raw:0x{instr:08x}>"
            
            # Simple pattern matching for common ARM instructions
            if (instr & 0x0F000000) == 0x0A000000:  # Branch
                instr_type = "branch"
                target = (instr & 0x00FFFFFF) << 2
                disasm = f"b 0x{target:08x}"
            elif (instr & 0x0FE00000) == 0x02000000:  # Data processing
                instr_type = "data_proc"
                disasm = f"mov r{(instr>>12)&0xF}, #0x{instr&0xFF:02x}"
            elif (instr & 0x0C000000) == 0x04000000:  # Load/Store
                instr_type = "mem_access"
                disasm = f"ldr r{(instr>>12)&0xF}, [r{(instr>>16)&0xF}]"
            
            # Generate TARMAC line
            tarmac_line = f"{cycle_count:8d} {addr:08x} {instr:08x} {disasm}"
            tarmac_lines.append(tarmac_line)
            
            cycle_count += 1
            instruction_count += 1
            
            # Limit output for demo
            if instruction_count >= 50:
                break
                
        except struct.error:
            continue
    
    # Write TARMAC file
    try:
        with open(output_filename, 'w') as f:
            f.write('\n'.join(tarmac_lines))
        
        print(f"✓ TARMAC format trace saved: {output_filename}")
        print(f"✓ Generated {instruction_count} instruction entries")
        
        # Show preview
        print("\nTARMAC Preview (first 10 lines):")
        print("-" * 50)
        for line in tarmac_lines[4:14]:  # Skip header comments
            print(line)
            
    except Exception as e:
        print(f"Error writing TARMAC file: {e}")

def create_simple_trace_viewer(filename):
    """Create a simple educational trace viewer"""
    
    print(f"\nSimple ETM Trace Viewer for: {filename}")
    print("=" * 60)
    
    try:
        with open(filename, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: File {filename} not found")
        return
    
    # Look for potential instruction trace patterns
    print("Searching for potential instruction sequences...")
    print("-" * 50)
    
    # Simple pattern matching for ARM instruction traces
    instruction_count = 0
    
    for i in range(0, len(data) - 4, 4):
        # Read 4 bytes as potential ARM instruction
        try:
            instr = struct.unpack('<I', data[i:i+4])[0]
            
            # Check for common ARM instruction patterns
            if (instr & 0xF0000000) != 0xF0000000:  # Not undefined
                # Check for branch instructions (common in traces)
                if (instr & 0x0F000000) == 0x0A000000:  # Branch
                    print(f"  Potential branch at 0x{i:08x}: 0x{instr:08x}")
                    instruction_count += 1
                    if instruction_count >= 10:  # Limit output
                        break
                        
        except struct.error:
            continue
    
    if instruction_count == 0:
        print("  No clear instruction patterns found")
        print("  This suggests the trace format may need specific decoding")

def main():
    parser = argparse.ArgumentParser(description='Analyze raw RP2350 ETM trace data')
    parser.add_argument('filename', help='ETM trace file to analyze')
    parser.add_argument('--viewer', action='store_true', help='Enable simple trace viewer')
    parser.add_argument('--tarmac', action='store_true', help='Generate TARMAC format output')
    parser.add_argument('--output', '-o', help='Output filename for TARMAC format')
    
    args = parser.parse_args()
    
    analyze_raw_trace(args.filename)
    
    if args.viewer:
        create_simple_trace_viewer(args.filename)
    
    if args.tarmac:
        create_tarmac_format(args.filename, args.output)
    
    print("\n" + "=" * 60)
    print("EDUCATIONAL NOTES:")
    print("=" * 60)
    print("• ETM traces contain compressed instruction flow data")
    print("• Synchronization patterns help decoders align with data stream")
    print("• High percentage of zeros may indicate buffer padding")
    print("• TARMAC format shows: cycle_count address opcode disassembly")
    print("• Real ETM decoding requires knowledge of:")
    print("  - Target CPU architecture (ARM Cortex-M33)")
    print("  - ETM configuration registers")
    print("  - Instruction set being traced")
    print("  - Memory map and symbol table")
    print("=" * 60)

if __name__ == '__main__':
    main()

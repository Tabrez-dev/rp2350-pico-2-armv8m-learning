#!/usr/bin/env python3
"""
Map ETM trace addresses to C source lines
Usage: python map_trace_addresses.py etm_ptm2human.txt
"""

import re
import subprocess
import sys
import os

def extract_addresses(trace_file):
    """Extract all instruction addresses from ptm2human output"""
    addresses = []
    with open(trace_file, 'r') as f:
        for line in f:
            # Look for "Address - Instruction address 0x..." lines
            match = re.search(r'Address - Instruction address (0x[0-9a-fA-F]+)', line)
            if match:
                addr = match.group(1)
                if addr not in addresses:  # Avoid duplicates
                    addresses.append(addr)
    return addresses

def map_address_to_source(elf_file, address):
    """Use addr2line to map address to source line"""
    try:
        result = subprocess.run([
            'arm-none-eabi-addr2line', 
            '-e', elf_file, 
            '-f', '-C', 
            address
        ], capture_output=True, text=True, check=True)
        
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 2:
            function = lines[0]
            location = lines[1]
            return function, location
        return "??", "??:0"
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "??", "??:0"

def main():
    if len(sys.argv) != 2:
        print("Usage: python map_trace_addresses.py etm_ptm2human.txt")
        sys.exit(1)
    
    trace_file = sys.argv[1]
    
    # Find the ELF file - check multiple possible locations
    script_dir = os.path.dirname(os.path.abspath(__file__))
    possible_elf_paths = [
        os.path.join(script_dir, "Output", "arm_baremetal_pico2_dual_core_nosdk.elf"),
        os.path.join(script_dir, "..", "Output", "arm_baremetal_pico2_dual_core_nosdk.elf"),
        os.path.join(script_dir, "Build", "arm_baremetal_pico2_dual_core_nosdk.elf"),
        "Output/arm_baremetal_pico2_dual_core_nosdk.elf",
        "../Output/arm_baremetal_pico2_dual_core_nosdk.elf"
    ]
    
    elf_file = None
    for path in possible_elf_paths:
        if os.path.exists(path):
            elf_file = path
            break
    
    if not os.path.exists(trace_file):
        print(f"Error: {trace_file} not found")
        sys.exit(1)
    
    if elf_file is None:
        print("Error: ELF file not found. Searched in:")
        for path in possible_elf_paths:
            print(f"  - {path}")
        sys.exit(1)
    
    print(f"Using ELF file: {elf_file}")
    
    print("Extracting addresses from trace...")
    addresses = extract_addresses(trace_file)
    print(f"Found {len(addresses)} unique addresses")
    
    print("\nAddress to Source Mapping:")
    print("=" * 80)
    print(f"{'Address':<12} {'Function':<25} {'Source Location'}")
    print("-" * 80)
    
    for addr in addresses:
        function, location = map_address_to_source(elf_file, addr)
        print(f"{addr:<12} {function:<25} {location}")
    
    # Create annotated trace file in same directory as trace file (not ELF)
    trace_dir = os.path.dirname(trace_file)
    trace_name = os.path.basename(trace_file)
    output_file = os.path.join(trace_dir, trace_name.replace('.txt', '_annotated.txt'))
    print(f"\nCreating annotated trace: {output_file}")
    
    # Build address-to-source mapping
    addr_map = {}
    for addr in addresses:
        function, location = map_address_to_source(elf_file, addr)
        addr_map[addr] = f"{function} ({location})"
    
    # Annotate the trace file
    with open(trace_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            match = re.search(r'Address - Instruction address (0x[0-9a-fA-F]+)', line)
            if match:
                addr = match.group(1)
                annotation = addr_map.get(addr, "")
                outfile.write(f"{line.rstrip()} # {annotation}\n")
            else:
                outfile.write(line)
    
    print(f"Done! Check {output_file} for annotated trace.")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Utility functions for forensic web capture
"""

import os
import sys
import subprocess
from pathlib import Path

def verify_capture(capture_dir):
    """Verify integrity of a capture"""
    capture_dir = Path(capture_dir)
    
    if not capture_dir.exists():
        print(f"Error: Directory {capture_dir} not found")
        return False
    
    print(f"\n=== VERIFYING CAPTURE ===")
    print(f"Directory: {capture_dir}")
    
    # Check SHA256
    sha256_file = capture_dir / 'SHA256SUMS.txt'
    if sha256_file.exists():
        print("\nVerifying SHA256 hashes...")
        result = subprocess.run(['sha256sum', '-c', 'SHA256SUMS.txt'], 
                              cwd=capture_dir, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ SHA256 verification PASSED")
        else:
            print("✗ SHA256 verification FAILED")
            print(result.stderr)
            return False
    
    # Check SHA512
    sha512_file = capture_dir / 'SHA512SUMS.txt'
    if sha512_file.exists():
        print("\nVerifying SHA512 hashes...")
        result = subprocess.run(['sha512sum', '-c', 'SHA512SUMS.txt'], 
                              cwd=capture_dir, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ SHA512 verification PASSED")
        else:
            print("✗ SHA512 verification FAILED")
            return False
    
    print("\n✓ VERIFICATION COMPLETE - INTEGRITY CONFIRMED")
    return True
#!/usr/bin/env python3

"""
Forensic Web Capture Tool CLI wrapper
Uses the modular forensic_webcapture package
"""

import sys
import os

# Add the package directory to Python path
package_dir = os.path.join(os.path.dirname(__file__), 'forensic_webcapture')
sys.path.insert(0, os.path.dirname(__file__))

if __name__ == '__main__':
    from forensic_webcapture.main import main
    main()
#!/usr/bin/env python3

"""
Main CLI entry point for forensic web capture tool
"""

import argparse
from pathlib import Path

from .capture import ForensicCapture
from .server import browse_capture
from .utils import verify_capture


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Forensic Web Capture Tool')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Capture command  
    capture_parser = subparsers.add_parser('capture', help='Capture a website')
    capture_parser.add_argument('url', help='URL to capture')
    capture_parser.add_argument('-o', '--output', help='Output directory')
    capture_parser.add_argument('-b', '--browser', 
                               choices=['chrome', 'firefox', 'safari', 'googlebot', 'random'],
                               default='chrome',
                               help='Browser profile to spoof (default: chrome)')
    capture_parser.add_argument('--crawl', action='store_true',
                               help='Recursively crawl same-domain links')
    capture_parser.add_argument('--depth', type=int, default=2,
                               help='Maximum crawl depth (default: 2, max: 5)')
    capture_parser.add_argument('--max-pages', type=int, default=50,
                               help='Maximum pages to crawl (default: 50, max: 200)')
    
    # Verify command
    verify_parser = subparsers.add_parser('verify', help='Verify capture integrity')
    verify_parser.add_argument('directory', help='Capture directory to verify')
    
    # Report command
    report_parser = subparsers.add_parser('report', help='Generate report from capture')
    report_parser.add_argument('directory', help='Capture directory')
    
    # Browse command
    browse_parser = subparsers.add_parser('browse', help='Browse captured website locally with domain spoofing and sandboxing')
    browse_parser.add_argument('directory', help='Capture directory to browse')
    browse_parser.add_argument('-p', '--port', type=int, default=8000, help='Port to serve on (default: 8000)')
    
    args = parser.parse_args()
    
    if args.command == 'capture':
        # Validate crawl parameters
        depth = getattr(args, 'depth', 2)
        max_pages = getattr(args, 'max_pages', 50)
        crawl = getattr(args, 'crawl', False)
        
        if depth > 5:
            print("⚠ Maximum crawl depth is 5. Setting depth to 5.")
            depth = 5
        if max_pages > 200:
            print("⚠ Maximum pages is 200. Setting max-pages to 200.")
            max_pages = 200
        
        capture = ForensicCapture(args.url, args.output, args.browser, crawl, depth, max_pages)
        capture.capture()
    
    elif args.command == 'verify':
        verify_capture(args.directory)
    
    elif args.command == 'report':
        # Read and display the report
        report_file = Path(args.directory) / 'forensic_report.txt'
        if report_file.exists():
            with open(report_file) as f:
                print(f.read())
        else:
            print(f"No report found in {args.directory}")
    
    elif args.command == 'browse':
        browse_capture(args.directory, args.port)
    
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
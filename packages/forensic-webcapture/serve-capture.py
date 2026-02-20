#!/usr/bin/env python3

"""
Local Web Server for Forensic Captures
Serves captured websites locally for browsing and analysis
"""

import os
import sys
import argparse
import mimetypes
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
import webbrowser
import json

class ForensicCaptureHandler(SimpleHTTPRequestHandler):
    """Custom handler for serving forensic captures"""
    
    def __init__(self, *args, capture_dir=None, **kwargs):
        self.capture_dir = Path(capture_dir) if capture_dir else Path('.')
        self.response_headers = self._load_response_headers()
        super().__init__(*args, directory=str(self.capture_dir), **kwargs)
    
    def _load_response_headers(self):
        """Load original response headers from capture"""
        headers_file = self.capture_dir / 'response_headers.json'
        if headers_file.exists():
            try:
                with open(headers_file) as f:
                    return json.load(f)
            except:
                pass
        return {}
    
    def do_GET(self):
        """Handle GET requests with forensic capture context"""
        # Serve the main page.html as index
        if self.path == '/' or self.path == '/index.html':
            self.path = '/page.html'
        
        # Check if this is the main HTML page and we have original headers
        if self.path == '/page.html' and self.response_headers:
            self._serve_compressed_html()
        else:
            super().do_GET()
    
    def _serve_compressed_html(self):
        """Serve the HTML exactly as captured with original compression"""
        html_file = self.capture_dir / 'page.html'
        
        if not html_file.exists():
            self.send_error(404, "File not found")
            return
        
        # Send response with original headers
        self.send_response(200)
        
        # Copy relevant headers from original response
        content_type = self.response_headers.get('content-type', 'text/html; charset=utf-8')
        self.send_header('Content-Type', content_type)
        
        # Preserve original compression - serve exactly as captured
        if 'content-encoding' in self.response_headers:
            encoding = self.response_headers['content-encoding']
            self.send_header('Content-Encoding', encoding)
        
        # Get file size
        file_size = html_file.stat().st_size
        self.send_header('Content-Length', str(file_size))
        
        # Add forensic headers  
        self.send_header('X-Forensic-Capture', 'true')
        self.send_header('X-Frame-Options', 'SAMEORIGIN')
        self.send_header('X-Original-Date', self.response_headers.get('Date', 'Unknown'))
        
        self.end_headers()
        
        # Send the raw content exactly as captured (compressed)
        with open(html_file, 'rb') as f:
            self.wfile.write(f.read())
    
    def end_headers(self):
        """Add custom headers for forensic context"""
        if not hasattr(self, '_headers_sent'):
            self.send_header('X-Forensic-Capture', 'true')
            self.send_header('X-Frame-Options', 'SAMEORIGIN')
        super().end_headers()
    
    def log_message(self, format, *args):
        """Custom logging for forensic server"""
        print(f"[FORENSIC SERVER] {format % args}")

def create_handler_class(capture_dir):
    """Create a handler class with the capture directory bound"""
    class BoundHandler(ForensicCaptureHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, capture_dir=capture_dir, **kwargs)
    return BoundHandler

def validate_capture_directory(capture_dir):
    """Validate that the directory contains a forensic capture"""
    capture_path = Path(capture_dir)
    
    if not capture_path.exists():
        print(f"Error: Directory {capture_dir} does not exist")
        return False
    
    # Check for required forensic files
    required_files = ['page.html', 'capture_metadata.json', 'SHA256SUMS.txt']
    missing_files = []
    
    for required_file in required_files:
        if not (capture_path / required_file).exists():
            missing_files.append(required_file)
    
    if missing_files:
        print(f"Error: Directory {capture_dir} appears to not be a forensic capture.")
        print(f"Missing required files: {', '.join(missing_files)}")
        return False
    
    return True

def show_capture_info(capture_dir):
    """Display information about the forensic capture"""
    capture_path = Path(capture_dir)
    
    # Load metadata
    metadata_file = capture_path / 'capture_metadata.json'
    if metadata_file.exists():
        with open(metadata_file) as f:
            metadata = json.load(f)
        
        print("\n" + "="*60)
        print("FORENSIC CAPTURE INFORMATION")
        print("="*60)
        print(f"Original URL: {metadata.get('url', 'Unknown')}")
        print(f"Capture Date: {metadata.get('capture_time_local', 'Unknown')}")
        print(f"Capture ID: {metadata.get('capture_id', 'Unknown')}")
        print(f"Browser Profile: {metadata.get('browser_profile', 'Unknown')}")
        
        if 'tls_certificate' in metadata:
            cert = metadata['tls_certificate']
            print(f"TLS Certificate: {cert.get('subject', 'Unknown')}")
            print(f"Certificate Valid: {cert.get('is_valid', 'Unknown')}")
        
        print(f"Files in capture: {len(list(capture_path.glob('**/*')))}")
        print("="*60)
    
    # Check integrity
    sha256_file = capture_path / 'SHA256SUMS.txt'
    if sha256_file.exists():
        print("\nVerifying capture integrity...")
        import subprocess
        try:
            result = subprocess.run(['sha256sum', '-c', 'SHA256SUMS.txt'], 
                                  cwd=capture_path, capture_output=True, text=True)
            if result.returncode == 0:
                print("✓ Integrity verification PASSED")
            else:
                print("✗ Integrity verification FAILED")
                print(result.stderr)
        except FileNotFoundError:
            print("⚠ sha256sum not available for verification")

def fix_html_paths(capture_dir):
    """Fix relative paths in HTML to work with local server"""
    capture_path = Path(capture_dir)
    html_file = capture_path / 'page.html'
    
    if not html_file.exists():
        return
    
    try:
        # Read the HTML content
        with open(html_file, 'r', encoding='utf-8', errors='ignore') as f:
            html_content = f.read()
        
        # Create a browsable version
        browsable_file = capture_path / 'index.html'
        
        # Add forensic banner
        forensic_banner = '''
        <div style="position: fixed; top: 0; left: 0; right: 0; background: #ffeb3b; color: #000; padding: 10px; z-index: 10000; border-bottom: 3px solid #f57f17; font-family: monospace;">
            <strong>🔍 FORENSIC CAPTURE</strong> - This is a preserved copy of a website captured for legal/forensic purposes. 
            Original timestamp and integrity verified.
            <button onclick="this.parentElement.style.display='none'" style="float: right; background: #f57f17; border: none; padding: 5px 10px; cursor: pointer;">×</button>
        </div>
        <div style="margin-top: 60px;">
        '''
        
        # Insert banner after <body> tag
        if '<body' in html_content:
            html_content = html_content.replace('<body', f'{forensic_banner}<body', 1)
            html_content += '</div>'
        else:
            html_content = forensic_banner + html_content + '</div>'
        
        # Save browsable version
        with open(browsable_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"Created browsable version: {browsable_file}")
        
    except Exception as e:
        print(f"Warning: Could not process HTML file: {e}")

def main():
    parser = argparse.ArgumentParser(
        description='Local web server for browsing forensic web captures'
    )
    parser.add_argument('capture_dir', 
                       help='Directory containing forensic capture')
    parser.add_argument('-p', '--port', type=int, default=8000,
                       help='Port to serve on (default: 8000)')
    parser.add_argument('--no-browser', action='store_true',
                       help='Don\'t automatically open browser')
    parser.add_argument('--info-only', action='store_true',
                       help='Show capture info and exit')
    
    args = parser.parse_args()
    
    # Validate capture directory
    if not validate_capture_directory(args.capture_dir):
        sys.exit(1)
    
    # Show capture information
    show_capture_info(args.capture_dir)
    
    if args.info_only:
        sys.exit(0)
    
    # Prepare HTML for browsing
    fix_html_paths(args.capture_dir)
    
    # Start server
    handler_class = create_handler_class(args.capture_dir)
    
    try:
        with HTTPServer(('localhost', args.port), handler_class) as httpd:
            capture_path = Path(args.capture_dir).resolve()
            url = f"http://localhost:{args.port}"
            
            print(f"\n🌐 Serving forensic capture from: {capture_path}")
            print(f"📍 Local URL: {url}")
            print(f"🔍 Forensic files available at: {url}/forensic_report.txt")
            print(f"🛡️ Certificate details: {url}/certificates/")
            print("\nPress Ctrl+C to stop the server")
            
            # Open browser if requested
            if not args.no_browser:
                print(f"\n🔗 Opening browser to {url}...")
                webbrowser.open(url)
            
            # Serve forever
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"\n❌ Port {args.port} is already in use. Try a different port with -p")
        else:
            print(f"\n❌ Server error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
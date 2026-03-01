#!/usr/bin/env python3
"""
HTTP server implementation for browsing forensic captures
"""

import json
import subprocess
import shutil
import webbrowser
from pathlib import Path
from urllib.parse import urlparse
from http.server import HTTPServer, SimpleHTTPRequestHandler

def browse_capture(capture_dir, port=8000):
    """Browse a forensic capture using HTTP server with rewritten asset URLs"""
    capture_dir = Path(capture_dir)
    
    if not capture_dir.exists():
        print(f"Error: Directory {capture_dir} not found")
        return False
    
    # Load metadata to get the original URL
    metadata_file = capture_dir / 'capture_metadata.json'
    original_url = None
    original_domain = None
    
    if metadata_file.exists():
        try:
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
                original_url = metadata.get('url', '')
                parsed_url = urlparse(original_url)
                original_domain = parsed_url.hostname
        except:
            pass
    
    print(f"\n=== BROWSING FORENSIC CAPTURE ===")
    print(f"Directory: {capture_dir}")
    print(f"Port: {port}")
    print("Mode: HTTP server with rewritten asset URLs")
    print("Network isolation: Sandboxed browser with no external access")
    
    # Custom handler to serve from capture directory
    class ForensicHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(capture_dir), **kwargs)
        
        def do_GET(self):
            if self.path == '/' or self.path == '/index.html':
                # Serve the main page
                self.serve_main_page()
            elif self.path == '/crawl_index.html':
                # Serve the crawl navigation index
                self.serve_crawl_index()
            elif self.path.startswith('/pages/'):
                # Serve crawled pages
                self.serve_crawled_page()
            elif self.path.endswith('.html') or (not '.' in self.path.split('/')[-1] and not self.path.startswith('/assets/')):
                # Check if it's a crawled page path (e.g., /sverige/, /app/, /brandstudio/...)
                # This handles both .html files and directory-style paths that might map to crawled pages
                self.serve_crawled_page_by_path()
            else:
                # Serve assets normally
                super().do_GET()
        
        def serve_main_page(self):
            """Serve the main captured page with rewritten asset URLs"""
            html_file = capture_dir / 'page.html'
            
            if not html_file.exists():
                self.send_error(404, "Main page not found")
                return
            
            # Read and rewrite HTML content
            with open(html_file, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Rewrite asset URLs on the fly
            html_content = self.rewrite_html_for_serving(html_content)
            html_bytes = html_content.encode('utf-8')
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(html_bytes)))
            
            # Add forensic headers for identification
            self.send_header('X-Forensic-Capture', 'true')
            
            self.end_headers()
            
            # Send the rewritten HTML content
            self.wfile.write(html_bytes)
        
        def rewrite_html_for_serving(self, html_content):
            """Rewrite HTML to use local asset paths for serving"""
            # Load domain mapping
            mapping_file = capture_dir / 'domain_mapping.json'
            if not mapping_file.exists():
                return html_content
            
            try:
                with open(mapping_file, 'r') as f:
                    domain_mapping = json.load(f)
                
                # Create a set of all available local asset paths
                available_assets = set()
                for domain, assets in domain_mapping.items():
                    for asset in assets:
                        available_assets.add(asset['local_path'])
                
                # Create URL mapping from original to local (with /assets/ prefix for web serving) 
                # AND Handle URL variants with different query parameters using regex replacement
                import re
                from html import unescape
                
                # Build a mapping of base URLs to local paths
                base_url_to_local = {}
                for domain, assets in domain_mapping.items():
                    for asset in assets:
                        original_url = asset['original_url']
                        local_path = '/' + asset['local_path']  # Add leading slash for absolute path
                        
                        # Get base URL without query parameters
                        base_url = original_url.split('?')[0] if '?' in original_url else original_url
                        base_url_to_local[base_url] = local_path
                        
                        # Handle HTML entity encoded URLs for exact matches
                        encoded_url = original_url.replace('&', '&amp;')
                        
                        # Replace exact matches in all common attributes
                        for attr in ['src', 'href', 'data-src', 'data-lazy-src', 'data-original']:
                            # Replace exact matches (for backwards compatibility)
                            html_content = html_content.replace(f'{attr}="{original_url}"', f'{attr}="{local_path}"')
                            html_content = html_content.replace(f'{attr}="{encoded_url}"', f'{attr}="{local_path}"')
                            html_content = html_content.replace(f"{attr}='{original_url}'", f"{attr}='{local_path}'")
                            html_content = html_content.replace(f"{attr}='{encoded_url}'", f"{attr}='{local_path}'")
                        
                        # Replace in srcset attributes (for responsive images)
                        html_content = html_content.replace(f' {original_url} ', f' {local_path} ')
                        html_content = html_content.replace(f' {encoded_url} ', f' {local_path} ')
                        html_content = html_content.replace(f',{original_url} ', f',{local_path} ')
                        html_content = html_content.replace(f',{encoded_url} ', f',{local_path} ')
                        
                        # Replace in CSS url() functions
                        html_content = html_content.replace(f'url("{original_url}")', f'url("{local_path}")')
                        html_content = html_content.replace(f'url("{encoded_url}")', f'url("{local_path}")')
                        html_content = html_content.replace(f"url('{original_url}')", f"url('{local_path}')")
                        html_content = html_content.replace(f"url('{encoded_url}')", f"url('{local_path}')")
                        html_content = html_content.replace(f'url({original_url})', f'url({local_path})')
                
                # Now handle URL variants with different query parameters using regex
                def replace_url_variants(match):
                    """Replace URLs that have the same base but different parameters"""
                    attr_part = match.group(1)  # e.g., 'src="'
                    url_in_html = match.group(2)  # The URL in HTML
                    
                    # Decode HTML entities to normalize for comparison
                    decoded_url = unescape(url_in_html)
                    
                    # Get base URL (without query parameters)
                    base_url = decoded_url.split('?')[0] if '?' in decoded_url else decoded_url
                    
                    # Check if we have a local asset for this base URL
                    if base_url in base_url_to_local:
                        local_path = base_url_to_local[base_url]
                        return f'{attr_part}{local_path}"'
                    
                    # No match found, return original
                    return match.group(0)
                
                # Apply URL variant matching for all attributes
                for attr in ['src', 'href', 'data-src', 'data-lazy-src', 'data-original']:
                    html_content = re.sub(
                        rf'({attr}=")([^"]+)"', 
                        replace_url_variants, 
                        html_content
                    )
                
                # Fix srcset attributes that contain uncaptured URLs
                import re
                
                def fix_srcset(match):
                    srcset_value = match.group(1)
                    # Parse srcset entries (URL + descriptor)
                    entries = []
                    debug_url = "https://static.bonniernews.se/ba/0e0b83c7-a5ea-4a90-84f2-2043e80bcb68.jpeg"
                    
                    for entry in srcset_value.split(','):
                        entry = entry.strip()
                        if ' ' in entry:
                            url = entry.split(' ')[0]
                            descriptor = ' '.join(entry.split(' ')[1:])
                            
                            # Debug logging for the problematic image
                            if debug_url in url:
                                print(f"🔍 DEBUG: Processing srcset URL: {url}")
                            
                            # Check if this URL has a corresponding local asset
                            found_local_path = None
                            for domain, assets in domain_mapping.items():
                                for asset in assets:
                                    # First check for exact URL match
                                    if asset['original_url'] == url:
                                        found_local_path = '/' + asset['local_path']
                                        if debug_url in url:
                                            print(f"✓ DEBUG: Exact match found: {found_local_path}")
                                        break
                                    
                                    # If no exact match, check for same image with different query params
                                    # Extract base filename and parameters
                                    asset_base = asset['original_url'].split('?')[0]
                                    url_base = url.split('?')[0]
                                    
                                    # If same base filename (same image, different params), use the captured version
                                    if asset_base == url_base:
                                        found_local_path = '/' + asset['local_path']
                                        if debug_url in url:
                                            print(f"✓ DEBUG: Base match found - URL: {url_base} -> Asset: {asset_base} -> Path: {found_local_path}")
                                        break
                                
                                if found_local_path:
                                    break
                            
                            # Debug if no match found for our problem image
                            if debug_url in url and not found_local_path:
                                print(f"❌ DEBUG: No match found for {url}")
                                print(f"   URL base: {url.split('?')[0]}")
                                # Show first few available assets for comparison
                                for domain, assets in list(domain_mapping.items())[:2]:
                                    for asset in assets[:3]:
                                        if "bonniernews.se" in asset['original_url']:
                                            print(f"   Available: {asset['original_url'].split('?')[0]}")
                            
                            # If we found a local asset, add it to entries with rewritten URL
                            if found_local_path:
                                entries.append(f"{found_local_path} {descriptor}")
                    
                    # If no valid entries remain, remove srcset entirely
                    if not entries:
                        return ''
                    else:
                        return f'srcset="{", ".join(entries)}"'
                
                # Apply srcset fixing
                html_content = re.sub(r'srcset="([^"]*)"', fix_srcset, html_content)
                
                return html_content
            except Exception as e:
                print(f"Warning: Failed to rewrite HTML for serving: {e}")
                return html_content
        
        def serve_crawl_index(self):
            """Serve the crawl navigation index"""
            index_file = capture_dir / 'crawl_index.html'
            
            if not index_file.exists():
                self.send_error(404, "Crawl index not found")
                return
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            
            # Get file size and set content length
            file_size = index_file.stat().st_size
            self.send_header('Content-Length', str(file_size))
            
            # Add forensic headers for identification
            self.send_header('X-Forensic-Capture', 'true')
            self.send_header('X-Forensic-Crawl-Index', 'true')
            
            self.end_headers()
            
            # Send the index content
            with open(index_file, 'rb') as f:
                self.wfile.write(f.read())
        
        def serve_crawled_page(self):
            """Serve a crawled page from the pages directory with rewritten URLs"""
            # Remove /pages/ prefix from path
            page_path = self.path[7:]  # Remove '/pages/'
            page_file = capture_dir / 'pages' / page_path
            
            if not page_file.exists():
                self.send_error(404, f"Crawled page not found: {page_path}")
                return
            
            # Read and rewrite HTML content
            with open(page_file, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Rewrite asset URLs on the fly (without modifying the file)
            html_content = self.rewrite_html_for_serving(html_content)
            html_bytes = html_content.encode('utf-8')
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(html_bytes)))
            
            # Add forensic headers for identification
            self.send_header('X-Forensic-Capture', 'true')
            self.send_header('X-Forensic-Crawled-Page', 'true')
            
            self.end_headers()
            
            # Send the rewritten HTML content
            self.wfile.write(html_bytes)
        
        def serve_crawled_page_by_path(self):
            """Serve a crawled page by matching its original path"""
            # Try to find a matching crawled page
            pages_dir = capture_dir / 'pages'
            if not pages_dir.exists():
                super().do_GET()
                return
            
            # Look for matching HTML files in pages directory
            request_path = self.path.strip('/').replace('/', '_')
            
            # Try different filename patterns
            possible_files = [
                f"{request_path}.html",
                f"{request_path}_index.html", 
                f"index.html" if request_path == "" else None
            ]
            
            for filename in possible_files:
                if filename:
                    page_file = pages_dir / filename
                    if page_file.exists():
                        print(f"✓ Serving crawled page: {filename}")
                        
                        # Read and rewrite the HTML content
                        with open(page_file, 'r', encoding='utf-8', errors='ignore') as f:
                            html_content = f.read()
                        
                        # Apply HTML rewriting for asset URLs
                        html_content = self.rewrite_html_for_serving(html_content)
                        
                        # Convert to bytes for sending
                        html_bytes = html_content.encode('utf-8')
                        
                        # Send response
                        self.send_response(200)
                        self.send_header('Content-Type', 'text/html; charset=utf-8')
                        self.send_header('Content-Length', str(len(html_bytes)))
                        
                        # Add forensic headers for identification
                        self.send_header('X-Forensic-Capture', 'true')
                        self.send_header('X-Forensic-Crawled-Page', 'true')
                        
                        self.end_headers()
                        
                        # Send the rewritten HTML content
                        self.wfile.write(html_bytes)
                        return
            
            # If no matching crawled page found, try normal asset serving
            super().do_GET()
    
    try:
        with HTTPServer(('localhost', port), ForensicHandler) as httpd:
            url = f"http://localhost:{port}"
            
            print(f"\n🌐 Serving forensic capture at: {url}")
            
            # Launch sandboxed browser
            browser_cmd = None
            for cmd in ['chromium', 'google-chrome', 'chrome']:
                if shutil.which(cmd):
                    browser_cmd = cmd
                    break
            
            if browser_cmd:
                try:
                    subprocess.Popen([
                        browser_cmd,
                        '--disable-web-security',  # Allow mixed content for forensic analysis
                        '--disable-background-networking',  # Prevent background requests
                        '--disable-background-timer-throttling',
                        '--disable-backgrounding-occluded-windows',
                        '--disable-renderer-backgrounding',
                        '--disable-features=TranslateUI',
                        '--disable-ipc-flooding-protection',
                        '--no-default-browser-check',
                        '--no-first-run',
                        '--disable-default-apps',
                        '--disable-extensions',
                        '--disable-plugins',
                        '--disable-sync',
                        '--disable-component-extensions-with-background-pages',
                        '--user-data-dir=/tmp/forensic-browser-isolated',
                        '--block-new-web-contents',
                        '--disable-client-side-phishing-detection',
                        '--disable-component-update',
                        '--disable-domain-reliability',
                        '--disable-features=VizNetworkService',
                        '--disable-features=NetworkService',
                        '--proxy-server=socks5://127.0.0.1:1',  # Invalid proxy blocks external requests
                        '--proxy-bypass-list=localhost,127.0.0.1',  # Allow localhost
                        '--disable-background-sync',
                        '--disable-permissions-api',
                        url
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    print(f"🎭 Sandboxed browser launched (no external network access)")
                except Exception as e:
                    print(f"⚠ Sandboxed browser failed: {e}")
                    print("🔗 Opening fallback browser")
                    webbrowser.open(url)
            else:
                print("⚠ Chromium not found, using system browser")
                webbrowser.open(url)
            
            print("\nPress Ctrl+C to stop the server")
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped")
        return True
    except OSError as e:
        if e.errno == 98:
            print(f"\n❌ Port {port} already in use")
        else:
            print(f"\n❌ Server error: {e}")
        return False
    
    return True
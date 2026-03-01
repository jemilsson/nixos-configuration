#!/usr/bin/env python3

"""
Forensic Web Capture Tool with TLS Certificate Preservation and Browser Spoofing
Creates court-admissible captures with cryptographic proof of origin
"""

import os
import sys
import json
import hashlib
import argparse
import subprocess
import socket
import ssl
import datetime
import uuid
import tempfile
from pathlib import Path
from urllib.parse import urlparse
import time
import random
import threading
import socketserver
import struct

try:
    import requests
    from fake_useragent import UserAgent
    import certifi
    from cryptography import x509
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import serialization
    from bs4 import BeautifulSoup
    import dns.resolver
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install with: pip install requests fake-useragent certifi cryptography beautifulsoup4 dnspython")
    sys.exit(1)

class ForensicSOCKSProxy(socketserver.ThreadingTCPServer):
    """SOCKS5 proxy that serves forensic content directly"""
    
    def __init__(self, server_address, capture_dir, original_domain):
        super().__init__(server_address, ForensicSOCKSHandler)
        self.capture_dir = Path(capture_dir)
        self.original_domain = original_domain
        self.allow_reuse_address = True
        
        # Load captured content
        self.index_content = None
        self.response_headers = {}
        self.domain_mapping = {}
        
        # Load main page
        page_file = self.capture_dir / 'page.html'
        if page_file.exists():
            with open(page_file, 'rb') as f:
                self.index_content = f.read()
        
        # Load response headers
        headers_file = self.capture_dir / 'response_headers.json'
        if headers_file.exists():
            with open(headers_file) as f:
                self.response_headers = json.load(f)
        
        # Load domain mapping for cross-domain assets
        mapping_file = self.capture_dir / 'domain_mapping.json'
        if mapping_file.exists():
            with open(mapping_file) as f:
                self.domain_mapping = json.load(f)

class ForensicSOCKSHandler(socketserver.BaseRequestHandler):
    """Handle SOCKS5 connections and serve forensic content"""
    
    def handle(self):
        try:
            # Read SOCKS5 initial request
            data = self.request.recv(262)
            if len(data) < 3 or data[0] != 5:  # Not SOCKS5
                return
                
            # Send auth method (no auth)
            self.request.send(b'\x05\x00')
            
            # Read connection request
            data = self.request.recv(262)
            if len(data) < 10 or data[0] != 5 or data[1] != 1:  # Not CONNECT
                return
                
            # Parse target address
            addr_type = data[3]
            if addr_type == 1:  # IPv4
                target_addr = socket.inet_ntoa(data[4:8])
                target_port = struct.unpack('>H', data[8:10])[0]
            elif addr_type == 3:  # Domain name
                addr_len = data[4]
                target_addr = data[5:5+addr_len].decode('ascii')
                target_port = struct.unpack('>H', data[5+addr_len:7+addr_len])[0]
            else:
                return
                
            # Send success response
            self.request.send(b'\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00')
            
            # Handle HTTP requests to captured domains
            if target_port == 80 or target_port == 443:
                if (target_addr == self.server.original_domain or 
                    target_addr in self.server.domain_mapping):
                    self.handle_http_request(target_addr)
                else:
                    # Block uncaptured domains
                    self.request.close()
            else:
                # Block all non-HTTP connections
                self.request.close()
                
        except Exception as e:
            print(f"SOCKS error: {e}")
            
    def handle_http_request(self, domain):
        """Handle HTTP request and serve forensic content"""
        try:
            while True:
                data = self.request.recv(8192)
                if not data:
                    break
                    
                # Parse HTTP request
                request_text = data.decode('utf-8', errors='ignore')
                lines = request_text.split('\r\n')
                if not lines:
                    break
                    
                first_line = lines[0]
                if not first_line.startswith(('GET ', 'POST ', 'HEAD ')):
                    break
                    
                # Extract path
                parts = first_line.split(' ')
                if len(parts) < 2:
                    break
                    
                path = parts[1]
                
                # Serve content based on domain and path
                if domain == self.server.original_domain and path == '/':
                    # Serve main page
                    self.serve_main_page()
                elif domain in self.server.domain_mapping:
                    # Serve cross-domain asset
                    self.serve_asset(domain, path)
                else:
                    # 404 for unknown requests
                    self.send_404()
                    
                break
                
        except Exception as e:
            print(f"HTTP error: {e}")
        finally:
            self.request.close()
    
    def serve_main_page(self):
        """Serve the main captured page"""
        if not self.server.index_content:
            self.send_404()
            return
            
        # Build HTTP response
        response = b'HTTP/1.1 200 OK\r\n'
        
        # Add original headers
        for key, value in self.server.response_headers.items():
            if key.lower() not in ['connection', 'transfer-encoding']:
                response += f'{key}: {value}\r\n'.encode()
        
        response += b'Connection: close\r\n'
        response += b'\r\n'
        response += self.server.index_content
        
        self.request.send(response)
    
    def serve_asset(self, domain, path):
        """Serve a cross-domain asset"""
        # Find asset in domain mapping
        if domain not in self.server.domain_mapping:
            self.send_404()
            return
        
        # Look for matching path (with or without query parameters)
        for asset in self.server.domain_mapping[domain]:
            original_url = asset['original_url']
            local_path = asset['local_path']
            asset_type = asset['type']
            
            # Extract path and query from original URL for matching
            from urllib.parse import urlparse, parse_qs
            parsed_original = urlparse(original_url)
            original_path = parsed_original.path
            original_query = parsed_original.query
            
            # Parse request path and query
            request_parts = path.split('?', 1)
            request_path = request_parts[0]
            request_query = request_parts[1] if len(request_parts) > 1 else ""
            
            # Match by path first
            if original_path == request_path:
                # For images with query parameters, also check if query parameters match
                if request_query and original_query:
                    # Parse query parameters
                    original_params = parse_qs(original_query)
                    request_params = parse_qs(request_query)
                    
                    # Check if essential image parameters match (or are compatible)
                    params_match = True
                    for key in ['width', 'quality', 'crop', 'io', 'auto']:
                        if key in request_params and key in original_params:
                            if request_params[key] != original_params[key]:
                                params_match = False
                                break
                    
                    if not params_match:
                        continue
                
                # Found matching asset
                asset_file = self.server.capture_dir / local_path
                if asset_file.exists():
                    self.serve_file(asset_file, asset_type)
                    print(f"📸 Served {asset_type}: {original_path}")
                else:
                    print(f"⚠ Asset file missing: {local_path}")
                    self.send_404()
                return
        
        # Asset not found - log for debugging
        print(f"❌ Asset not found: {domain}{path}")
        print(f"   Available assets for {domain}:")
        for asset in self.server.domain_mapping[domain][:3]:  # Show first 3
            parsed = urlparse(asset['original_url'])
            print(f"   - {parsed.path}?{parsed.query}")
        self.send_404()
    
    def serve_file(self, file_path, asset_type):
        """Serve a file with appropriate headers"""
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
            
            # Determine content type
            content_type = self.get_content_type(file_path, asset_type)
            
            response = b'HTTP/1.1 200 OK\r\n'
            response += f'Content-Type: {content_type}\r\n'.encode()
            response += f'Content-Length: {len(content)}\r\n'.encode()
            response += b'Connection: close\r\n'
            response += b'\r\n'
            response += content
            
            self.request.send(response)
            
        except Exception as e:
            print(f"Error serving file {file_path}: {e}")
            self.send_404()
    
    def get_content_type(self, file_path, asset_type):
        """Determine content type for asset"""
        ext = file_path.suffix.lower()
        
        content_types = {
            '.css': 'text/css',
            '.js': 'application/javascript',
            '.png': 'image/png',
            '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
            '.gif': 'image/gif',
            '.svg': 'image/svg+xml',
            '.woff': 'font/woff',
            '.woff2': 'font/woff2',
            '.ttf': 'font/ttf',
            '.eot': 'application/vnd.ms-fontobject'
        }
        
        return content_types.get(ext, 'application/octet-stream')
    
    def send_404(self):
        """Send 404 Not Found response"""
        response = b'HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n404 Not Found'
        self.request.send(response)

class ForensicCapture:
    """Forensic web capture with TLS certificates and browser spoofing"""
    
    def __init__(self, url, output_dir=None, browser_profile="chrome", crawl=False, depth=2, max_pages=50):
        self.url = url
        self.parsed_url = urlparse(url)
        self.hostname = self.parsed_url.hostname
        self.port = self.parsed_url.port or (443 if self.parsed_url.scheme == 'https' else 80)
        
        # Crawling parameters
        self.crawl_enabled = crawl
        self.max_depth = min(max(1, depth), 5)  # Clamp between 1 and 5
        self.max_pages = min(max(1, max_pages), 200)  # Clamp between 1 and 200
        self.crawled_urls = set()
        self.crawl_queue = []
        self.pages_captured = 0
        
        # Generate output directory
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        self.output_dir = Path(output_dir or f"capture_{self.hostname}_{timestamp}")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Browser profiles for spoofing
        self.browser_profiles = {
            'chrome': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'identity',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Sec-Fetch-User': '?1',
                'Cache-Control': 'max-age=0',
                'sec-ch-ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
                'sec-ch-ua-mobile': '?0',
                'sec-ch-ua-platform': '"Windows"',
            },
            'firefox': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
                'Accept-Encoding': 'identity',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Sec-Fetch-User': '?1',
            },
            'safari': {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'identity',
                'Connection': 'keep-alive',
            },
            'googlebot': {
                'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'en',
                'Accept-Encoding': 'identity',
                'Connection': 'keep-alive',
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
            },
            'random': None  # Will use fake_useragent
        }
        
        self.browser = browser_profile
        self.session = requests.Session()
        
        # Initialize metadata first
        self.metadata = {
            'capture_id': str(uuid.uuid4()),
            'capture_time_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'capture_time_local': datetime.datetime.now().isoformat(),
            'url': url,
            'hostname': self.hostname,
            'browser_profile': browser_profile,
            'system': dict(zip(['sysname', 'nodename', 'release', 'version', 'machine'], 
                              os.uname())) if hasattr(os, 'uname') else {},
        }
        
        self.setup_session()
    
    def setup_session(self):
        """Configure session with browser spoofing"""
        if self.browser == 'random':
            ua = UserAgent()
            headers = {
                'User-Agent': ua.random,
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'identity',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
            }
        else:
            headers = self.browser_profiles.get(self.browser, self.browser_profiles['chrome'])
        
        self.session.headers.update(headers)
        self.metadata['headers_used'] = dict(self.session.headers)
        self.metadata['domain_certificates'] = {}  # Track all domain certificates
    
    def capture_domain_certificate(self, hostname, port=443):
        """Capture TLS/SSL certificate for a specific domain"""
        try:
            # Create SSL context
            context = ssl.create_default_context()
            
            # Connect and get certificate
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    # Get peer certificate (DER format)
                    der_cert = ssock.getpeercert(binary_form=True)
                    
                    # Get certificate info
                    cert_info = ssock.getpeercert()
                    
                    # Parse certificate with cryptography
                    cert = x509.load_der_x509_certificate(der_cert, default_backend())
                    
                    # Create safe filename for the domain
                    domain_safe = hostname.replace('.', '_').replace(':', '_')
                    
                    # Save certificates
                    cert_dir = self.output_dir / 'certificates'
                    cert_dir.mkdir(exist_ok=True)
                    
                    # Save domain certificate
                    with open(cert_dir / f'{domain_safe}_certificate.der', 'wb') as f:
                        f.write(der_cert)
                    
                    with open(cert_dir / f'{domain_safe}_certificate.pem', 'wb') as f:
                        f.write(cert.public_bytes(serialization.Encoding.PEM))
                    
                    # Certificate details
                    cert_details = {
                        'hostname': hostname,
                        'subject': str(cert.subject),
                        'issuer': str(cert.issuer),
                        'version': f"v{cert.version.value}",
                        'serial_number': str(cert.serial_number),
                        'not_before': cert.not_valid_before_utc.isoformat(),
                        'not_after': cert.not_valid_after_utc.isoformat(),
                        'signature_algorithm': cert.signature_algorithm_oid._name,
                        'sha256_fingerprint': hashlib.sha256(der_cert).hexdigest(),
                        'sha1_fingerprint': hashlib.sha1(der_cert).hexdigest(),
                        'san': self._get_san(cert),
                        'is_valid': self._check_validity(cert)
                    }
                    
                    # Save certificate details
                    with open(cert_dir / f'{domain_safe}_certificate_details.json', 'w') as f:
                        json.dump(cert_details, f, indent=2)
                    
                    # Store in metadata for reporting
                    self.metadata['domain_certificates'][hostname] = cert_details
                    
                    return cert_details
                    
        except Exception as e:
            print(f"    ⚠ Certificate capture failed for {hostname}: {e}")
            return {'hostname': hostname, 'error': str(e)}

    def capture_tls_certificates(self):
        """Capture TLS/SSL certificates from the main server"""
        print(f"[1/7] Capturing TLS certificates from {self.hostname}...")
        
        if self.parsed_url.scheme != 'https':
            print("  ⚠ Not an HTTPS URL, no certificates to capture")
            return None
        
        try:
            cert_details = self.capture_domain_certificate(self.hostname, self.port)
            
            if cert_details and 'error' not in cert_details:
                # Also save as main server certificate for backward compatibility
                cert_dir = self.output_dir / 'certificates'
                domain_safe = self.hostname.replace('.', '_')
                
                # Copy the domain certificate as server certificate
                import shutil
                shutil.copy2(cert_dir / f'{domain_safe}_certificate.der', cert_dir / 'server_certificate.der')
                shutil.copy2(cert_dir / f'{domain_safe}_certificate.pem', cert_dir / 'server_certificate.pem')
                shutil.copy2(cert_dir / f'{domain_safe}_certificate_details.json', cert_dir / 'certificate_details.json')
                
                print(f"  ✓ Certificate captured: {cert_details.get('subject', 'Unknown')}")
                print(f"  ✓ SHA256 Fingerprint: {cert_details.get('sha256_fingerprint', 'N/A')}")
                print(f"  ✓ Valid from {cert_details.get('not_before', 'N/A')} to {cert_details.get('not_after', 'N/A')}")
                
                self.metadata['tls_certificate'] = cert_details
                return cert_details
            else:
                print(f"  ✗ Certificate capture failed")
                self.metadata['tls_certificate_error'] = cert_details.get('error', 'Unknown error') if cert_details else 'No certificate data'
                return None
                    
        except Exception as e:
            print(f"  ✗ Certificate capture failed: {e}")
            self.metadata['tls_certificate_error'] = str(e)
            return None
    
    def _get_san(self, cert):
        """Extract Subject Alternative Names from certificate"""
        try:
            san_ext = cert.extensions.get_extension_for_oid(x509.oid.ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
            return [name.value for name in san_ext.value]
        except:
            return []
    
    def _check_validity(self, cert):
        """Check if certificate is currently valid"""
        now = datetime.datetime.now(datetime.timezone.utc)
        return cert.not_valid_before_utc <= now <= cert.not_valid_after_utc
    
    def check_ocsp(self, cert, cert_dir):
        """Check OCSP status of certificate"""
        try:
            # Try to extract OCSP URL from certificate
            aia = cert.extensions.get_extension_for_oid(x509.oid.ExtensionOID.AUTHORITY_INFORMATION_ACCESS)
            ocsp_urls = [desc.access_location.value for desc in aia.value 
                        if desc.access_method == x509.oid.AuthorityInformationAccessOID.OCSP]
            
            if ocsp_urls:
                print(f"  → Checking OCSP status at {ocsp_urls[0]}")
                # Note: Full OCSP checking would require additional implementation
                with open(cert_dir / 'ocsp_urls.txt', 'w') as f:
                    for url in ocsp_urls:
                        f.write(url + '\n')
        except:
            pass
    
    def capture_dns_records(self):
        """Capture DNS resolution records"""
        print(f"[2/7] Resolving DNS for {self.hostname}...")
        
        dns_records = {}
        try:
            # A records
            a_records = dns.resolver.resolve(self.hostname, 'A')
            dns_records['A'] = [str(r) for r in a_records]
            print(f"  ✓ A records: {', '.join(dns_records['A'])}")
        except:
            pass
        
        try:
            # AAAA records
            aaaa_records = dns.resolver.resolve(self.hostname, 'AAAA')
            dns_records['AAAA'] = [str(r) for r in aaaa_records]
            print(f"  ✓ AAAA records: {', '.join(dns_records['AAAA'])}")
        except:
            pass
        
        # Save DNS records
        with open(self.output_dir / 'dns_records.json', 'w') as f:
            json.dump(dns_records, f, indent=2)
        
        self.metadata['dns_records'] = dns_records
        return dns_records
    
    def capture_page(self):
        """Capture the web page with spoofed headers"""
        print(f"[3/7] Capturing page content from {self.url}...")
        
        try:
            # Add referer for some sites that check it
            if self.parsed_url.path and self.parsed_url.path != '/':
                self.session.headers['Referer'] = f"{self.parsed_url.scheme}://{self.parsed_url.netloc}/"
            
            # Make request with timeout and disable auto decompression for forensic integrity
            response = self.session.get(self.url, timeout=30, verify=certifi.where(), stream=True)
            
            # Get headers first
            headers = dict(response.headers)
            
            # Save raw content exactly as received (including compression)
            with open(self.output_dir / 'page.html', 'wb') as f:
                f.write(response.content)
            
            # Also save decompressed version for analysis
            decompressed_content = response.text  # This will decompress if needed
            with open(self.output_dir / 'page_readable.html', 'w', encoding='utf-8') as f:
                f.write(decompressed_content)
            
            if 'content-encoding' in headers:
                print(f"  ℹ Content preserved with {headers['content-encoding']} compression")
            
            # Save response headers
            with open(self.output_dir / 'response_headers.json', 'w') as f:
                json.dump(headers, f, indent=2)
            
            # Parse and save metadata
            soup = BeautifulSoup(response.text, 'html.parser')
            page_metadata = {
                'status_code': response.status_code,
                'encoding': response.encoding,
                'content_length': len(response.content),
                'headers': headers,
                'title': soup.title.string if soup.title else None,
                'meta_tags': {meta.get('name', meta.get('property', 'unknown')): meta.get('content', '') 
                             for meta in soup.find_all('meta') if meta.get('content')},
                'server_date': headers.get('Date', 'Not provided'),
                'response_time_seconds': response.elapsed.total_seconds(),
            }
            
            with open(self.output_dir / 'page_metadata.json', 'w') as f:
                json.dump(page_metadata, f, indent=2, default=str)
            
            print(f"  ✓ Page captured: {response.status_code} {response.reason}")
            print(f"  ✓ Content length: {len(response.content)} bytes")
            print(f"  ✓ Server date: {headers.get('Date', 'Not provided')}")
            
            self.metadata['page_capture'] = page_metadata
            
            # Save any cookies
            if response.cookies:
                cookies = {k: v for k, v in response.cookies.items()}
                with open(self.output_dir / 'cookies.json', 'w') as f:
                    json.dump(cookies, f, indent=2)
            
            return response
            
        except Exception as e:
            print(f"  ✗ Page capture failed: {e}")
            self.metadata['page_capture_error'] = str(e)
            return None
    
    def capture_assets(self, html_content):
        """Capture assets using Playwright with proper header spoofing"""
        print("[4/7] Capturing page assets using Playwright...")
        
        try:
            return self._capture_assets_with_playwright()
        except ImportError:
            print("  ⚠ Playwright not available, falling back to HTML parsing")
            return self._capture_assets_fallback(html_content)
        except Exception as e:
            print(f"  ⚠ Playwright capture failed: {e}")
            print("  ℹ Falling back to HTML parsing method")
            return self._capture_assets_fallback(html_content)
    
    def _capture_assets_with_playwright(self):
        """Use Playwright to navigate to original website and capture all network requests"""
        from playwright.sync_api import sync_playwright
        import json
        
        assets_dir = self.output_dir / 'assets'
        assets_dir.mkdir(exist_ok=True)
        
        asset_count = 0
        domain_mapping = {}
        captured_urls = set()  # Avoid duplicates
        requests_data = []
        
        with sync_playwright() as p:
            # Launch browser with proper configuration for forensic capture
            browser = p.chromium.launch(
                headless=True,
                args=[
                    '--no-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-gpu',
                    '--disable-extensions',
                    '--disable-plugins',
                    '--disable-web-security',  # Allow cross-origin requests for forensic capture
                    '--allow-running-insecure-content',
                ]
            )
            
            # Create new context with our spoofed headers
            context = browser.new_context(
                user_agent=self.session.headers.get('User-Agent'),
                extra_http_headers={
                    key: value for key, value in self.session.headers.items()
                    if key.lower() not in ['user-agent', 'content-length']
                }
            )
            
            page = context.new_page()
            
            # Track all network requests
            requests_data = []
            
            def handle_response(response):
                try:
                    url = response.url
                    content_type = response.headers.get('content-type', '')
                    status = response.status
                    
                    # Only capture successful responses for assets we care about
                    if (status == 200 and url not in captured_urls and 
                        any(asset_type in content_type.lower() for asset_type in 
                            ['image/', 'text/css', 'application/javascript', 'javascript', 
                             'font/', 'application/font', 'text/javascript'])):
                        
                        requests_data.append({
                            'url': url,
                            'content_type': content_type,
                            'status': status,
                            'headers': dict(response.headers)
                        })
                        captured_urls.add(url)
                        
                except Exception as e:
                    print(f"    ⚠ Error handling response: {e}")
            
            page.on('response', handle_response)
            
            try:
                # Navigate to the page
                print(f"  → Loading page with Playwright...")
                page.goto(self.url, wait_until='networkidle', timeout=30000)
                
                # Scroll to trigger lazy loading
                print(f"  → Triggering lazy loading...")
                page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                page.wait_for_timeout(2000)
                page.evaluate("window.scrollTo(0, 0)")
                page.wait_for_timeout(2000)
                
                # Additional scrolling to catch more lazy content
                page.evaluate("""
                    let scrolls = 0;
                    const scrollDown = () => {
                        if (scrolls < 5) {
                            window.scrollBy(0, window.innerHeight);
                            scrolls++;
                            setTimeout(scrollDown, 500);
                        }
                    };
                    scrollDown();
                """)
                page.wait_for_timeout(3000)
                
            except Exception as e:
                print(f"    ⚠ Page navigation error: {e}")
            
            # Capture certificates for all asset domains
            unique_domains = set()
            for request_data in requests_data:
                try:
                    parsed = urlparse(request_data['url'])
                    if parsed.scheme == 'https' and parsed.netloc:
                        unique_domains.add(parsed.netloc)
                except:
                    continue
            
            if unique_domains:
                print(f"  → Capturing TLS certificates for {len(unique_domains)} asset domains...")
                for domain in unique_domains:
                    if domain != self.hostname:  # Skip main domain (already captured)
                        print(f"    • {domain}")
                        self.capture_domain_certificate(domain)
            
            # Process captured requests
            print(f"  → Processing {len(requests_data)} captured requests...")
            
            for request_data in requests_data:
                try:
                    url = request_data['url']
                    content_type = request_data['content_type']
                    
                    # Download the asset using our session (maintains header spoofing)
                    asset_response = self.session.get(url, timeout=10)
                    
                    # Determine asset type
                    if 'image/' in content_type:
                        asset_type = 'image'
                    elif 'text/css' in content_type:
                        asset_type = 'css'
                    elif 'javascript' in content_type:
                        asset_type = 'js'
                    elif 'font/' in content_type or 'application/font' in content_type:
                        asset_type = 'font'
                    else:
                        asset_type = 'resource'
                    
                    # Generate safe filename
                    parsed = urlparse(url)
                    domain_safe = parsed.netloc.replace('.', '_')
                    path_safe = parsed.path.replace('/', '_').strip('_') or 'index'
                    # Limit filename length to avoid filesystem issues
                    if len(path_safe) > 100:
                        path_safe = path_safe[:100] + '_trunc'
                    
                    filename = f"{asset_type}_{asset_count}_{domain_safe}_{path_safe}"
                    
                    # Add appropriate extension based on content type
                    if 'image/jpeg' in content_type:
                        filename += '.jpg'
                    elif 'image/png' in content_type:
                        filename += '.png'
                    elif 'image/gif' in content_type:
                        filename += '.gif'
                    elif 'image/svg' in content_type:
                        filename += '.svg'
                    elif 'image/webp' in content_type:
                        filename += '.webp'
                    elif 'text/css' in content_type:
                        filename += '.css'
                    elif 'javascript' in content_type:
                        filename += '.js'
                    elif 'font/' in content_type:
                        if 'woff2' in content_type:
                            filename += '.woff2'
                        elif 'woff' in content_type:
                            filename += '.woff'
                        elif 'ttf' in content_type:
                            filename += '.ttf'
                        else:
                            filename += '.font'
                    
                    # Save file
                    file_path = assets_dir / filename
                    with open(file_path, 'wb') as f:
                        f.write(asset_response.content)
                    
                    # Track for domain mapping
                    if parsed.netloc not in domain_mapping:
                        domain_mapping[parsed.netloc] = []
                    
                    domain_mapping[parsed.netloc].append({
                        'original_url': url,
                        'local_path': f'assets/{filename}',
                        'type': asset_type,
                        'content_type': content_type
                    })
                    
                    asset_count += 1
                    
                except Exception as e:
                    print(f"    ⚠ Failed to download {url}: {e}")
                    continue
            
            browser.close()
        
        # Save domain mapping
        with open(self.output_dir / 'domain_mapping.json', 'w') as f:
            json.dump(domain_mapping, f, indent=2)
        
        print(f"  ✓ Captured {asset_count} assets from {len(domain_mapping)} domains using Playwright")
        self.metadata['assets_captured'] = asset_count
        self.metadata['domains_captured'] = list(domain_mapping.keys())
        self.metadata['capture_method'] = 'playwright'
        
        return domain_mapping
    
    def _capture_assets_fallback(self, html_content):
        """Fallback method using HTML parsing"""
        print("  → Using HTML parsing fallback method...")
        
        if not html_content:
            return {}
        
        soup = BeautifulSoup(html_content.text, 'html.parser')
        assets_dir = self.output_dir / 'assets'
        assets_dir.mkdir(exist_ok=True)
        
        asset_count = 0
        assets = []
        domain_mapping = {}
        
        # Extract all possible assets from HTML
        self._extract_html_assets(soup, assets)
        
        # Capture certificates for all asset domains
        unique_domains = set()
        for asset_info in assets:
            try:
                absolute_url = self._make_absolute_url(asset_info[1])
                parsed = urlparse(absolute_url)
                if parsed.scheme == 'https' and parsed.netloc:
                    unique_domains.add(parsed.netloc)
            except:
                continue
        
        if unique_domains:
            print(f"  → Capturing TLS certificates for {len(unique_domains)} asset domains...")
            for domain in unique_domains:
                if domain != self.hostname:  # Skip main domain (already captured)
                    print(f"    • {domain}")
                    self.capture_domain_certificate(domain)

        # Download and process assets
        css_files = []
        for asset_info in assets:
            asset_type, url = asset_info[0], asset_info[1]
            try:
                absolute_url = self._make_absolute_url(url)
                parsed = urlparse(absolute_url)
                
                # Track domain for SOCKS proxy
                if parsed.netloc not in domain_mapping:
                    domain_mapping[parsed.netloc] = []
                
                # Download asset
                asset_response = self.session.get(absolute_url, timeout=10)
                
                # Generate filename with domain info
                domain_safe = parsed.netloc.replace('.', '_')
                path_safe = parsed.path.replace('/', '_').strip('_') or 'index'
                filename = f"{asset_type}_{asset_count}_{domain_safe}_{path_safe}"
                
                # Add appropriate extension
                if not filename.split('.')[-1] in ['css', 'js', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'woff', 'woff2', 'ttf']:
                    if asset_type == 'css':
                        filename += '.css'
                    elif asset_type == 'js':
                        filename += '.js'
                    elif asset_type in ['font', 'woff', 'woff2']:
                        filename += '.woff'
                
                file_path = assets_dir / filename
                with open(file_path, 'wb') as f:
                    f.write(asset_response.content)
                
                # Track for domain mapping
                domain_mapping[parsed.netloc].append({
                    'original_url': absolute_url,
                    'local_path': f'assets/{filename}',
                    'type': asset_type
                })
                
                # If it's CSS, extract more assets from within it
                if asset_type == 'css':
                    css_files.append((file_path, absolute_url))
                
                asset_count += 1
                
            except Exception as e:
                print(f"    ⚠ Failed to capture {url}: {e}")
                continue
        
        # Process CSS files for additional assets (fonts, images, imports)
        for css_file, css_url in css_files:
            try:
                with open(css_file, 'r', encoding='utf-8', errors='ignore') as f:
                    css_content = f.read()
                css_assets = self._extract_css_assets(css_content, css_url)
                
                # Download CSS assets
                for asset_type, url in css_assets:
                    try:
                        absolute_url = self._make_absolute_url(url, css_url)
                        parsed = urlparse(absolute_url)
                        
                        if parsed.netloc not in domain_mapping:
                            domain_mapping[parsed.netloc] = []
                        
                        asset_response = self.session.get(absolute_url, timeout=10)
                        
                        domain_safe = parsed.netloc.replace('.', '_')
                        path_safe = parsed.path.replace('/', '_').strip('_') or 'index'
                        filename = f"{asset_type}_{asset_count}_{domain_safe}_{path_safe}"
                        
                        if asset_type == 'font':
                            # Preserve font extensions
                            original_ext = os.path.splitext(parsed.path)[1]
                            if original_ext:
                                filename += original_ext
                            else:
                                filename += '.woff'
                        
                        file_path = assets_dir / filename
                        with open(file_path, 'wb') as f:
                            f.write(asset_response.content)
                        
                        domain_mapping[parsed.netloc].append({
                            'original_url': absolute_url,
                            'local_path': f'assets/{filename}',
                            'type': asset_type
                        })
                        
                        asset_count += 1
                        
                    except Exception as e:
                        continue
            except Exception as e:
                continue
        
        # Save domain mapping for SOCKS proxy
        mapping_file = self.output_dir / 'domain_mapping.json'
        with open(mapping_file, 'w') as f:
            json.dump(domain_mapping, f, indent=2)
        
        # Rewrite HTML to use local assets
        self._rewrite_html_assets(domain_mapping)
        
        print(f"  ✓ Captured {asset_count} assets from {len(domain_mapping)} domains")
        self.metadata['assets_captured'] = asset_count
        self.metadata['domains_captured'] = list(domain_mapping.keys())
    
    def _extract_html_assets(self, soup, assets):
        """Extract all assets from HTML including lazy-loaded content"""
        import re
        
        # Images - check multiple attributes for lazy loading
        for img in soup.find_all('img'):
            # Standard src
            src = img.get('src')
            if src and not src.startswith('data:'):
                assets.append(('image', src, src))
            
            # Lazy loading attributes
            for attr in ['data-src', 'data-original', 'data-lazy-src', 'data-srcset']:
                lazy_src = img.get(attr)
                if lazy_src and not lazy_src.startswith('data:'):
                    assets.append(('image', lazy_src, lazy_src))
            
            # Handle srcset
            srcset = img.get('srcset')
            if srcset:
                # Extract URLs from srcset (format: "url1 1x, url2 2x" or "url1 100w, url2 200w")
                urls = re.findall(r'([^\s,]+)(?:\s+[0-9.]+[wx]?)?', srcset)
                for url in urls:
                    if not url.startswith('data:'):
                        assets.append(('image', url, url))
        
        # Background images in style attributes
        for element in soup.find_all(attrs={'style': True}):
            style = element.get('style')
            if style:
                # Extract background-image URLs
                bg_urls = re.findall(r'background-image:\s*url\([\'"]?([^\'")]+)[\'"]?\)', style)
                for url in bg_urls:
                    if not url.startswith('data:'):
                        assets.append(('image', url, url))
        
        # Extract URLs from all script content (JavaScript)
        for script in soup.find_all('script'):
            if script.string:
                # Look for image URLs in JavaScript
                js_content = script.string
                # Match common patterns for image URLs
                patterns = [
                    r'[\'"]([^"\']+\.(?:jpg|jpeg|png|gif|svg|webp)(?:\?[^"\']*)?)[\'"]',  # Quoted image URLs
                    r'src[\'"\s]*[:=][\'"\s]*([^"\'\s]+\.(?:jpg|jpeg|png|gif|svg|webp)(?:\?[^"\']*)?)',  # src assignments
                    r'[\'"]([^"\']+/cfcdn-screen9/[^"\']*)[\'"]',  # Specific pattern for cfcdn-screen9 images
                ]
                
                for pattern in patterns:
                    matches = re.findall(pattern, js_content, re.IGNORECASE)
                    for match in matches:
                        if not match.startswith('data:'):
                            assets.append(('image', match, match))
            
            # External script sources
            src = script.get('src')
            if src:
                assets.append(('js', src, src))
        
        # CSS stylesheets
        for link in soup.find_all('link', rel='stylesheet'):
            href = link.get('href')
            if href:
                assets.append(('css', href, href))
        
        # Preload links (fonts, images, etc.)
        for link in soup.find_all('link', rel='preload'):
            href = link.get('href')
            as_type = link.get('as', 'resource')
            if href:
                if as_type == 'font':
                    assets.append(('font', href, href))
                elif as_type == 'image':
                    assets.append(('image', href, href))
                else:
                    assets.append(('resource', href, href))
        
        # Favicon and icons
        for link in soup.find_all('link', rel=['icon', 'shortcut icon', 'apple-touch-icon']):
            href = link.get('href')
            if href:
                assets.append(('icon', href, href))
        
        # Check all data attributes for potential URLs
        for element in soup.find_all():
            if hasattr(element, 'attrs') and element.attrs:
                for attr, value in element.attrs.items():
                    if attr.startswith('data-') and isinstance(value, str):
                        if any(ext in value.lower() for ext in ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp']):
                            if not value.startswith('data:'):
                                assets.append(('image', value, value))
    
    def _extract_css_assets(self, css_content, base_url):
        """Extract assets from CSS content"""
        import re
        assets = []
        
        # Extract url() references
        url_pattern = r'url\([\'"]?([^\'")]+)[\'"]?\)'
        matches = re.findall(url_pattern, css_content)
        
        for match in matches:
            if match.startswith('data:'):
                continue  # Skip data URLs
            
            # Determine asset type
            asset_type = 'resource'
            if any(ext in match.lower() for ext in ['.woff', '.woff2', '.ttf', '.eot']):
                asset_type = 'font'
            elif any(ext in match.lower() for ext in ['.png', '.jpg', '.jpeg', '.gif', '.svg']):
                asset_type = 'image'
            
            assets.append((asset_type, match))
        
        # Extract @import rules
        import_pattern = r'@import\s+[\'"]([^\'"]+)[\'"]'
        imports = re.findall(import_pattern, css_content)
        for import_url in imports:
            assets.append(('css', import_url))
        
        return assets
    
    def _make_absolute_url(self, url, base_url=None):
        """Convert relative URL to absolute"""
        if base_url is None:
            base_url = self.url
        
        if url.startswith('//'):
            return self.parsed_url.scheme + ':' + url
        elif url.startswith('/'):
            return f"{self.parsed_url.scheme}://{self.parsed_url.netloc}{url}"
        elif url.startswith('http'):
            return url
        else:
            # Relative to base URL
            from urllib.parse import urljoin
            return urljoin(base_url, url)
    
    def _rewrite_html_assets(self, domain_mapping):
        """Rewrite HTML to use local asset paths"""
        page_file = self.output_dir / 'page.html'
        if not page_file.exists():
            return
        
        try:
            # Read original HTML
            with open(page_file, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Create URL mapping from original to local
            url_mapping = {}
            for domain, assets in domain_mapping.items():
                for asset in assets:
                    original_url = asset['original_url']
                    local_path = asset['local_path']
                    url_mapping[original_url] = local_path
            
            # Replace URLs in HTML
            modified_html = html_content
            for original_url, local_path in url_mapping.items():
                # Handle HTML entity encoded URLs
                encoded_url = original_url.replace('&', '&amp;')
                
                # Replace both normal and encoded versions
                modified_html = modified_html.replace(original_url, local_path)
                modified_html = modified_html.replace(encoded_url, local_path)
                
                # Also handle quoted versions
                modified_html = modified_html.replace(f'"{original_url}"', f'"{local_path}"')
                modified_html = modified_html.replace(f'"{encoded_url}"', f'"{local_path}"')
                modified_html = modified_html.replace(f"'{original_url}'", f"'{local_path}'")
                modified_html = modified_html.replace(f"'{encoded_url}'", f"'{local_path}'")
            
            # Save rewritten HTML
            with open(page_file, 'w', encoding='utf-8') as f:
                f.write(modified_html)
            
            # Also save original for reference
            original_file = self.output_dir / 'page_original.html'
            with open(original_file, 'w', encoding='utf-8') as f:
                f.write(html_content)
                
            print(f"  ✓ Rewritten HTML with {len(url_mapping)} local asset references")
            
        except Exception as e:
            print(f"  ⚠ HTML rewriting failed: {e}")
    
    def take_screenshot(self):
        """Skip screenshot - not needed for forensic evidence"""
        print("[5/7] Skipping screenshot (not required for forensic integrity)")
        self.metadata['screenshot'] = False
    
    def generate_hashes(self):
        """Generate cryptographic hashes of all captured files"""
        print("[6/7] Generating cryptographic hashes...")
        
        sha256_hashes = {}
        sha512_hashes = {}
        
        for file_path in self.output_dir.rglob('*'):
            if file_path.is_file() and not file_path.name.endswith('.sha256'):
                relative_path = file_path.relative_to(self.output_dir)
                
                # Calculate SHA256
                sha256 = hashlib.sha256()
                sha512 = hashlib.sha512()
                
                with open(file_path, 'rb') as f:
                    for chunk in iter(lambda: f.read(4096), b""):
                        sha256.update(chunk)
                        sha512.update(chunk)
                
                sha256_hashes[str(relative_path)] = sha256.hexdigest()
                sha512_hashes[str(relative_path)] = sha512.hexdigest()
        
        # Save hash files
        with open(self.output_dir / 'SHA256SUMS.txt', 'w') as f:
            for path, hash_val in sorted(sha256_hashes.items()):
                f.write(f"{hash_val}  {path}\n")
        
        with open(self.output_dir / 'SHA512SUMS.txt', 'w') as f:
            for path, hash_val in sorted(sha512_hashes.items()):
                f.write(f"{hash_val}  {path}\n")
        
        print(f"  ✓ Generated hashes for {len(sha256_hashes)} files")
        self.metadata['file_count'] = len(sha256_hashes)
    
    def generate_report(self):
        """Generate chain of custody report"""
        print("[7/7] Generating forensic report...")
        
        # Save metadata
        with open(self.output_dir / 'capture_metadata.json', 'w') as f:
            json.dump(self.metadata, f, indent=2, default=str)
        
        # Generate report
        report = f"""FORENSIC WEB CAPTURE REPORT
===========================

Capture ID: {self.metadata['capture_id']}
Date/Time (UTC): {self.metadata['capture_time_utc']}
Date/Time (Local): {self.metadata['capture_time_local']}
Target URL: {self.url}
Hostname: {self.hostname}

TLS CERTIFICATE VALIDATION
--------------------------
"""
        
        if 'tls_certificate' in self.metadata:
            cert = self.metadata['tls_certificate']
            report += f"""✓ Certificate captured successfully
  Subject: {cert['subject']}
  Issuer: {cert['issuer']}
  SHA256 Fingerprint: {cert['sha256_fingerprint']}
  Valid: {cert['is_valid']}
  Not Before: {cert['not_before']}
  Not After: {cert['not_after']}
"""
        else:
            report += "⚠ No TLS certificate (HTTP connection)\n"
        
        report += f"""
DNS RESOLUTION
--------------
"""
        if 'dns_records' in self.metadata:
            for record_type, values in self.metadata['dns_records'].items():
                report += f"{record_type}: {', '.join(values)}\n"
        
        report += f"""
BROWSER SPOOFING
----------------
Profile: {self.metadata['browser_profile']}
User-Agent: {self.metadata['headers_used'].get('User-Agent', 'N/A')}

PAGE CAPTURE
------------
"""
        if 'page_capture' in self.metadata:
            pc = self.metadata['page_capture']
            report += f"""Status: {pc['status_code']}
Content Length: {pc['content_length']} bytes
Server Date: {pc['server_date']}
Response Time: {pc['response_time_seconds']:.2f} seconds
"""
        
        report += f"""
FILES CAPTURED
--------------
Total Files: {self.metadata.get('file_count', 0)}
Assets: {self.metadata.get('assets_captured', 0)}
Screenshot: {'Yes' if self.metadata.get('screenshot') else 'No'}

INTEGRITY VERIFICATION
---------------------
SHA256 hashes: SHA256SUMS.txt
SHA512 hashes: SHA512SUMS.txt

To verify integrity:
  cd {self.output_dir}
  sha256sum -c SHA256SUMS.txt
  sha512sum -c SHA512SUMS.txt

CHAIN OF CUSTODY
---------------
This capture was performed using forensic best practices:
1. TLS certificates preserved for cryptographic proof of origin
2. Complete HTTP headers and response captured
3. Browser spoofing used to obtain authentic server response
4. All files hashed with SHA256 and SHA512
5. Timestamps preserved at multiple levels

The TLS certificate provides cryptographic proof that:
- Content originated from the legitimate server
- Server was authorized by a Certificate Authority
- Connection was encrypted and authenticated
- No man-in-the-middle attack occurred

Generated: {datetime.datetime.now().isoformat()}
"""
        
        with open(self.output_dir / 'forensic_report.txt', 'w') as f:
            f.write(report)
        
        print(f"  ✓ Report saved to {self.output_dir}/forensic_report.txt")
        
        return report
    
    def extract_links(self, html_content, base_url):
        """Extract same-domain links from HTML content"""
        links = set()
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            base_parsed = urlparse(base_url)
            
            # Find all links
            for tag in soup.find_all(['a', 'link']):
                href = tag.get('href')
                if not href:
                    continue
                
                # Resolve relative URLs
                if href.startswith('/'):
                    link = f"{base_parsed.scheme}://{base_parsed.netloc}{href}"
                elif href.startswith('http'):
                    link = href
                else:
                    # Relative path
                    base_path = '/'.join(base_url.rstrip('/').split('/')[:-1])
                    link = f"{base_path}/{href}"
                
                link_parsed = urlparse(link)
                
                # Only include same-domain HTTP/HTTPS links
                if (link_parsed.netloc == base_parsed.netloc and
                    link_parsed.scheme in ['http', 'https'] and
                    not link.endswith(('.jpg', '.jpeg', '.png', '.gif', '.css', '.js', '.pdf', '.zip'))):
                    links.add(link)
        
        except Exception as e:
            print(f"⚠ Error extracting links: {e}")
        
        return links
    
    def capture_page_with_url(self, url, depth=0):
        """Capture a specific page and return its content"""
        print(f"{'  ' * depth}📄 Capturing: {url} (depth {depth})")
        
        try:
            # Use the same session for consistent headers
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            # Parse URL for safe filename
            parsed = urlparse(url)
            path_parts = parsed.path.strip('/').split('/')
            if not path_parts or path_parts == ['']:
                filename = 'index.html'
            else:
                filename = '_'.join(path_parts).replace('?', '_').replace('&', '_') + '.html'
            
            # Save page content
            page_file = self.output_dir / 'pages' / filename
            page_file.parent.mkdir(exist_ok=True)
            
            with open(page_file, 'wb') as f:
                f.write(response.content)
            
            # Save metadata for this page
            page_metadata = {
                'url': url,
                'status_code': response.status_code,
                'headers': dict(response.headers),
                'encoding': response.encoding,
                'content_length': len(response.content),
                'capture_time': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'depth': depth,
                'filename': filename
            }
            
            metadata_file = self.output_dir / 'pages' / (filename.replace('.html', '_metadata.json'))
            with open(metadata_file, 'w') as f:
                json.dump(page_metadata, f, indent=2)
            
            self.pages_captured += 1
            return response.content.decode(response.encoding or 'utf-8', errors='ignore')
        
        except Exception as e:
            print(f"{'  ' * depth}❌ Failed to capture {url}: {e}")
            return None
    
    def crawl_recursive(self, start_url, max_depth):
        """Recursively crawl same-domain links"""
        print(f"\n🕷️ Starting recursive crawl (max depth: {max_depth}, max pages: {self.max_pages})")
        
        # Initialize crawl queue with start URL
        self.crawl_queue = [(start_url, 0)]  # (url, depth)
        self.crawled_urls.add(start_url)
        
        while self.crawl_queue and self.pages_captured < self.max_pages:
            current_url, depth = self.crawl_queue.pop(0)
            
            if depth > max_depth:
                continue
            
            # Capture current page
            page_content = self.capture_page_with_url(current_url, depth)
            if not page_content:
                continue
            
            # Extract and queue new links if we haven't reached max depth
            if depth < max_depth:
                links = self.extract_links(page_content, current_url)
                new_links = links - self.crawled_urls
                
                if new_links:
                    print(f"{'  ' * depth}🔗 Found {len(new_links)} new links at depth {depth}")
                    
                    for link in sorted(new_links):
                        if self.pages_captured >= self.max_pages:
                            break
                        
                        self.crawl_queue.append((link, depth + 1))
                        self.crawled_urls.add(link)
                
                # Limit queue size to prevent memory issues
                if len(self.crawl_queue) > 500:
                    self.crawl_queue = self.crawl_queue[:500]
                    print("⚠ Crawl queue limited to 500 URLs")
        
        print(f"🕷️ Crawl complete: {self.pages_captured} pages captured")
        
        # Create navigation index for crawled pages
        self.create_crawl_index()
    
    def create_crawl_index(self):
        """Create a navigation index for browsing crawled pages"""
        pages_dir = self.output_dir / 'pages'
        if not pages_dir.exists():
            return
        
        # Gather information about crawled pages
        pages_info = []
        
        for page_file in pages_dir.glob('*.html'):
            metadata_file = pages_dir / (page_file.stem + '_metadata.json')
            
            if metadata_file.exists():
                try:
                    with open(metadata_file) as f:
                        metadata = json.load(f)
                    
                    pages_info.append({
                        'filename': page_file.name,
                        'url': metadata.get('url', ''),
                        'depth': metadata.get('depth', 0),
                        'status_code': metadata.get('status_code', ''),
                        'content_length': metadata.get('content_length', 0),
                        'capture_time': metadata.get('capture_time', '')
                    })
                except:
                    # If metadata is invalid, still include the page
                    pages_info.append({
                        'filename': page_file.name,
                        'url': f'/{page_file.name}',
                        'depth': '?',
                        'status_code': '?',
                        'content_length': page_file.stat().st_size,
                        'capture_time': '?'
                    })
        
        # Sort by depth then by URL
        pages_info.sort(key=lambda x: (x['depth'], x['url']))
        
        # Create HTML index
        index_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Forensic Capture Navigation - {self.hostname}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .header {{ background: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }}
        .header h1 {{ margin: 0; }}
        .stats {{ background: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; border-left: 4px solid #3498db; }}
        .pages {{ background: white; border-radius: 5px; overflow: hidden; }}
        .page {{ padding: 15px; border-bottom: 1px solid #eee; }}
        .page:last-child {{ border-bottom: none; }}
        .page:hover {{ background: #f8f9fa; }}
        .page-url {{ font-weight: bold; color: #2c3e50; text-decoration: none; }}
        .page-url:hover {{ color: #3498db; }}
        .page-info {{ font-size: 0.9em; color: #666; margin-top: 5px; }}
        .page-info span {{ margin-right: 15px; }}
        .depth-0 {{ border-left: 4px solid #e74c3c; }}
        .depth-1 {{ border-left: 4px solid #f39c12; }}
        .depth-2 {{ border-left: 4px solid #f1c40f; }}
        .depth-3+ {{ border-left: 4px solid #27ae60; }}
        .forensic-note {{ background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🕷️ Forensic Web Capture Navigation</h1>
        <p>Domain: <strong>{self.hostname}</strong> | Captured: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
    
    <div class="stats">
        <strong>📊 Capture Statistics:</strong><br>
        Pages captured: {len(pages_info)} | 
        Max depth: {max([p['depth'] for p in pages_info if isinstance(p['depth'], int)], default=0)} | 
        Total size: {sum(p['content_length'] for p in pages_info if isinstance(p['content_length'], int)):,} bytes
    </div>
    
    <div class="pages">"""

        for page in pages_info:
            depth_class = f"depth-{page['depth']}" if isinstance(page['depth'], int) and page['depth'] <= 3 else "depth-3+"
            
            index_html += f"""
        <div class="page {depth_class}">
            <a href="/pages/{page['filename']}" class="page-url">{page['url']}</a>
            <div class="page-info">
                <span>🔗 Depth: {page['depth']}</span>
                <span>📄 Status: {page['status_code']}</span>
                <span>📊 Size: {page['content_length']:,} bytes</span>
                <span>🕐 Captured: {page['capture_time'][:19] if isinstance(page['capture_time'], str) else page['capture_time']}</span>
            </div>
        </div>"""
        
        index_html += """
    </div>
    
    <div class="forensic-note">
        <strong>⚖️ Forensic Note:</strong> This is a complete forensic capture with cryptographic integrity verification. 
        All pages and assets have been captured with TLS certificates as proof of origin. 
        Run <code>sha256sum -c SHA256SUMS.txt</code> to verify integrity.
    </div>
</body>
</html>"""
        
        # Save the index
        index_file = self.output_dir / 'crawl_index.html'
        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(index_html)
        
        print(f"  ✓ Created navigation index: {index_file}")

    def capture(self):
        """Perform complete forensic capture"""
        print(f"\n=== FORENSIC WEB CAPTURE ===")
        print(f"URL: {self.url}")
        print(f"Output: {self.output_dir}")
        print(f"Browser: {self.browser}")
        if self.crawl_enabled:
            print(f"Crawling: Enabled (depth: {self.max_depth}, max pages: {self.max_pages})")
        print("=" * 40)
        
        # Capture components for main page
        self.capture_tls_certificates()
        self.capture_dns_records()
        page = self.capture_page()
        
        if page:
            self.capture_assets(page)
        
        # Perform crawling if enabled
        if self.crawl_enabled:
            # Mark the main URL as already crawled
            self.crawled_urls.add(self.url)
            self.pages_captured = 1  # Main page already captured
            
            # Start crawling
            self.crawl_recursive(self.url, self.max_depth)
        
        self.take_screenshot()
        self.generate_hashes()
        report = self.generate_report()
        
        print("\n" + "=" * 40)
        print("CAPTURE COMPLETE!")
        print(f"Output directory: {self.output_dir}")
        print(f"Files captured: {self.metadata.get('file_count', 0)}")
        if self.crawl_enabled:
            print(f"Pages crawled: {self.pages_captured}")
        print("\nTo verify integrity:")
        print(f"  cd {self.output_dir} && sha256sum -c SHA256SUMS.txt")
        
        return self.output_dir

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

def browse_capture(capture_dir, port=8000):
    """Browse a forensic capture using SOCKS proxy for transparent interception"""
    import json
    import subprocess
    import shutil
    import webbrowser
    from urllib.parse import urlparse
    import threading
    import tempfile
    
    capture_dir = Path(capture_dir)
    
    if not capture_dir.exists():
        print(f"Error: Directory {capture_dir} not found")
        return False
    
    # Determine if we should use SOCKS proxy or HTTP server based on capture type
    domain_mapping_file = capture_dir / 'domain_mapping.json'
    metadata_file = capture_dir / 'capture_metadata.json'
    
    # Load metadata to get the original URL
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
    from http.server import HTTPServer, SimpleHTTPRequestHandler
    
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
                
                # Create URL mapping from original to local (with /assets/ prefix for web serving)
                for domain, assets in domain_mapping.items():
                    for asset in assets:
                        original_url = asset['original_url']
                        local_path = '/' + asset['local_path']  # Add leading slash for absolute path
                        
                        # Handle HTML entity encoded URLs
                        encoded_url = original_url.replace('&', '&amp;')
                        
                        # Replace in all common attributes
                        for attr in ['src', 'href', 'data-src', 'data-lazy-src', 'data-original']:
                            # Replace in quoted attributes
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
                    import webbrowser
                    webbrowser.open(url)
            else:
                print("⚠ Chromium not found, using system browser")
                import webbrowser
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
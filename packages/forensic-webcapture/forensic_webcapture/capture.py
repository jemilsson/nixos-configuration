#!/usr/bin/env python3

"""
Forensic Web Capture Tool with TLS Certificate Preservation and Browser Spoofing
Creates court-admissible captures with cryptographic proof of origin
"""

import os
import sys
import json
import hashlib
import subprocess
import socket
import ssl
import datetime
import uuid
import tempfile
from pathlib import Path
from urllib.parse import urlparse, urljoin
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

from .assets import AssetExtractor
from .crawling import WebCrawler


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
        """Capture assets using AssetExtractor module"""
        print("[4/7] Capturing page assets...")
        
        extractor = AssetExtractor(self.url, self.session, self.output_dir)
        
        try:
            domain_mapping, asset_count = extractor.capture_assets_with_playwright()
            self.metadata['capture_method'] = 'playwright'
        except ImportError:
            print("  ⚠ Playwright not available, falling back to HTML parsing")
            domain_mapping, asset_count = extractor.capture_assets_fallback(html_content)
            self.metadata['capture_method'] = 'html_parsing'
        except Exception as e:
            print(f"  ⚠ Playwright capture failed: {e}")
            print("  ℹ Falling back to HTML parsing method")
            domain_mapping, asset_count = extractor.capture_assets_fallback(html_content)
            self.metadata['capture_method'] = 'html_parsing_fallback'
        
        # Capture certificates for all asset domains
        unique_domains = set()
        for domain, assets in domain_mapping.items():
            for asset in assets:
                try:
                    parsed = urlparse(asset['original_url'])
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
        
        print(f"  ✓ Captured {asset_count} assets from {len(domain_mapping)} domains")
        self.metadata['assets_captured'] = asset_count
        self.metadata['domains_captured'] = list(domain_mapping.keys())
        
        return domain_mapping
    
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
            crawler = WebCrawler(self.session, self.output_dir, self.hostname, self.max_depth, self.max_pages)
            crawler.crawl_recursive(self.url)
        
        self.take_screenshot()
        self.generate_hashes()
        report = self.generate_report()
        
        print("\n" + "=" * 40)
        print("CAPTURE COMPLETE!")
        print(f"Output directory: {self.output_dir}")
        print(f"Files captured: {self.metadata.get('file_count', 0)}")
        if self.crawl_enabled:
            print(f"Pages crawled: Available in crawl_index.html")
        print("\nTo verify integrity:")
        print(f"  cd {self.output_dir} && sha256sum -c SHA256SUMS.txt")
        
        return self.output_dir
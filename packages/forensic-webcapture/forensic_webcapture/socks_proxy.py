#!/usr/bin/env python3
"""
SOCKS5 proxy implementation for forensic web capture browsing
"""

import json
import socket
import struct
import threading
import socketserver
from pathlib import Path
from urllib.parse import urlparse

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
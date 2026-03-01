#!/usr/bin/env python3
"""
Asset extraction and processing for forensic web capture
"""

import os
import re
import json
from pathlib import Path
from urllib.parse import urlparse, urljoin
from bs4 import BeautifulSoup

class AssetExtractor:
    """Extract and process web assets for forensic capture"""
    
    def __init__(self, base_url, session, output_dir):
        self.base_url = base_url
        self.session = session
        self.output_dir = Path(output_dir)
        self.parsed_base_url = urlparse(base_url)
    
    def capture_assets_with_playwright(self):
        """Use Playwright to navigate to original website and capture all network requests"""
        from playwright.sync_api import sync_playwright
        
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
                page.goto(self.base_url, wait_until='networkidle', timeout=30000)
                
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
                    filename = self._add_file_extension(filename, content_type)
                    
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
        
        return domain_mapping, asset_count
    
    def capture_assets_fallback(self, html_content):
        """Fallback method using HTML parsing"""
        print("  → Using HTML parsing fallback method...")
        
        if not html_content:
            return {}, 0
        
        soup = BeautifulSoup(html_content.text, 'html.parser')
        assets_dir = self.output_dir / 'assets'
        assets_dir.mkdir(exist_ok=True)
        
        asset_count = 0
        assets = []
        domain_mapping = {}
        
        # Extract all possible assets from HTML
        self._extract_html_assets(soup, assets)
        
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
            asset_count += self._process_css_assets(css_file, css_url, domain_mapping, asset_count)
        
        return domain_mapping, asset_count
    
    def _add_file_extension(self, filename, content_type):
        """Add appropriate file extension based on content type"""
        if 'image/jpeg' in content_type:
            return filename + '.jpg'
        elif 'image/png' in content_type:
            return filename + '.png'
        elif 'image/gif' in content_type:
            return filename + '.gif'
        elif 'image/svg' in content_type:
            return filename + '.svg'
        elif 'image/webp' in content_type:
            return filename + '.webp'
        elif 'text/css' in content_type:
            return filename + '.css'
        elif 'javascript' in content_type:
            return filename + '.js'
        elif 'font/' in content_type:
            if 'woff2' in content_type:
                return filename + '.woff2'
            elif 'woff' in content_type:
                return filename + '.woff'
            elif 'ttf' in content_type:
                return filename + '.ttf'
            else:
                return filename + '.font'
        return filename
    
    def _extract_html_assets(self, soup, assets):
        """Extract all assets from HTML including lazy-loaded content"""
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
    
    def _process_css_assets(self, css_file, css_url, domain_mapping, asset_count_start):
        """Process CSS files for additional assets (fonts, images, imports)"""
        asset_count = 0
        try:
            with open(css_file, 'r', encoding='utf-8', errors='ignore') as f:
                css_content = f.read()
            css_assets = self._extract_css_assets(css_content)
            
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
                    filename = f"{asset_type}_{asset_count_start + asset_count}_{domain_safe}_{path_safe}"
                    
                    if asset_type == 'font':
                        # Preserve font extensions
                        original_ext = os.path.splitext(parsed.path)[1]
                        if original_ext:
                            filename += original_ext
                        else:
                            filename += '.woff'
                    
                    file_path = self.output_dir / 'assets' / filename
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
            pass
        
        return asset_count
    
    def _extract_css_assets(self, css_content):
        """Extract assets from CSS content"""
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
            base_url = self.base_url
        
        if url.startswith('//'):
            return self.parsed_base_url.scheme + ':' + url
        elif url.startswith('/'):
            return f"{self.parsed_base_url.scheme}://{self.parsed_base_url.netloc}{url}"
        elif url.startswith('http'):
            return url
        else:
            # Relative to base URL
            return urljoin(base_url, url)
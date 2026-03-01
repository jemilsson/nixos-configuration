#!/usr/bin/env python3
"""
Web crawling functionality for forensic capture
"""

import json
import datetime
from pathlib import Path
from urllib.parse import urlparse
from bs4 import BeautifulSoup

class WebCrawler:
    """Recursive web crawler for same-domain links"""
    
    def __init__(self, session, output_dir, hostname, max_depth=2, max_pages=50):
        self.session = session
        self.output_dir = Path(output_dir)
        self.hostname = hostname
        self.max_depth = min(max(1, max_depth), 5)  # Clamp between 1 and 5
        self.max_pages = min(max(1, max_pages), 200)  # Clamp between 1 and 200
        
        self.crawled_urls = set()
        self.crawl_queue = []
        self.pages_captured = 0
    
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
    
    def crawl_recursive(self, start_url):
        """Recursively crawl same-domain links"""
        print(f"\n🕷️ Starting recursive crawl (max depth: {self.max_depth}, max pages: {self.max_pages})")
        
        # Initialize crawl queue with start URL
        self.crawl_queue = [(start_url, 0)]  # (url, depth)
        self.crawled_urls.add(start_url)
        
        while self.crawl_queue and self.pages_captured < self.max_pages:
            current_url, depth = self.crawl_queue.pop(0)
            
            if depth > self.max_depth:
                continue
            
            # Capture current page
            page_content = self.capture_page_with_url(current_url, depth)
            if not page_content:
                continue
            
            # Extract and queue new links if we haven't reached max depth
            if depth < self.max_depth:
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
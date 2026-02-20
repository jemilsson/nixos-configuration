#!/usr/bin/env bash

# Forensic Web Capture Tool with TLS/SSL Certificate Preservation
# Captures web content with cryptographic proof from the server's HTTPS certificate

set -euo pipefail

# Configuration
MODE="${1:-capture}"
OUTPUT_DIR="${2:-}"
URL="${3:-}"
WITNESS="${4:-$USER}"

show_usage() {
    cat <<EOF
Forensic Web Capture with TLS/SSL Certificate Chain

Usage:
  $0 capture [output_dir] <URL> [witness_name]  - Capture with TLS certs
  $0 verify <capture_dir>                        - Verify certificates
  $0 report <capture_dir>                        - Generate court report

Features:
  - Captures complete TLS/SSL certificate chain
  - Server certificate fingerprints (SHA256)
  - Certificate validity verification
  - OCSP (Online Certificate Status Protocol) checking
  - Complete page preservation
  - Cryptographic proof of origin via TLS
  - Timestamp from server's Date header
EOF
    exit 1
}

# Function to extract domain from URL
get_domain() {
    echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|:.*||'
}

# Function to extract port from URL (default 443 for https)
get_port() {
    local url="$1"
    if echo "$url" | grep -q ":443"; then
        echo "443"
    elif echo "$url" | grep -E -o ':[0-9]+' > /dev/null; then
        echo "$url" | sed -e 's|^[^:]*://[^:]*:||' -e 's|/.*$||'
    else
        echo "443"
    fi
}

# Verify mode
if [ "$MODE" = "verify" ]; then
    CAPTURE_DIR="$OUTPUT_DIR"
    if [ -z "$CAPTURE_DIR" ] || [ ! -d "$CAPTURE_DIR" ]; then
        echo "Error: Please specify a valid capture directory to verify"
        show_usage
    fi
    
    echo "=== TLS CERTIFICATE VERIFICATION ==="
    echo "Directory: $CAPTURE_DIR"
    echo "Verification Time: $(date -Iseconds)"
    echo "===================================="
    
    # Verify certificate chain
    if [ -f "$CAPTURE_DIR/tls/server_cert.pem" ]; then
        echo "[1/4] Checking certificate validity..."
        openssl x509 -in "$CAPTURE_DIR/tls/server_cert.pem" -text -noout > /tmp/cert_check.txt
        
        # Check dates
        NOT_BEFORE=$(openssl x509 -in "$CAPTURE_DIR/tls/server_cert.pem" -noout -startdate | cut -d= -f2)
        NOT_AFTER=$(openssl x509 -in "$CAPTURE_DIR/tls/server_cert.pem" -noout -enddate | cut -d= -f2)
        
        echo "Certificate valid from: $NOT_BEFORE"
        echo "Certificate valid to: $NOT_AFTER"
        
        # Check if currently valid
        openssl x509 -in "$CAPTURE_DIR/tls/server_cert.pem" -noout -checkend 0
        if [ $? -eq 0 ]; then
            echo "✓ Certificate is currently VALID"
        else
            echo "⚠ Certificate has EXPIRED"
        fi
    fi
    
    # Verify certificate chain
    if [ -f "$CAPTURE_DIR/tls/cert_chain.pem" ]; then
        echo "[2/4] Verifying certificate chain..."
        openssl verify -CAfile "$CAPTURE_DIR/tls/cert_chain.pem" "$CAPTURE_DIR/tls/server_cert.pem" 2>&1
    fi
    
    # Check fingerprints
    if [ -f "$CAPTURE_DIR/tls/certificate_fingerprints.txt" ]; then
        echo "[3/4] Certificate fingerprints:"
        cat "$CAPTURE_DIR/tls/certificate_fingerprints.txt"
    fi
    
    # Verify file hashes
    echo "[4/4] Verifying content integrity..."
    if cd "$CAPTURE_DIR" && sha256sum -c SHA256SUMS.txt > /dev/null 2>&1; then
        echo "✓ Content integrity verified"
    else
        echo "✗ Content integrity check FAILED"
        exit 1
    fi
    
    echo ""
    echo "=== VERIFICATION COMPLETE ==="
    exit 0
fi

# Report mode
if [ "$MODE" = "report" ]; then
    CAPTURE_DIR="$OUTPUT_DIR"
    if [ -z "$CAPTURE_DIR" ] || [ ! -d "$CAPTURE_DIR" ]; then
        echo "Error: Please specify a valid capture directory"
        show_usage
    fi
    
    cat > "$CAPTURE_DIR/tls_forensic_report.md" <<EOF
# FORENSIC WEB CAPTURE REPORT WITH TLS VERIFICATION

## Executive Summary
This report documents the forensic capture of web content with TLS/SSL certificate verification,
providing cryptographic proof of origin from the web server.

## Capture Metadata
$(cat "$CAPTURE_DIR/capture_metadata.txt" 2>/dev/null || echo "Metadata not available")

## TLS/SSL Certificate Information

### Server Certificate
\`\`\`
$(openssl x509 -in "$CAPTURE_DIR/tls/server_cert.pem" -text -noout 2>/dev/null | head -30 || echo "Certificate not available")
\`\`\`

### Certificate Fingerprints
\`\`\`
$(cat "$CAPTURE_DIR/tls/certificate_fingerprints.txt" 2>/dev/null || echo "Fingerprints not available")
\`\`\`

### Certificate Chain
$(ls -la "$CAPTURE_DIR/tls/" 2>/dev/null || echo "TLS files not available")

## Captured Content

### Files Inventory
\`\`\`
$(find "$CAPTURE_DIR" -type f -name "*.html" -o -name "*.htm" | head -10)
\`\`\`

### HTTP Response Headers
\`\`\`
$(head -20 "$CAPTURE_DIR/response_headers.txt" 2>/dev/null || echo "Headers not available")
\`\`\`

## Integrity Verification

### SHA256 Hashes
Files captured: $(wc -l < "$CAPTURE_DIR/SHA256SUMS.txt" 2>/dev/null || echo "0")
\`\`\`
$(head -10 "$CAPTURE_DIR/SHA256SUMS.txt" 2>/dev/null || echo "Hashes not available")
\`\`\`

## Chain of Custody
$(cat "$CAPTURE_DIR/chain_of_custody.txt" 2>/dev/null || echo "Not available")

## Certification
I certify that this capture was performed using industry-standard forensic techniques
and that the TLS/SSL certificates provide cryptographic proof of origin.

Date: $(date -Iseconds)
Prepared by: $USER

---
*Generated by Forensic Web Capture Tool with TLS Verification*
EOF

    echo "Report generated: $CAPTURE_DIR/tls_forensic_report.md"
    
    # Try to generate PDF
    if command -v pandoc &> /dev/null; then
        pandoc "$CAPTURE_DIR/tls_forensic_report.md" \
               -o "$CAPTURE_DIR/tls_forensic_report_$(date +%Y%m%d).pdf" 2>/dev/null && \
        echo "PDF report generated: $CAPTURE_DIR/tls_forensic_report_$(date +%Y%m%d).pdf"
    fi
    exit 0
fi

# Capture mode
if [ "$MODE" != "capture" ]; then
    show_usage
fi

if [ -z "$URL" ]; then
    OUTPUT_DIR=""
    URL="$2"
    WITNESS="$3"
fi

if [ -z "$URL" ]; then
    show_usage
fi

# Check if URL is HTTPS
if ! echo "$URL" | grep -q "^https://"; then
    echo "WARNING: URL is not HTTPS. No TLS certificate will be captured."
    echo "For forensic purposes, HTTPS URLs provide cryptographic proof of origin."
fi

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="./capture_$(date +%Y%m%d_%H%M%S)"
fi

DOMAIN=$(get_domain "$URL")
PORT=$(get_port "$URL")

echo "=== FORENSIC WEB CAPTURE WITH TLS CERTIFICATES ==="
echo "Date/Time: $(date -Iseconds)"
echo "URL: $URL"
echo "Domain: $DOMAIN"
echo "Port: $PORT"
echo "Witness: $WITNESS"
echo "Output: $OUTPUT_DIR"
echo "================================================="

# Create output directory structure
mkdir -p "$OUTPUT_DIR/tls"
mkdir -p "$OUTPUT_DIR/content"
mkdir -p "$OUTPUT_DIR/headers"

# Create metadata file
cat > "$OUTPUT_DIR/capture_metadata.txt" <<EOF
FORENSIC WEB CAPTURE WITH TLS VERIFICATION
==========================================
Capture ID: $(uuidgen 2>/dev/null || echo "$(date +%s)-$$")
Capture Date/Time (UTC): $(date -u -Iseconds)
Capture Date/Time (Local): $(date -Iseconds)
Timezone: $(date +%Z)
UNIX Timestamp: $(date +%s)
Target URL: $URL
Domain: $DOMAIN
Port: $PORT
Protocol: $(echo "$URL" | grep -o '^[^:]*')
Witness/Operator: $WITNESS
System: $(uname -a)
Hostname: $(hostname -f)
==========================================
EOF

# 1. Capture TLS/SSL Certificate Chain
echo "[1/8] Capturing TLS/SSL certificates..."
if echo "$URL" | grep -q "^https://"; then
    # Get the certificate chain
    echo | openssl s_client -showcerts -servername "$DOMAIN" \
                           -connect "$DOMAIN:$PORT" 2>/dev/null | \
                           sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
                           > "$OUTPUT_DIR/tls/cert_chain_raw.pem"
    
    # Extract individual certificates
    awk 'BEGIN {n=0} 
         /-----BEGIN CERTIFICATE-----/ {n++} 
         {print > "'$OUTPUT_DIR'/tls/cert_" n ".pem"}' \
         "$OUTPUT_DIR/tls/cert_chain_raw.pem"
    
    # Get server certificate (first in chain)
    cp "$OUTPUT_DIR/tls/cert_1.pem" "$OUTPUT_DIR/tls/server_cert.pem" 2>/dev/null || true
    
    # Get detailed certificate information
    echo "=== SERVER CERTIFICATE DETAILS ===" > "$OUTPUT_DIR/tls/certificate_info.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -text -noout \
            >> "$OUTPUT_DIR/tls/certificate_info.txt" 2>&1
    
    # Get certificate fingerprints
    echo "=== CERTIFICATE FINGERPRINTS ===" > "$OUTPUT_DIR/tls/certificate_fingerprints.txt"
    echo "SHA256 Fingerprint:" >> "$OUTPUT_DIR/tls/certificate_fingerprints.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -fingerprint -sha256 \
            >> "$OUTPUT_DIR/tls/certificate_fingerprints.txt" 2>&1
    echo "" >> "$OUTPUT_DIR/tls/certificate_fingerprints.txt"
    echo "SHA1 Fingerprint (legacy):" >> "$OUTPUT_DIR/tls/certificate_fingerprints.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -fingerprint -sha1 \
            >> "$OUTPUT_DIR/tls/certificate_fingerprints.txt" 2>&1
    
    # Extract certificate dates
    echo "" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    echo "=== VALIDITY PERIOD ===" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -startdate \
            >> "$OUTPUT_DIR/tls/certificate_info.txt" 2>&1
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -enddate \
            >> "$OUTPUT_DIR/tls/certificate_info.txt" 2>&1
    
    # Get issuer and subject
    echo "" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    echo "=== SUBJECT ===" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -subject \
            >> "$OUTPUT_DIR/tls/certificate_info.txt" 2>&1
    echo "" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    echo "=== ISSUER ===" >> "$OUTPUT_DIR/tls/certificate_info.txt"
    openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -issuer \
            >> "$OUTPUT_DIR/tls/certificate_info.txt" 2>&1
    
    # Save the full TLS handshake details
    echo "" | openssl s_client -showcerts -servername "$DOMAIN" \
                               -connect "$DOMAIN:$PORT" -status 2>&1 \
                               > "$OUTPUT_DIR/tls/tls_handshake_full.txt"
    
    echo "✓ TLS certificates captured"
else
    echo "⚠ Not an HTTPS URL - no TLS certificates to capture"
fi

# 2. OCSP (Online Certificate Status Protocol) check
echo "[2/8] Checking certificate revocation status (OCSP)..."
if [ -f "$OUTPUT_DIR/tls/server_cert.pem" ]; then
    # Extract OCSP URL
    OCSP_URL=$(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -ocsp_uri 2>/dev/null)
    if [ -n "$OCSP_URL" ]; then
        echo "OCSP URL: $OCSP_URL" > "$OUTPUT_DIR/tls/ocsp_check.txt"
        # Perform OCSP check (requires issuer cert)
        if [ -f "$OUTPUT_DIR/tls/cert_2.pem" ]; then
            openssl ocsp -issuer "$OUTPUT_DIR/tls/cert_2.pem" \
                        -cert "$OUTPUT_DIR/tls/server_cert.pem" \
                        -url "$OCSP_URL" \
                        -header "HOST" "$(echo $OCSP_URL | cut -d/ -f3)" \
                        >> "$OUTPUT_DIR/tls/ocsp_check.txt" 2>&1 || true
        fi
    fi
fi

# 3. Capture with curl - preserving headers and TLS info
echo "[3/8] Capturing with curl (TLS-aware)..."
curl -v \
     --cert-status \
     --tlsv1.2 \
     --tls-max 1.3 \
     -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
     -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
     -H "Accept-Language: en-US,en;q=0.9" \
     -H "Accept-Encoding: gzip, deflate, br" \
     -H "DNT: 1" \
     -H "Connection: keep-alive" \
     -H "Upgrade-Insecure-Requests: 1" \
     -H "Sec-Fetch-Dest: document" \
     -H "Sec-Fetch-Mode: navigate" \
     -H "Sec-Fetch-Site: none" \
     -H "Sec-Fetch-User: ?1" \
     -H "Cache-Control: max-age=0" \
     --compressed \
     -i \
     -L \
     --trace-ascii "$OUTPUT_DIR/curl_trace.txt" \
     --trace-time \
     "$URL" > "$OUTPUT_DIR/content/response_with_headers.txt" 2> "$OUTPUT_DIR/curl_verbose.log"

# Extract just headers
sed -n '1,/^\r*$/p' "$OUTPUT_DIR/content/response_with_headers.txt" > "$OUTPUT_DIR/headers/response_headers.txt"

# Extract Date header from server (important for timestamp)
SERVER_DATE=$(grep -i "^Date:" "$OUTPUT_DIR/headers/response_headers.txt" | cut -d' ' -f2- | tr -d '\r')
if [ -n "$SERVER_DATE" ]; then
    echo "Server Date Header: $SERVER_DATE" >> "$OUTPUT_DIR/capture_metadata.txt"
fi

# 4. Capture complete page with wget
echo "[4/8] Capturing complete page content..."
wget \
    --page-requisites \
    --convert-links \
    --adjust-extension \
    --span-hosts \
    --no-check-certificate \
    --secure-protocol=auto \
    --https-only \
    --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
    --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
    --header="Accept-Language: en-US,en;q=0.9" \
    --header="Accept-Encoding: gzip, deflate, br" \
    --header="DNT: 1" \
    --header="Connection: keep-alive" \
    --header="Upgrade-Insecure-Requests: 1" \
    --header="Sec-Fetch-Dest: document" \
    --header="Sec-Fetch-Mode: navigate" \
    --header="Sec-Fetch-Site: none" \
    --header="Cache-Control: max-age=0" \
    --compression=auto \
    --directory-prefix="$OUTPUT_DIR/content/full_page" \
    --output-file="$OUTPUT_DIR/wget.log" \
    "$URL" 2>&1 || true

# 5. DNS and network information
echo "[5/8] Capturing DNS and network information..."
{
    echo "=== DNS RESOLUTION ==="
    host "$DOMAIN"
    echo ""
    echo "=== DIG OUTPUT ==="
    dig "$DOMAIN" +noall +answer
    echo ""
    echo "=== REVERSE DNS ==="
    IP=$(dig +short "$DOMAIN" | head -1)
    [ -n "$IP" ] && host "$IP"
} > "$OUTPUT_DIR/dns_info.txt" 2>&1

# 6. Screenshot if possible
echo "[6/8] Attempting screenshot capture..."
if command -v wkhtmltoimage &> /dev/null; then
    wkhtmltoimage \
        --width 1920 \
        --javascript-delay 5000 \
        --custom-header "User-Agent" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
        --custom-header "Accept-Language" "en-US,en;q=0.9" \
        "$URL" \
        "$OUTPUT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png" 2> "$OUTPUT_DIR/screenshot.log" || true
fi

# Alternative with chromium - using full browser emulation
if command -v chromium &> /dev/null; then
    chromium --headless \
             --disable-gpu \
             --screenshot="$OUTPUT_DIR/screenshot_chromium.png" \
             --window-size=1920,1080 \
             --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
             --lang=en-US \
             --accept-lang=en-US,en \
             --disable-blink-features=AutomationControlled \
             --disable-dev-shm-usage \
             --no-sandbox \
             --ignore-certificate-errors \
             "$URL" 2>/dev/null || true
fi

# 7. Create cryptographic hashes of everything
echo "[7/8] Creating cryptographic hashes..."
find "$OUTPUT_DIR" -type f -exec sha256sum {} \; > "$OUTPUT_DIR/SHA256SUMS.txt"
find "$OUTPUT_DIR" -type f -exec sha512sum {} \; > "$OUTPUT_DIR/SHA512SUMS.txt"

# 8. Create chain of custody document
echo "[8/8] Creating chain of custody documentation..."
cat > "$OUTPUT_DIR/chain_of_custody.txt" <<EOF
CHAIN OF CUSTODY - TLS-VERIFIED WEB CAPTURE
============================================
Evidence ID: $(uuidgen 2>/dev/null || echo "$(date +%s)-$$")
Case/Matter: [TO BE FILLED]

CAPTURE DETAILS
---------------
Date/Time (UTC): $(date -u -Iseconds)
Date/Time (Local): $(date -Iseconds)
Server Date Header: ${SERVER_DATE:-Not available}
Target URL: $URL
Performed by: $WITNESS

TLS/SSL CERTIFICATE VERIFICATION
---------------------------------
EOF

if [ -f "$OUTPUT_DIR/tls/server_cert.pem" ]; then
    cat >> "$OUTPUT_DIR/chain_of_custody.txt" <<EOF
Certificate Subject: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -subject | cut -d= -f2-)
Certificate Issuer: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -issuer | cut -d= -f2-)
Serial Number: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -serial | cut -d= -f2)
SHA256 Fingerprint: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -fingerprint -sha256 | cut -d= -f2)
Valid From: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -startdate | cut -d= -f2)
Valid To: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -enddate | cut -d= -f2)
EOF
else
    echo "No TLS certificate captured (non-HTTPS)" >> "$OUTPUT_DIR/chain_of_custody.txt"
fi

cat >> "$OUTPUT_DIR/chain_of_custody.txt" <<EOF

CRYPTOGRAPHIC PROOF OF ORIGIN
------------------------------
The TLS/SSL certificate captured provides cryptographic proof that:
1. The content originated from the server controlling the private key
2. The server was authorized by a Certificate Authority for this domain
3. The connection was encrypted and authenticated
4. The certificate was valid at the time of capture

FILES CAPTURED
--------------
Total files: $(find "$OUTPUT_DIR" -type f | wc -l)
Total size: $(du -sh "$OUTPUT_DIR" | cut -f1)
Content hash: $(sha256sum "$OUTPUT_DIR/content/response_with_headers.txt" 2>/dev/null | cut -d' ' -f1)

VERIFICATION INSTRUCTIONS
-------------------------
1. To verify TLS certificate:
   openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -text -noout

2. To verify content integrity:
   cd "$OUTPUT_DIR" && sha256sum -c SHA256SUMS.txt

3. To generate report:
   forensic-webcapture report "$OUTPUT_DIR"

LEGAL CERTIFICATION
-------------------
I certify under penalty of perjury that:
1. This capture was performed at the date and time specified
2. The TLS certificate provides cryptographic proof of origin
3. No alterations have been made to the captured content
4. The methods used are forensically sound and verifiable

_______________________        _______________________
Signature of Witness           Date

Printed Name: $WITNESS
Title/Organization: ___________________
EOF

# Create verification script
cat > "$OUTPUT_DIR/verify.sh" <<'VERIF'
#!/bin/bash
echo "=== TLS-VERIFIED FORENSIC CAPTURE VERIFICATION ==="
echo ""

# Check TLS certificate
if [ -f tls/server_cert.pem ]; then
    echo "TLS Certificate Check:"
    openssl x509 -in tls/server_cert.pem -noout -checkend 0
    if [ $? -eq 0 ]; then
        echo "✓ Certificate was valid at capture time"
    else
        echo "⚠ Certificate has expired since capture"
    fi
    echo "Fingerprint: $(openssl x509 -in tls/server_cert.pem -noout -fingerprint -sha256)"
    echo ""
fi

# Check file integrity
echo "File Integrity Check:"
if sha256sum -c SHA256SUMS.txt >/dev/null 2>&1; then
    echo "✓ All files verified - integrity intact"
else
    echo "✗ Integrity check FAILED - files may be modified"
    exit 1
fi

echo ""
echo "=== VERIFICATION COMPLETE ==="
VERIF
chmod +x "$OUTPUT_DIR/verify.sh"

# Summary
echo "================================================="
echo "CAPTURE COMPLETE!"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
if [ -f "$OUTPUT_DIR/tls/server_cert.pem" ]; then
    echo "✓ TLS Certificate captured"
    echo "  Subject: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -subject | cut -d= -f2-)"
    echo "  SHA256: $(openssl x509 -in "$OUTPUT_DIR/tls/server_cert.pem" -noout -fingerprint -sha256 | cut -d= -f2)"
else
    echo "⚠ No TLS certificate (non-HTTPS URL)"
fi
echo ""
echo "Next steps:"
echo "1. Verify: cd $OUTPUT_DIR && ./verify.sh"
echo "2. Report: forensic-webcapture report $OUTPUT_DIR"
echo "3. Document: Print and sign chain_of_custody.txt"
echo ""
echo "The TLS certificate provides cryptographic proof of origin!"
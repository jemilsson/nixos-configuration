#!/usr/bin/env bash

# PDF Data Extraction Script
# Extracts data from Adobe LiveCycle/XFA PDFs and generates markdown reports

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check required tools
check_dependencies() {
    local missing_tools=()
    
    for tool in mutool pdftotext pdffonts strings base64 gunzip; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install: poppler-utils mupdf-tools"
        exit 1
    fi
}

# Function to extract basic PDF info
extract_pdf_info() {
    local pdf_file="$1"
    print_status "Extracting basic PDF information..."
    
    # Get PDF info using mutool
    mutool info "$pdf_file" 2>/dev/null || echo "Could not extract PDF info"
}

# Function to extract font information
extract_font_info() {
    local pdf_file="$1"
    print_status "Extracting font information..."
    
    echo "## Font Analysis"
    echo ""
    echo '```'
    pdffonts "$pdf_file" 2>/dev/null || echo "Could not extract font information"
    echo '```'
    echo ""
}

# Function to extract text content
extract_text_content() {
    local pdf_file="$1"
    local temp_dir="$2"
    print_status "Extracting text content..."
    
    # Try standard text extraction
    pdftotext "$pdf_file" "$temp_dir/extracted_text.txt" 2>/dev/null || true
    
    if [ -s "$temp_dir/extracted_text.txt" ]; then
        echo "## Standard Text Extraction"
        echo ""
        echo '```'
        head -20 "$temp_dir/extracted_text.txt"
        if [ $(wc -l < "$temp_dir/extracted_text.txt") -gt 20 ]; then
            echo "... (truncated, see full content in extracted_text.txt)"
        fi
        echo '```'
        echo ""
    else
        print_warning "Standard text extraction yielded no content (likely XFA/LiveCycle PDF)"
    fi
}

# Function to extract XFA data
extract_xfa_data() {
    local pdf_file="$1"
    local temp_dir="$2"
    print_status "Extracting XFA data structures..."
    
    # Clean PDF first
    mutool clean -d "$pdf_file" "$temp_dir/cleaned.pdf" 2>/dev/null || return 1
    
    echo "## XFA Data Extraction"
    echo ""
    
    # Find XFA objects
    local found_xfa=false
    for i in {1..100}; do
        if mutool show "$temp_dir/cleaned.pdf" $i 2>/dev/null | grep -q -i "xml\|xfa\|xdp\|datasets"; then
            found_xfa=true
            echo "### XFA Object $i"
            echo ""
            echo '```xml'
            # Extract and format XML
            mutool show "$temp_dir/cleaned.pdf" $i 2>/dev/null | \
                sed -n '/<?xml\|<xfa:\|<template\|<config/,/endstream/p' | \
                head -50
            echo '```'
            echo ""
            
            # Save full object for further processing
            mutool show "$temp_dir/cleaned.pdf" $i > "$temp_dir/xfa_object_$i.xml" 2>/dev/null || true
        fi
    done
    
    if [ "$found_xfa" = false ]; then
        print_warning "No XFA data structures found"
    fi
}

# Function to extract and decode compressed data
extract_compressed_data() {
    local pdf_file="$1"
    local temp_dir="$2"
    print_status "Extracting compressed template data..."
    
    # Look for base64 encoded data
    if grep -q "FSTEMPLATEBYTES_" "$temp_dir"/xfa_object_*.xml 2>/dev/null; then
        echo "## Compressed Template Data"
        echo ""
        
        # Extract and decode
        for xfa_file in "$temp_dir"/xfa_object_*.xml; do
            if grep -q "FSTEMPLATEBYTES_" "$xfa_file"; then
                print_status "Decoding compressed data from $(basename "$xfa_file")..."
                
                # Extract base64 data and decode
                grep -A 1000 "FSTEMPLATEBYTES_" "$xfa_file" | \
                    sed 's/.*<FSTEMPLATEBYTES_>//' | \
                    sed 's/<\/FSTEMPLATEBYTES_>.*//' | \
                    tr -d '\n\r ' | \
                    base64 -d 2>/dev/null | \
                    gunzip -c 2>/dev/null > "$temp_dir/decoded_template.xml" || true
                
                if [ -s "$temp_dir/decoded_template.xml" ]; then
                    echo "### Decoded Template Content (first 50 lines)"
                    echo ""
                    echo '```xml'
                    head -50 "$temp_dir/decoded_template.xml"
                    echo '```'
                    echo ""
                fi
                break
            fi
        done
    fi
}

# Function to search for specific data types
search_data_patterns() {
    local temp_dir="$1"
    print_status "Searching for specific data patterns..."
    
    echo "## Data Pattern Analysis"
    echo ""
    
    # Search all extracted files
    local search_files=("$temp_dir"/*.xml "$temp_dir"/*.txt)
    
    # IP Addresses
    echo "### IP Addresses"
    echo ""
    local ip_found=false
    for file in "${search_files[@]}"; do
        if [ -f "$file" ]; then
            if grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file" 2>/dev/null; then
                ip_found=true
                echo "**Found in $(basename "$file"):**"
                echo '```'
                grep -E -A 3 -B 3 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file" 2>/dev/null | head -20
                echo '```'
                echo ""
            fi
        fi
    done
    if [ "$ip_found" = false ]; then
        echo "No IP addresses found."
        echo ""
    fi
    
    # Email addresses
    echo "### Email Addresses"
    echo ""
    local email_found=false
    for file in "${search_files[@]}"; do
        if [ -f "$file" ]; then
            if grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null; then
                email_found=true
                echo "**Found in $(basename "$file"):**"
                echo '```'
                grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null | sort -u
                echo '```'
                echo ""
            fi
        fi
    done
    if [ "$email_found" = false ]; then
        echo "No email addresses found."
        echo ""
    fi
    
    # Phone numbers (various formats)
    echo "### Phone Numbers"
    echo ""
    local phone_found=false
    for file in "${search_files[@]}"; do
        if [ -f "$file" ]; then
            if grep -E '(\+?[0-9]{1,3}[-.\s]?)?(\(?[0-9]{3}\)?[-.\s]?)?[0-9]{3}[-.\s]?[0-9]{4}' "$file" 2>/dev/null; then
                phone_found=true
                echo "**Found in $(basename "$file"):**"
                echo '```'
                grep -E -o '(\+?[0-9]{1,3}[-.\s]?)?(\(?[0-9]{3}\)?[-.\s]?)?[0-9]{3}[-.\s]?[0-9]{4}' "$file" 2>/dev/null | sort -u
                echo '```'
                echo ""
            fi
        fi
    done
    if [ "$phone_found" = false ]; then
        echo "No phone numbers found."
        echo ""
    fi
    
    # URLs
    echo "### URLs and File Paths"
    echo ""
    local url_found=false
    for file in "${search_files[@]}"; do
        if [ -f "$file" ]; then
            if grep -E 'https?://[^[:space:]]+|\\\\[^[:space:]]+|[A-Za-z]:\\[^[:space:]]+' "$file" 2>/dev/null; then
                url_found=true
                echo "**Found in $(basename "$file"):**"
                echo '```'
                grep -E -o 'https?://[^[:space:]]+|\\\\[^[:space:]]+|[A-Za-z]:\\[^[:space:]]+' "$file" 2>/dev/null | sort -u | head -10
                echo '```'
                echo ""
            fi
        fi
    done
    if [ "$url_found" = false ]; then
        echo "No URLs or file paths found."
        echo ""
    fi
}

# Function to extract metadata
extract_metadata() {
    local pdf_file="$1"
    print_status "Extracting document metadata..."
    
    echo "## Document Metadata"
    echo ""
    
    # Use strings to find metadata
    echo "### PDF Properties"
    echo ""
    echo '```'
    strings "$pdf_file" | grep -E '^(Creator|Producer|CreationDate|ModDate|Title|Author|Subject)' | head -20
    echo '```'
    echo ""
    
    # Version information
    echo "### Software Versions"
    echo ""
    echo '```'
    strings "$pdf_file" | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -10
    echo '```'
    echo ""
}

# Main function
main() {
    local pdf_file="${1:-}"
    local output_file="${2:-}"
    
    if [ -z "$pdf_file" ]; then
        echo "Usage: $0 <pdf_file> [output_markdown_file]"
        echo "Example: $0 document.pdf extracted_data.md"
        exit 1
    fi
    
    if [ ! -f "$pdf_file" ]; then
        print_error "PDF file not found: $pdf_file"
        exit 1
    fi
    
    # Set default output file
    if [ -z "$output_file" ]; then
        output_file="${pdf_file%.*}_extracted.md"
    fi
    
    print_status "Starting PDF data extraction for: $pdf_file"
    
    # Check dependencies
    check_dependencies
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Start markdown generation
    {
        echo "# PDF Data Extraction Report"
        echo ""
        echo "**Source File:** \`$(basename "$pdf_file")\`"
        echo "**Extraction Date:** $(date -I)"
        echo "**Full Path:** \`$pdf_file\`"
        echo ""
        
        # Extract all data types
        extract_metadata "$pdf_file"
        extract_font_info "$pdf_file"
        extract_text_content "$pdf_file" "$temp_dir"
        extract_xfa_data "$pdf_file" "$temp_dir"
        extract_compressed_data "$pdf_file" "$temp_dir"
        search_data_patterns "$temp_dir"
        
        echo "## Technical Details"
        echo ""
        echo "### PDF Structure Information"
        echo ""
        echo '```'
        extract_pdf_info "$pdf_file"
        echo '```'
        echo ""
        
        echo "## Extraction Methods Used"
        echo ""
        echo "1. **Basic Info:** \`mutool info\`"
        echo "2. **Font Analysis:** \`pdffonts\`"
        echo "3. **Text Extraction:** \`pdftotext\`"
        echo "4. **XFA Data:** \`mutool show\` + \`mutool clean\`"
        echo "5. **Compressed Data:** Base64 decode + gzip decompress"
        echo "6. **Pattern Matching:** Regular expressions for IPs, emails, etc."
        echo "7. **Metadata:** \`strings\` command analysis"
        echo ""
        
        echo "## Files Generated"
        echo ""
        echo "- \`extracted_text.txt\` - Standard text extraction results"
        echo "- \`cleaned.pdf\` - Decompressed PDF structure"
        echo "- \`xfa_object_*.xml\` - Individual XFA data objects"
        echo "- \`decoded_template.xml\` - Decompressed template data"
        echo ""
        
        echo "---"
        echo "*Report generated by PDF Data Extraction Script*"
        echo "*$(date)*"
        
    } > "$output_file"
    
    print_success "Extraction complete! Report saved to: $output_file"
    print_status "Temporary files cleaned up automatically"
}

# Run main function with all arguments
main "$@"
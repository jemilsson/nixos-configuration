#!/usr/bin/env bash

# Simple PDF Data Extraction Script
# Creates markdown reports from XFA/LiveCycle PDFs

set -euo pipefail

main() {
    local pdf_file="${1:-}"
    local output_file="${2:-extracted_data.md}"
    
    if [ -z "$pdf_file" ] || [ ! -f "$pdf_file" ]; then
        echo "Usage: $0 <pdf_file> [output_file]"
        exit 1
    fi
    
    echo "Extracting data from: $pdf_file" >&2
    
    # Create temp directory
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Generate markdown report
    {
        echo "# PDF Data Extraction Report"
        echo ""
        echo "**Source:** \`$(basename "$pdf_file")\`  "
        echo "**Date:** $(date -I)  "
        echo "**Path:** \`$pdf_file\`"
        echo ""
        
        # Document metadata
        echo "## Document Information"
        echo ""
        if command -v mutool &> /dev/null; then
            echo "### PDF Structure"
            echo '```'
            mutool info "$pdf_file" 2>/dev/null || echo "Could not extract PDF info"
            echo '```'
            echo ""
        fi
        
        # Font information
        if command -v pdffonts &> /dev/null; then
            echo "### Fonts Used"
            echo '```'
            pdffonts "$pdf_file" 2>/dev/null || echo "Could not extract font info"
            echo '```'
            echo ""
        fi
        
        # Standard text extraction
        echo "## Text Content"
        echo ""
        if command -v pdftotext &> /dev/null; then
            pdftotext "$pdf_file" "$temp_dir/text.txt" 2>/dev/null || true
            if [ -s "$temp_dir/text.txt" ]; then
                echo "### Standard Text Extraction"
                echo '```'
                head -20 "$temp_dir/text.txt"
                echo '```'
                echo ""
            else
                echo "*Standard text extraction yielded no content (likely XFA/LiveCycle PDF)*"
                echo ""
            fi
        fi
        
        # XFA data extraction
        echo "## XFA Data Structures"
        echo ""
        if command -v mutool &> /dev/null; then
            mutool clean -d "$pdf_file" "$temp_dir/clean.pdf" 2>/dev/null || true
            
            local found_data=false
            for i in {1..50}; do
                if mutool show "$temp_dir/clean.pdf" $i 2>/dev/null | grep -q -i "xml\|xfa\|datasets"; then
                    found_data=true
                    echo "### Data Object $i"
                    echo '```xml'
                    mutool show "$temp_dir/clean.pdf" $i 2>/dev/null | head -30
                    echo '```'
                    echo ""
                    
                    # Save object for pattern search
                    mutool show "$temp_dir/clean.pdf" $i > "$temp_dir/obj_$i.xml" 2>/dev/null || true
                fi
            done
            
            if [ "$found_data" = false ]; then
                echo "*No XFA data structures found*"
                echo ""
            fi
        fi
        
        # Pattern search
        echo "## Data Analysis"
        echo ""
        
        # Search all temp files
        local search_files=("$temp_dir"/*.txt "$temp_dir"/*.xml)
        
        # IP addresses
        echo "### IP Addresses Found"
        local found_ips=false
        for file in "${search_files[@]}"; do
            if [ -f "$file" ] && grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file" 2>/dev/null; then
                found_ips=true
                echo "**In $(basename "$file"):**"
                echo '```'
                grep -E -A 2 -B 2 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file" 2>/dev/null | head -10
                echo '```'
                echo ""
            fi
        done
        if [ "$found_ips" = false ]; then
            echo "No IP addresses found."
        fi
        echo ""
        
        # Email addresses
        echo "### Email Addresses Found"
        local found_emails=false
        for file in "${search_files[@]}"; do
            if [ -f "$file" ] && grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null; then
                found_emails=true
                echo "**In $(basename "$file"):**"
                echo '```'
                grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null | sort -u
                echo '```'
                echo ""
            fi
        done
        if [ "$found_emails" = false ]; then
            echo "No email addresses found."
        fi
        echo ""
        
        # URLs and paths
        echo "### URLs and File Paths"
        local found_urls=false
        for file in "${search_files[@]}"; do
            if [ -f "$file" ] && grep -E 'https?://[^[:space:]]+|\\\\[^[:space:]]+' "$file" 2>/dev/null; then
                found_urls=true
                echo "**In $(basename "$file"):**"
                echo '```'
                grep -E -o 'https?://[^[:space:]]+|\\\\[^[:space:]]+' "$file" 2>/dev/null | sort -u | head -5
                echo '```'
                echo ""
            fi
        done
        if [ "$found_urls" = false ]; then
            echo "No URLs or network paths found."
        fi
        echo ""
        
        # Binary string search for additional patterns
        echo "### Additional Metadata"
        echo '```'
        strings "$pdf_file" | grep -E 'Creator|Producer|Version' | head -10
        echo '```'
        echo ""
        
        echo "---"
        echo "*Report generated by Simple PDF Extraction Script*  "
        echo "*$(date)*"
        
    } > "$output_file"
    
    echo "Report saved to: $output_file" >&2
}

main "$@"
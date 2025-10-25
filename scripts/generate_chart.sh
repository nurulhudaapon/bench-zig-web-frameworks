#!/bin/bash

# ============================================
# Generate ASCII Bar Chart from Benchmark Results
# ============================================

FRAMEWORKS=("std" "zap" "httpz" "zinc")

# Function to generate bar chart
generate_chart() {
    local chart_content=""
    local max_rps=0
    local max_bar_length=50  # Maximum bar length in characters
    
    # Arrays to store framework data
    local -a rps_values=()
    
    # First pass: collect all RPS values and find maximum
    for framework in "${FRAMEWORKS[@]}"; do
        local latest_file=$(ls -t "results/${framework}"/bench_*.json 2>/dev/null | head -1)
        
        if [ -f "$latest_file" ]; then
            local rps=$(jq -r '.summary.requestsPerSec' "$latest_file")
            rps_values+=("$rps")
            
            # Find maximum RPS for scaling
            if [ $(awk -v a="$rps" -v b="$max_rps" 'BEGIN {print (a > b)}') -eq 1 ]; then
                max_rps="$rps"
            fi
        else
            rps_values+=("0")
        fi
    done
    
    # Generate chart
    chart_content+="\`\`\`\n"
    
    # Second pass: generate bars for each framework
    local idx=0
    for framework in "${FRAMEWORKS[@]}"; do
        local rps="${rps_values[$idx]}"
        idx=$((idx + 1))
        
        if [ "$rps" = "0" ] || [ -z "$rps" ]; then
            continue
        fi
        
        # Calculate bar length (proportional to max)
        # Using awk for better floating point math
        local bar_length=$(awk -v rps="$rps" -v max="$max_rps" -v maxlen="$max_bar_length" 'BEGIN {printf "%.0f", (rps / max) * maxlen}')
        
        # Ensure minimum bar length of 1 for visibility
        if [ "$bar_length" -lt 1 ]; then
            bar_length=1
        fi
        
        # Format RPS with thousand separators
        local formatted_rps=$(printf "%'.0f" "$rps" 2>/dev/null || printf "%.0f" "$rps")
        
        # Pad framework name for alignment
        local padded_name=$(printf "%-8s" "$framework")
        
        # Generate bar using Unicode block characters
        local bar=""
        for ((i=0; i<bar_length; i++)); do
            bar+="█"
        done
        
        # Add to chart content
        chart_content+="${padded_name} │${bar} ${formatted_rps} req/s\n"
    done
    
    chart_content+="\`\`\`\n"
    
    # Output the chart
    echo -e "$chart_content"
}

# Main execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo "Generates an ASCII bar chart from benchmark results in results/ directory"
    exit 0
fi

generate_chart

#!/bin/bash

# ============================================
# Configuration - Add/remove frameworks here
# ============================================
FRAMEWORKS=(
    "std"
    "zap"
    "httpz"
    "zinc"
)

# Benchmark settings
REQUESTS=10000
CONCURRENCY=100
PORT=8081
ENDPOINT="/httpz/"

# Execution mode: "docker" or "local"
# Can be set via environment variable: MODE=local ./scripts/bench.sh
MODE=${MODE:-"local"}

# ============================================
# Functions
# ============================================

# Function to save machine information to results/machine.json
save_machine_info() {
    local machine_file="results/machine.json"
    local os_name=$(uname -s)
    local os_version=$(uname -r)
    local arch=$(uname -m)
    local hostname=$(hostname)
    local cpu_info=""
    local cpu_cores=""
    local total_memory=""
    
    # Collect CPU and memory info based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        cpu_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
        total_memory=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
    else
        # Linux
        cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs 2>/dev/null || echo "Unknown")
        cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "Unknown")
        total_memory=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}' 2>/dev/null || echo 0) / 1024 / 1024 ))
    fi
    
    # Write machine info to file
    cat > "$machine_file" <<EOF
{
  "hostname": "$hostname",
  "os": {
    "name": "$os_name",
    "version": "$os_version",
    "arch": "$arch"
  },
  "cpu": {
    "model": "$cpu_info",
    "cores": $cpu_cores
  },
  "memory": {
    "totalGB": $total_memory
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mode": "$MODE"
}
EOF
    
    echo "Machine information saved to: $machine_file"
}

# Function to update README with benchmark results
update_readme() {
    echo ""
    echo "================================================"
    echo "Updating README with results..."
    echo "================================================"
    
    local readme_file="README.md"
    local machine_file="results/machine.json"
    
    # Read machine info
    local cpu_model=$(jq -r '.cpu.model' "$machine_file")
    local cpu_cores=$(jq -r '.cpu.cores' "$machine_file")
    local memory=$(jq -r '.memory.totalGB' "$machine_file")
    local os_name=$(jq -r '.os.name' "$machine_file")
    local os_arch=$(jq -r '.os.arch' "$machine_file")
    local mode=$(jq -r '.mode' "$machine_file")
    
    # Build the table content
    local table_content="### Results\n\n"
    table_content+="| Framework | Requests/sec |\n"
    table_content+="|-----------|-------------:|\n"
    
    # Collect results from each framework (get the latest file)
    for framework in "${FRAMEWORKS[@]}"; do
        local latest_file=$(ls -t "results/${framework}"/bench_*.json 2>/dev/null | head -1)
        
        if [ -f "$latest_file" ]; then
            local rps=$(jq -r '.summary.requestsPerSec' "$latest_file")
            # Format with thousand separators
            local formatted_rps=$(printf "%'.2f" "$rps" 2>/dev/null || echo "$rps")
            table_content+="| ${framework} | ${formatted_rps} |\n"
        else
            echo "  ⚠ Warning: No results found for ${framework}"
        fi
    done
    
    # Add machine info in italic
    table_content+="\n*Machine: ${cpu_model} (${cpu_cores} cores), ${memory}GB RAM, ${os_name} ${os_arch}, Mode: ${mode}*\n"
    
    # Find where to insert/replace in README
    # We'll replace everything after "### Results"
    local temp_file=$(mktemp)
    
    # Get content before "### Results" (excluding the "### Results" line itself)
    awk '/^### Results/{exit} {print}' "$readme_file" > "$temp_file"
    
    # Add the new table
    echo -e "$table_content" >> "$temp_file"
    
    # Replace README
    mv "$temp_file" "$readme_file"
    
    echo "  ✓ README updated with benchmark results"
}

# Function to benchmark a single framework
benchmark_framework() {
    local framework=$1
    local server_pid=""
    
    echo ""
    echo "================================================"
    echo "Benchmarking ${framework}..."
    echo "================================================"
    
    if [ "$MODE" = "local" ]; then
        # Local mode: run binary directly
        local binary="./zig-out/bin/bench_${framework}"
        
        if [ ! -f "$binary" ]; then
            echo "  ✗ Error: Binary not found: $binary"
            echo "  → Please run ./scripts/build.sh first"
            return 1
        fi
        
        echo "  → Starting local server ($binary)..."
        "$binary" &
        server_pid=$!
        
        # Wait for service to be ready
        echo "  → Waiting for service to be ready..."
        sleep 3
        
        # Check if process is still running
        if ! kill -0 $server_pid 2>/dev/null; then
            echo "  ✗ Error: Server failed to start"
            return 1
        fi
        
    else
        # Docker mode: run container
        local container_name="bench_${framework}"
        local image_name="bench_zig/${framework}"
        
        # Clean up any existing container
        docker rm -f "$container_name" 2>/dev/null || true
        
        # Start the container
        echo "  → Starting container..."
        docker run -d -p "${PORT}:${PORT}" --name "$container_name" "$image_name"
        
        # Wait for service to be ready
        echo "  → Waiting for service to be ready..."
        sleep 2
    fi
    
    # Run benchmark with oha
    echo "  → Running benchmark (${REQUESTS} requests, ${CONCURRENCY} concurrent)..."
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    local json_file="results/${framework}/bench_${TIMESTAMP}.json"
    
    # Run oha with JSON output directly to final file
    oha -n "$REQUESTS" -c "$CONCURRENCY" \
        --output-format json \
        -o "$json_file" \
        "http://localhost:${PORT}${ENDPOINT}"
    
    echo "  → Results saved to: $json_file"
    
    # Clean up
    echo "  → Cleaning up..."
    if [ "$MODE" = "local" ]; then
        # Kill local server
        if [ -n "$server_pid" ] && kill -0 $server_pid 2>/dev/null; then
            kill $server_pid
            wait $server_pid 2>/dev/null || true
        fi
    else
        # Stop docker container
        docker stop "$container_name" >/dev/null 2>&1
        # docker rm "$container_name" >/dev/null 2>&1
    fi
    
    echo "  ✓ Completed"
}

# ============================================
# Main execution
# ============================================

echo "============================================"
echo "Zig Web Framework Benchmark Suite"
echo "============================================"
echo "Mode: ${MODE}"
echo "Frameworks: ${FRAMEWORKS[*]}"
echo "Requests: ${REQUESTS}"
echo "Concurrency: ${CONCURRENCY}"
echo "============================================"

# Create results directory
mkdir -p results

# Save machine information once
save_machine_info
echo ""

# Create result directories for all frameworks
for framework in "${FRAMEWORKS[@]}"; do
    mkdir -p "results/${framework}"
done

# Run benchmarks for all frameworks
for framework in "${FRAMEWORKS[@]}"; do
    benchmark_framework "$framework"
done

echo ""
echo "============================================"
echo "All benchmarks completed!"
echo "Results saved in results/ directory"
echo "Machine info: results/machine.json"
echo "============================================"

# Update README with results
update_readme

echo ""
echo "============================================"
echo "✓ Benchmark suite finished successfully!"
echo "============================================"
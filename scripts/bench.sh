#!/bin/bash

# ============================================
# Configuration - Add/remove frameworks here
# ============================================
FRAMEWORKS=(
    "zap"
    "httpz"
    # "zinc"
)

# Benchmark settings
REQUESTS=10000
CONCURRENCY=100
PORT=8081
ENDPOINT="/httpz/"

# ============================================
# Functions
# ============================================

# Function to parse ab summary output to CSV
parse_summary_to_csv() {
    local framework=$1
    local timestamp=$2
    local csv_file="results/${framework}/bench_${timestamp}.csv"
    local temp_file="/tmp/bench_${framework}_${timestamp}.txt"
    
    # Create CSV with summary statistics
    {
        echo "Metric,Value,Unit"
        grep "^Server Software:" "$temp_file" | sed 's/Server Software:[ ]*//' | awk '{print "Server Software,"$0","}' 
        grep "^Complete requests:" "$temp_file" | sed 's/Complete requests:[ ]*//' | awk '{print "Complete requests,"$0",requests"}'
        grep "^Failed requests:" "$temp_file" | sed 's/Failed requests:[ ]*//' | awk '{print "Failed requests,"$0",requests"}'
        grep "^Total transferred:" "$temp_file" | sed 's/Total transferred:[ ]*//' | awk '{print "Total transferred,"$1",bytes"}'
        grep "^HTML transferred:" "$temp_file" | sed 's/HTML transferred:[ ]*//' | awk '{print "HTML transferred,"$1",bytes"}'
        grep "^Requests per second:" "$temp_file" | sed 's/Requests per second:[ ]*//' | awk '{print "Requests per second,"$1",req/s"}'
        grep "^Time per request:" "$temp_file" | head -1 | sed 's/Time per request:[ ]*//' | awk '{print "Time per request (mean),"$1",ms"}'
        grep "^Time per request:" "$temp_file" | tail -1 | sed 's/Time per request:[ ]*//' | awk '{print "Time per request (mean, across all),"$1",ms"}'
        grep "^Transfer rate:" "$temp_file" | sed 's/Transfer rate:[ ]*//' | awk '{print "Transfer rate,"$1",KB/s"}'
        
        # Connection Times
        echo ""
        echo "Connection Times (ms),min,mean,median,max"
        grep -A 4 "Connection Times (ms)" "$temp_file" | grep "Connect:" | awk '{print "Connect,"$2","$3","$4","$5}'
        grep -A 4 "Connection Times (ms)" "$temp_file" | grep "Processing:" | awk '{print "Processing,"$2","$3","$4","$5}'
        grep -A 4 "Connection Times (ms)" "$temp_file" | grep "Waiting:" | awk '{print "Waiting,"$2","$3","$4","$5}'
        grep -A 4 "Connection Times (ms)" "$temp_file" | grep "Total:" | awk '{print "Total,"$2","$3","$4","$5}'
        
        # Percentiles
        echo ""
        echo "Percentile,Time (ms)"
        grep "50%" "$temp_file" | awk '{print "50%,"$2}'
        grep "66%" "$temp_file" | awk '{print "66%,"$2}'
        grep "75%" "$temp_file" | awk '{print "75%,"$2}'
        grep "80%" "$temp_file" | awk '{print "80%,"$2}'
        grep "90%" "$temp_file" | awk '{print "90%,"$2}'
        grep "95%" "$temp_file" | awk '{print "95%,"$2}'
        grep "98%" "$temp_file" | awk '{print "98%,"$2}'
        grep "99%" "$temp_file" | awk '{print "99%,"$2}'
        grep "100%" "$temp_file" | awk '{print "100%,"$2}'
    } > "$csv_file"
    
    rm "$temp_file"
    echo "  → Results saved to: $csv_file"
}

# Function to benchmark a single framework
benchmark_framework() {
    local framework=$1
    local container_name="bench_${framework}"
    local image_name="bench_zig/${framework}"
    
    echo ""
    echo "================================================"
    echo "Benchmarking ${framework}..."
    echo "================================================"
    
    # Clean up any existing container
    docker rm -f "$container_name" 2>/dev/null || true
    
    # Start the container
    echo "  → Starting container..."
    docker run -d -p "${PORT}:80" --name "$container_name" "$image_name"
    
    # Wait for service to be ready
    echo "  → Waiting for service to be ready..."
    sleep 2
    
    # Run benchmark
    echo "  → Running benchmark (${REQUESTS} requests, ${CONCURRENCY} concurrent)..."
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    ab -n "$REQUESTS" -c "$CONCURRENCY" "http://localhost:${PORT}${ENDPOINT}" > "/tmp/bench_${framework}_${TIMESTAMP}.txt" 2>&1
    
    # Parse results to CSV
    parse_summary_to_csv "$framework" "$TIMESTAMP"
    
    # Clean up container
    echo "  → Cleaning up..."
    docker stop "$container_name" >/dev/null 2>&1
    docker rm "$container_name" >/dev/null 2>&1
    
    echo "  ✓ Completed"
}

# ============================================
# Main execution
# ============================================

echo "============================================"
echo "Zig Web Framework Benchmark Suite"
echo "============================================"
echo "Frameworks: ${FRAMEWORKS[*]}"
echo "Requests: ${REQUESTS}"
echo "Concurrency: ${CONCURRENCY}"
echo "============================================"

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
echo "============================================"
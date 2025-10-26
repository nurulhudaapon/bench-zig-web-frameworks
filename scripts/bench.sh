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
REQUESTS=1000000
CONCURRENCY=100
PORT=8081
ENDPOINT="/httpz"

# Execution mode: "docker" or "local"
# Can be set via environment variable: MODE=local ./scripts/bench.sh
MODE=${MODE:-"local"}

# ============================================
# Functions
# ============================================

# Function to kill any process using the port
kill_port_process() {
  local port=$1
  echo "  → Checking for processes on port ${port}..."
  
  # Try lsof first (more reliable)
  if command -v lsof &> /dev/null; then
    local pids=$(lsof -ti :${port} 2>/dev/null)
    if [ -n "$pids" ]; then
      echo "  → Killing processes on port ${port}: $pids"
      echo "$pids" | xargs kill -9 2>/dev/null || true
      sleep 1
    fi
  else
    # Fallback to fuser if lsof not available
    if command -v fuser &> /dev/null; then
      fuser -k ${port}/tcp 2>/dev/null || true
      sleep 1
    fi
  fi
}

# Function to wait for port to become available
wait_for_port_free() {
  local port=$1
  local max_wait=10
  local waited=0
  
  while [ $waited -lt $max_wait ]; do
    if ! nc -z localhost $port 2>/dev/null && ! lsof -i :$port >/dev/null 2>&1; then
      return 0
    fi
    echo "  → Port ${port} still in use, waiting... (${waited}s)"
    sleep 1
    waited=$((waited + 1))
  done
  
  echo "  ⚠ Warning: Port ${port} still in use after ${max_wait}s"
  return 1
}

# Function to wait for port to become ready
wait_for_port_ready() {
  local port=$1
  local max_wait=10
  local waited=0
  
  while [ $waited -lt $max_wait ]; do
    if nc -z localhost $port 2>/dev/null; then
      echo "  → Service is ready on port ${port}"
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  
  echo "  ✗ Error: Service not ready on port ${port} after ${max_wait}s"
  return 1
}

# Function to save machine information to results/machine.json
save_machine_info() {
  local machine_file="results/machine.json"
  local os_name=$(uname -s)
  local os_version=$(uname -r)
  local arch=$(uname -m)
  local hostname=$(hostname)
  local cpu_info=""
  local cpu_cores=""
  local cpu_physical_cores=""
  local total_memory=""
  local available_memory=""
  local cpu_freq_current=""
  local cpu_freq_min=""
  local cpu_freq_max=""
  local cpu_cache_l1=""
  local cpu_cache_l2=""
  local cpu_cache_l3=""
  local cpu_flags=""
  local cpu_governor=""
  local kernel_version=""

  # Collect CPU and memory info based on OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    cpu_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
    cpu_physical_cores=$(sysctl -n hw.physicalcpu 2>/dev/null || echo "Unknown")
    total_memory=$(($(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024))
    available_memory=$(($(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.' 2>/dev/null || echo 0) * 4096 / 1024 / 1024 / 1024))
    cpu_freq_current=$(sysctl -n hw.cpufrequency 2>/dev/null || echo "0")
    cpu_freq_min=$(sysctl -n hw.cpufrequency_min 2>/dev/null || echo "0")
    cpu_freq_max=$(sysctl -n hw.cpufrequency_max 2>/dev/null || echo "0")
    cpu_cache_l1=$(sysctl -n hw.l1icachesize 2>/dev/null || echo "0")
    cpu_cache_l2=$(sysctl -n hw.l2cachesize 2>/dev/null || echo "0")
    cpu_cache_l3=$(sysctl -n hw.l3cachesize 2>/dev/null || echo "0")
    kernel_version=$(uname -v)
  else
    # Linux
    # Try different CPU info fields (x86 vs ARM)
    cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs 2>/dev/null)
    if [ -z "$cpu_info" ]; then
      # ARM fallback: try Hardware, Model, or CPU implementer/part
      cpu_info=$(grep "^Hardware" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs 2>/dev/null)
      if [ -z "$cpu_info" ]; then
        cpu_info=$(grep "^Model" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs 2>/dev/null)
      fi
      if [ -z "$cpu_info" ]; then
        # Try to identify ARM CPU from implementer and part
        local cpu_part=$(grep "CPU part" /proc/cpuinfo | head -1 | awk '{print $NF}' 2>/dev/null)
        case "$cpu_part" in
          "0xd03") cpu_info="ARM Cortex-A53" ;;
          "0xd04") cpu_info="ARM Cortex-A35" ;;
          "0xd05") cpu_info="ARM Cortex-A55" ;;
          "0xd07") cpu_info="ARM Cortex-A57" ;;
          "0xd08") cpu_info="ARM Cortex-A72" ;;
          "0xd09") cpu_info="ARM Cortex-A73" ;;
          "0xd0a") cpu_info="ARM Cortex-A75" ;;
          "0xd0b") cpu_info="ARM Cortex-A76" ;;
          "0xd0c") cpu_info="ARM Neoverse N1" ;;
          "0xd0d") cpu_info="ARM Cortex-A77" ;;
          "0xd0e") cpu_info="ARM Cortex-A76AE" ;;
          "0xd40") cpu_info="ARM Neoverse V1" ;;
          "0xd41") cpu_info="ARM Cortex-A78" ;;
          "0xd44") cpu_info="ARM Cortex-X1" ;;
          "0xd46") cpu_info="ARM Cortex-A510" ;;
          "0xd47") cpu_info="ARM Cortex-A710" ;;
          "0xd48") cpu_info="ARM Cortex-X2" ;;
          "0xd49") cpu_info="ARM Neoverse N2" ;;
          "0xd4a") cpu_info="ARM Neoverse E1" ;;
          "0xd4b") cpu_info="ARM Cortex-A78AE" ;;
          "0xd4c") cpu_info="ARM Cortex-X1C" ;;
          "0xd4d") cpu_info="ARM Cortex-A715" ;;
          "0xd4e") cpu_info="ARM Cortex-X3" ;;
          *)
            local cpu_impl=$(grep "CPU implementer" /proc/cpuinfo | head -1 | awk '{print $NF}' 2>/dev/null)
            if [ -n "$cpu_impl" ] && [ -n "$cpu_part" ]; then
              cpu_info="ARM CPU (impl: $cpu_impl, part: $cpu_part)"
            else
              cpu_info="Unknown CPU"
            fi
            ;;
        esac
      fi
    fi
    
    cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
    
    # Try to get physical cores (x86), fallback to logical cores
    cpu_physical_cores=$(grep "^cpu cores" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs 2>/dev/null)
    if [ -z "$cpu_physical_cores" ] || [ "$cpu_physical_cores" = "0" ]; then
      # ARM or no hyperthreading - use logical cores
      cpu_physical_cores="$cpu_cores"
    fi
    
    total_memory=$(($(grep MemTotal /proc/meminfo | awk '{print $2}' 2>/dev/null || echo 0) / 1024 / 1024))
    available_memory=$(($(grep MemAvailable /proc/meminfo | awk '{print $2}' 2>/dev/null || echo 0) / 1024 / 1024))
    
    # CPU frequency in MHz (convert to Hz for consistency)
    cpu_freq_current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "0")
    cpu_freq_min=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo "0")
    cpu_freq_max=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo "0")
    
    # Convert kHz to MHz
    if [ "$cpu_freq_current" != "0" ]; then
      cpu_freq_current=$((cpu_freq_current / 1000))
    fi
    if [ "$cpu_freq_min" != "0" ]; then
      cpu_freq_min=$((cpu_freq_min / 1000))
    fi
    if [ "$cpu_freq_max" != "0" ]; then
      cpu_freq_max=$((cpu_freq_max / 1000))
    fi
    
    # CPU cache sizes (in KB)
    # L1: Try /proc/cpuinfo first, then sysfs
    cpu_cache_l1=$(grep "cache size" /proc/cpuinfo | head -1 | awk '{print $4}' 2>/dev/null)
    if [ -z "$cpu_cache_l1" ] || [ "$cpu_cache_l1" = "0" ]; then
      cpu_cache_l1=$(cat /sys/devices/system/cpu/cpu0/cache/index0/size 2>/dev/null | sed 's/K//')
    fi
    [ -z "$cpu_cache_l1" ] && cpu_cache_l1="0"
    
    # L2 and L3 from sysfs
    cpu_cache_l2=$(cat /sys/devices/system/cpu/cpu0/cache/index2/size 2>/dev/null | sed 's/K//' || echo "0")
    cpu_cache_l3=$(cat /sys/devices/system/cpu/cpu0/cache/index3/size 2>/dev/null | sed 's/K//' || echo "0")
    
    # CPU flags/features (x86: flags, ARM: Features)
    cpu_flags=$(grep "^flags" /proc/cpuinfo | head -1 | cut -d: -f2 | tr ' ' '\n' | grep -E "(sse|avx|aes|fma)" | head -10 | tr '\n' ',' | sed 's/,$//' 2>/dev/null)
    if [ -z "$cpu_flags" ]; then
      # ARM: try Features
      cpu_flags=$(grep "^Features" /proc/cpuinfo | head -1 | cut -d: -f2 | tr ' ' '\n' | grep -E "(neon|crypto|asimd|aes|sha|crc)" | head -10 | tr '\n' ',' | sed 's/,$//' 2>/dev/null || echo "")
    fi
    
    # CPU governor
    cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown")
    
    # Kernel version
    kernel_version=$(uname -v)
  fi

  # Write machine info to file with enhanced details
  cat >"$machine_file" <<EOF
{
  "hostname": "$hostname",
  "os": {
    "name": "$os_name",
    "version": "$os_version",
    "arch": "$arch",
    "kernel": "$kernel_version"
  },
  "cpu": {
    "model": "$cpu_info",
    "cores": {
      "logical": $cpu_cores,
      "physical": $cpu_physical_cores
    },
    "frequency": {
      "current_mhz": $cpu_freq_current,
      "min_mhz": $cpu_freq_min,
      "max_mhz": $cpu_freq_max
    },
    "cache": {
      "l1_kb": $cpu_cache_l1,
      "l2_kb": $cpu_cache_l2,
      "l3_kb": $cpu_cache_l3
    },
    "flags": "$cpu_flags",
    "governor": "$cpu_governor"
  },
  "memory": {
    "total_gb": $total_memory,
    "available_gb": $available_memory
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mode": "$MODE"
}
EOF

  echo "Machine information saved to: $machine_file"
  echo ""
  echo "System Details:"
  echo "  CPU: $cpu_info"
  echo "  Cores: $cpu_cores logical ($cpu_physical_cores physical)"
  echo "  Frequency: Current=${cpu_freq_current}MHz, Min=${cpu_freq_min}MHz, Max=${cpu_freq_max}MHz"
  echo "  Cache: L1=${cpu_cache_l1}KB, L2=${cpu_cache_l2}KB, L3=${cpu_cache_l3}KB"
  echo "  Governor: $cpu_governor"
  echo "  Memory: ${total_memory}GB total, ${available_memory}GB available"
}

# Function to generate bar chart
generate_chart() {
  local max_rps=0
  local max_bar_length=50
  local -a rps_values=()
  local chart_content=""

  # First pass: collect all RPS values and find maximum
  for framework in "${FRAMEWORKS[@]}"; do
    local latest_file=$(ls -t "results/${framework}"/bench.json 2>/dev/null | head -1)

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
    for ((i = 0; i < bar_length; i++)); do
      bar+="█"
    done

    # Add to chart content
    chart_content+="${padded_name} │${bar} ${formatted_rps} req/s\n"
  done

  chart_content+="\`\`\`\n"

  # Return the chart content
  echo -e "$chart_content"
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
  local cpu_cores_logical=$(jq -r '.cpu.cores.logical' "$machine_file")
  local cpu_cores_physical=$(jq -r '.cpu.cores.physical' "$machine_file")
  local cpu_freq_max=$(jq -r '.cpu.frequency.max_mhz' "$machine_file")
  local cpu_cache_l3=$(jq -r '.cpu.cache.l3_kb' "$machine_file")
  local cpu_governor=$(jq -r '.cpu.governor' "$machine_file")
  local memory=$(jq -r '.memory.total_gb' "$machine_file")
  local os_name=$(jq -r '.os.name' "$machine_file")
  local os_arch=$(jq -r '.os.arch' "$machine_file")
  local mode=$(jq -r '.mode' "$machine_file")

  # Build the results content with bar chart
  local results_content="### Results\n\n"

  # Generate and add bar chart
  results_content+="$(generate_chart)"

  # Add machine info in italic below the chart with enhanced details
  results_content+="\n*Machine: ${cpu_model} @ ${cpu_freq_max}MHz (${cpu_cores_logical} cores / ${cpu_cores_physical} physical)"
  if [ "$cpu_cache_l3" != "0" ] && [ "$cpu_cache_l3" != "null" ]; then
    results_content+=", L3: ${cpu_cache_l3}KB"
  fi
  results_content+=", ${memory}GB RAM, ${os_name} ${os_arch}"
  if [ "$cpu_governor" != "Unknown" ] && [ "$cpu_governor" != "null" ]; then
    results_content+=", Governor: ${cpu_governor}"
  fi
  results_content+=", Mode: ${mode}*\n"

  # Find where to insert/replace in README
  # We'll replace everything after "### Results"
  local temp_file=$(mktemp)

  # Get content before "### Results" (excluding the "### Results" line itself)
  awk '/^### Results/{exit} {print}' "$readme_file" >"$temp_file"

  # Add the new results content
  echo -e "$results_content" >>"$temp_file"

  # Replace README
  mv "$temp_file" "$readme_file"

  echo "  ✓ README updated with benchmark results chart"
}

# Function to benchmark a single framework
benchmark_framework() {
  local framework=$1
  local server_pid=""

  echo ""
  echo "================================================"
  echo "Benchmarking ${framework}..."
  echo "================================================"

  # Ensure port is free before starting
  kill_port_process "$PORT"
  wait_for_port_free "$PORT"

  if [ "$MODE" = "local" ]; then
    # Local mode: run binary directly
    local binary="./zig-out/bin/bench_${framework}"

    if [ ! -f "$binary" ]; then
      echo "  ✗ Error: Binary not found: $binary"
      echo "  → Please run ./scripts/build.sh first"
      return 1
    fi

    echo "  → Starting local server ($binary)..."
    "$binary" > /dev/null 2>&1 &
    server_pid=$!

    # Wait for service to be ready using port check
    echo "  → Waiting for service to be ready..."
    if ! wait_for_port_ready "$PORT"; then
      # Check if process is still running
      if ! kill -0 $server_pid 2>/dev/null; then
        echo "  ✗ Error: Server failed to start"
        return 1
      fi
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
  local json_file="results/${framework}/bench.json"

  # Run oha with JSON output directly to final file
  oha -n "$REQUESTS" -c "$CONCURRENCY" \
    --output-format json \
    -o "$json_file" \
    -H "Accept-Encoding: identity" \
    "http://localhost:${PORT}${ENDPOINT}"

  echo "  → Results saved to: $json_file"

  # Clean up
  echo "  → Cleaning up..."
  if [ "$MODE" = "local" ]; then
    # Kill local server
    if [ -n "$server_pid" ] && kill -0 $server_pid 2>/dev/null; then
      # Try graceful shutdown first
      kill $server_pid 2>/dev/null || true
      
      # Wait up to 5 seconds for graceful shutdown
      local waited=0
      while [ $waited -lt 5 ] && kill -0 $server_pid 2>/dev/null; do
        sleep 1
        waited=$((waited + 1))
      done
      
      # Force kill if still running
      if kill -0 $server_pid 2>/dev/null; then
        echo "  → Force killing server..."
        kill -9 $server_pid 2>/dev/null || true
      fi
      
      wait $server_pid 2>/dev/null || true
    fi
    
    # Ensure port is freed
    kill_port_process "$PORT"
    wait_for_port_free "$PORT"
  else
    # Stop docker container
    docker stop "$container_name" >/dev/null 2>&1
    # docker rm "$container_name" >/dev/null 2>&1
    wait_for_port_free "$PORT"
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

# Initial cleanup: ensure port is free before starting
echo ""
echo "Performing initial cleanup..."
kill_port_process "$PORT"
wait_for_port_free "$PORT"
echo "✓ Initial cleanup complete"

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

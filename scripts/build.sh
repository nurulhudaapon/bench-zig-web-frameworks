#!/bin/bash

# Get mode from first argument or default to "local"
MODE="${1:-local}"

if [ "$MODE" = "docker" ]; then
    echo "Building in Docker mode..."
    docker build --build-arg FW=std . -t bench_zig/std
    docker build --build-arg FW=zap . -t bench_zig/zap
    docker build --build-arg FW=httpz . -t bench_zig/httpz
    # docker build --build-arg FW=zinc . -t bench_zig/zinc
else
    echo "Building in local mode..."
    zig build -Doptimize=ReleaseFast -Dcpu=baseline
fi
### Zig Web Framework Benchmark

This is a benchmark suite for Zig web frameworks.

### Prerequisites

- Docker (for Docker mode)
- [oha](https://github.com/hatoo/oha) - HTTP load testing tool
- Zig compiler (for local mode)

### Running the benchmarks



#### Option 1: Local Mode (default)

Build the binaries locally:
```bash
zig build -Doptimize=ReleaseFast -Dcpu=baseline
```

Run the benchmarks locally (without Docker):
```bash
./scripts/bench.sh
```

#### Option 2: Docker Mode

Build the Docker images for each framework:
```bash
./scripts/build.sh
```

Run the benchmarks in Docker containers:
```bash
MODE=docker ./scripts/bench.sh
```

### Frameworks

- [Zig Standard Library HTTP Server](https://ziglang.org/documentation/master/std/#std.http.Server)
- [Zap](https://github.com/zigzap/zap)
- [HTTPz](https://github.com/karlseguin/http.zig)
- [Zinc](https://github.com/zon-dev/zinc)

### Results

```
std      │█████████████ 27,798 req/s
zap      │███████████████████████████████████████████████ 100,183 req/s
httpz    │██████████████████████████████████████████████████ 106,966 req/s
zinc     │█████████ 18,233 req/s
```
*Machine: Raspberry Pi 5 Model B Rev 1.0 @ 2400MHz (4 cores / 4 physical), L3: 2048KB, 7GB RAM, Linux aarch64, Governor: ondemand, Mode: local*


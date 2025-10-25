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
std      │█████████████ 32312 req/s
zap      │████████████████████████████████████████████████ 118040 req/s
httpz    │██████████████████████████████████████████████████ 123225 req/s
zinc     │██████████████ 34892 req/s
```
*Machine: Apple M1 Pro (10 cores), 16GB RAM, Darwin arm64, Mode: local*


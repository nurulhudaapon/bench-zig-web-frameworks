### Zig Web Framework Benchmark

This is a benchmark suite for Zig web frameworks.

**🌐 View Live Results:** [https://zigweb.nuhu.dev/](https://zigweb.nuhu.dev/)

### Prerequisites

- Docker (for Docker mode)
- [oha](https://github.com/hatoo/oha) - HTTP load testing tool
- Zig compiler (for local mode)

### Running the benchmarks



#### Option 1: Local Mode (default)

Build the binaries locally:
```bash
./scripts/build.sh
```

Run the benchmarks locally (without Docker):
```bash
./scripts/bench.sh
```

#### Option 2: Docker Mode

Build the Docker images for each framework:
```bash
MODE=docker ./scripts/build.sh
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

### Benchmark Methodology

The benchmarks measure raw HTTP performance by sending 1,000,000 requests with 100 concurrent connections to a simple `/httpz` endpoint that returns "OK". This provides a baseline comparison of each framework's request handling capability.

**Current Test:**
- Simple text response endpoint (`/httpz` → "OK")

**Planned Tests:**
- JSON serialization/deserialization
- Route parameter parsing
- Query parameter handling
- Static file serving
- Template rendering

**Note on Comparisons:**
The comparison is not strictly apple-to-apple due to architectural differences between frameworks (e.g., pure Zig vs C bindings, threading models). However, the goal is to keep the tests as fair as possible by using idiomatic patterns for each framework and testing within their intended use cases.

### Results

```
std      │█████████████ 27,798 req/s
zap      │███████████████████████████████████████████████ 100,183 req/s
httpz    │██████████████████████████████████████████████████ 106,966 req/s
zinc     │█████████ 18,233 req/s
```
*Machine: Raspberry Pi 5 Model B Rev 1.0 @ 2400MHz (4 cores / 4 physical), L3: 2048KB, 7GB RAM, Linux aarch64, Governor: ondemand, Mode: local*


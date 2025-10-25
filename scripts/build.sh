docker build --build-arg FW=std . -t bench_zig/std
docker build --build-arg FW=zap . -t bench_zig/zap
docker build --build-arg FW=httpz . -t bench_zig/httpz
# docker build --build-arg FW=zinc . -t bench_zig/zinc

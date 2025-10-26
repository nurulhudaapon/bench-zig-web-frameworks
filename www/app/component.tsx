'use client';

import { useEffect, useState } from 'react';
import type { BenchmarkData } from './data';

interface BenchmarkClientProps {
  benchmarkData: BenchmarkData[];
  maxRps: number;
}

export default function BenchmarkClient({ benchmarkData, maxRps }: BenchmarkClientProps) {
  const [isStarsLoading, setIsStarsLoading] = useState<boolean>(true);
  const [hoveredBar, setHoveredBar] = useState<string | null>(null);

  // Preload GitHub stars image
  useEffect(() => {
    const img = new Image();
    img.src =
      'https://img.shields.io/github/stars/nurulhudaapon/bench-zig-web-frameworks?style=social&cacheSeconds=60';
    img.onload = () => setIsStarsLoading(false);
  }, []);

  return (
    <div className="min-h-screen flex flex-col md:p-2 bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="flex justify-between items-center px-4 py-2 bg-gray-700 md:rounded-t-lg m-0">
        <label className="text-white font-semibold flex items-center gap-2">
          <ZigLogo />
          Zig Web Frameworks
        </label>
        <div className="flex items-center gap-2">
          <a
            href="https://github.com/nurulhudaapon/bench-zig-web-frameworks"
            target="_blank"
            rel="noopener noreferrer"
            className="text-white hover:text-gray-300 transition"
          >
            <GitHubIcon />
          </a>
          <a
            href="https://github.com/nurulhudaapon/bench-zig-web-frameworks"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:opacity-80 transition"
          >
            {isStarsLoading ? (
              <div className="h-5 w-18 bg-gray-600 animate-pulse rounded" />
            ) : (
              <img
                src="https://img.shields.io/github/stars/nurulhudaapon/bench-zig-web-frameworks?style=social&cacheSeconds=60"
                alt="GitHub stars"
                className="h-5 w-18"
              />
            )}
          </a>
        </div>
      </div>

      {/* Benchmark Chart */}
      <div className="bg-gray-800 md:rounded-b-lg p-6 mb-2">
        <h2 className="text-white text-center text-lg font-semibold mb-6">
          HTTP requests per second
        </h2>
        <div className="max-w-2xl mx-auto">
          <div className="flex items-end justify-center gap-8 h-64">
            {benchmarkData.map((item, index) => {
              const heightPercentage = (item.rps / maxRps) * 100;
              const isPink = index === 0;
              const isHovered = hoveredBar === item.name;

              return (
                <div key={item.name} className="flex flex-col items-center flex-1 max-w-[120px]">
                  <div className="relative w-full flex flex-col items-center justify-end h-[200px]">
                    <div className="text-white font-semibold mb-2 text-sm">
                      {Math.round(item.rps).toLocaleString()}
                    </div>
                    <div
                      className={`w-full rounded-t-lg transition-all duration-300 relative cursor-pointer ${
                        isPink ? 'bg-pink-400 hover:bg-pink-300' : 'bg-gray-600 hover:bg-gray-500'
                      } ${isHovered ? 'opacity-100' : 'opacity-90'}`}
                      style={{ height: `${heightPercentage}%` }}
                      onMouseEnter={() => setHoveredBar(item.name)}
                      onMouseLeave={() => setHoveredBar(null)}
                    >
                      {isPink && (
                        <div className="absolute top-8 left-1/2 -translate-x-1/2 text-4xl">
                          ⚡
                        </div>
                      )}

                      {/* Tooltip */}
                      {isHovered && (
                        <div className="absolute top-full left-1/2 -translate-x-1/2 mt-2 w-56 bg-gray-900 text-white text-xs rounded-lg shadow-lg p-3 z-10 pointer-events-none">
                          <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-px">
                            <div className="border-8 border-transparent border-b-gray-900"></div>
                          </div>
                          <div className="font-semibold text-sm mb-2 border-b border-gray-700 pb-2">
                            {item.name} v{item.version}
                          </div>
                          <div className="space-y-1">
                            <div className="flex justify-between">
                              <span className="text-gray-400">Req/sec:</span>
                              <span className="font-medium">{Math.round(item.rps).toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">Avg latency:</span>
                              <span className="font-medium">{(item.average * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">Fastest:</span>
                              <span className="font-medium">{(item.fastest * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">Slowest:</span>
                              <span className="font-medium">{(item.slowest * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">P50:</span>
                              <span className="font-medium">{(item.latencyP50 * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">P95:</span>
                              <span className="font-medium">{(item.latencyP95 * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">P99:</span>
                              <span className="font-medium">{(item.latencyP99 * 1000).toFixed(2)} ms</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">Success rate:</span>
                              <span className="font-medium">{(item.successRate * 100).toFixed(1)}%</span>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="mt-3 text-center">
                    <a
                      href={item.repoUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-white font-medium text-sm hover:text-pink-400 transition-colors cursor-pointer"
                    >
                      {item.name}
                    </a>
                    <div className="text-gray-400 text-xs">v{item.version}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Information Section */}
      <div className="bg-white dark:bg-gray-800 md:rounded-lg p-6 mb-2">
        <div className="grid md:grid-cols-2 gap-6">
          {/* Frameworks */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <span className="text-xl">🚀</span>
              Frameworks
            </h3>
            <ul className="space-y-2">
              <li>
                <a
                  href="https://ziglang.org/documentation/master/std/#std.http.Server"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Zig Standard Library HTTP Server
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/zigzap/zap"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Zap
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/karlseguin/http.zig"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 dark:text-blue-400 hover:underline"
                >
                  HTTPz
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/zon-dev/zinc"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Zinc
                </a>
              </li>
            </ul>
          </div>

          {/* Prerequisites */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <span className="text-xl">📋</span>
              Prerequisites
            </h3>
            <ul className="space-y-2 text-gray-700 dark:text-gray-300">
              <li className="flex items-start gap-2">
                <span className="text-green-500 mt-1">✓</span>
                <span>Docker (for Docker mode)</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-500 mt-1">✓</span>
                <span>
                  <a
                    href="https://github.com/hatoo/oha"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 dark:text-blue-400 hover:underline"
                  >
                    oha
                  </a>
                  {' - HTTP load testing tool'}
                </span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-500 mt-1">✓</span>
                <span>Zig compiler (for local mode)</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Running Benchmarks */}
        <div className="mt-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <span className="text-xl">⚙️</span>
            Running the Benchmarks
          </h3>
          <div className="grid md:grid-cols-2 gap-6">
            {/* Local Mode */}
            <div className="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
              <h4 className="font-semibold text-gray-900 dark:text-white mb-3">
                Option 1: Local Mode
              </h4>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-gray-600 dark:text-gray-400 mb-2">
                    Build the binaries:
                  </p>
                  <code className="block bg-gray-800 text-gray-100 p-2 rounded text-xs overflow-x-auto">
                    zig build -Doptimize=ReleaseFast -Dcpu=baseline
                  </code>
                </div>
                <div>
                  <p className="text-gray-600 dark:text-gray-400 mb-2">
                    Run benchmarks:
                  </p>
                  <code className="block bg-gray-800 text-gray-100 p-2 rounded text-xs overflow-x-auto">
                    ./scripts/bench.sh
                  </code>
                </div>
              </div>
            </div>

            {/* Docker Mode */}
            <div className="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
              <h4 className="font-semibold text-gray-900 dark:text-white mb-3">
                Option 2: Docker Mode
              </h4>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-gray-600 dark:text-gray-400 mb-2">
                    Build Docker images:
                  </p>
                  <code className="block bg-gray-800 text-gray-100 p-2 rounded text-xs overflow-x-auto">
                    ./scripts/build.sh
                  </code>
                </div>
                <div>
                  <p className="text-gray-600 dark:text-gray-400 mb-2">
                    Run benchmarks:
                  </p>
                  <code className="block bg-gray-800 text-gray-100 p-2 rounded text-xs overflow-x-auto">
                    MODE=docker ./scripts/bench.sh
                  </code>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Machine Info */}
        <div className="mt-6 text-center text-sm text-gray-500 dark:text-gray-400 italic">
          <p>* Results based on: Apple M1 Pro (10 cores), 16GB RAM, Darwin arm64, Mode: local</p>
        </div>
      </div>
    </div>
  );
}

// SVG Components
const ZigLogo = () => (
  <svg
    className="w-5 h-5"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 153 140"
  >
    <g fill="#f7a41d">
      <g>
        <polygon points="46,22 28,44 19,30" />
        <polygon
          points="46,22 33,33 28,44 22,44 22,95 31,95 20,100 12,117 0,117 0,22"
          shapeRendering="crispEdges"
        />
        <polygon points="31,95 12,117 4,106" />
      </g>
      <g>
        <polygon points="56,22 62,36 37,44" />
        <polygon
          points="56,22 111,22 111,44 37,44 56,32"
          shapeRendering="crispEdges"
        />
        <polygon points="116,95 97,117 90,104" />
        <polygon
          points="116,95 100,104 97,117 42,117 42,95"
          shapeRendering="crispEdges"
        />
        <polygon points="150,0 52,117 3,140 101,22" />
      </g>
      <g>
        <polygon points="141,22 140,40 122,45" />
        <polygon
          points="153,22 153,117 106,117 120,105 125,95 131,95 131,45 122,45 132,36 141,22"
          shapeRendering="crispEdges"
        />
        <polygon points="125,95 130,110 106,117" />
      </g>
    </g>
  </svg>
);

const GitHubIcon = () => (
  <svg
    fill="currentColor"
    className="w-5"
    role="img"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <title>GitHub</title>
    <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
  </svg>
);


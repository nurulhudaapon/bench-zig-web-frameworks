'use client';

import { useEffect, useState } from 'react';
import type { BenchmarkData } from './data';
import metaInfo from './../../results/meta.json';
import comparisonData from './comparison.json';
import React from 'react';

interface BenchmarkClientProps {
  benchmarkData: BenchmarkData[];
  maxRps: number;
}

export default function BenchmarkClient({ benchmarkData, maxRps }: BenchmarkClientProps) {
  const [isStarsLoading, setIsStarsLoading] = useState<boolean>(true);
  const [hoveredBar, setHoveredBar] = useState<string | null>(null);
  const [showMachineInfo, setShowMachineInfo] = useState<boolean>(false);

  // Preload GitHub stars image
  useEffect(() => {
    const img = new Image();
    img.src =
      'https://img.shields.io/github/stars/nurulhudaapon/bench-zig-web-frameworks?style=social&cacheSeconds=60';
    img.onload = () => setIsStarsLoading(false);
  }, []);

  // Close machine info when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      if (showMachineInfo && !target.closest('.machine-info-container')) {
        setShowMachineInfo(false);
      }
    };

    if (showMachineInfo) {
      document.addEventListener('click', handleClickOutside);
    }

    return () => {
      document.removeEventListener('click', handleClickOutside);
    };
  }, [showMachineInfo]);

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
      <div className="bg-gray-800 md:rounded-b-lg p-6 mb-0 md:mb-2">
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
                  <div className="mt-3 text-center w-full">
                    <a
                      href={item.repoUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-white font-medium text-sm hover:text-pink-400 transition-colors cursor-pointer block truncate"
                    >
                      {item.name}
                    </a>
                    <div className="text-gray-400 text-xs truncate max-w-[50px] mx-auto">v{item.version}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Machine Info */}
        <div className="mt-6 flex justify-center">
          <div className="group relative inline-block machine-info-container">
            <div 
              className="text-center text-xs text-gray-500 hover:text-gray-400 transition-colors cursor-help px-4 py-2 rounded-lg hover:bg-gray-700/30"
              onClick={() => setShowMachineInfo(!showMachineInfo)}
            >
              <div className="flex items-center gap-2 justify-center">
                <svg className="w-3 h-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>
                  {metaInfo.machine.cpu.model} • {metaInfo.execution_date.split('T')[0]}
                </span>
              </div>
            </div>
            
            {/* Extended Details Tooltip */}
            <div className={`${showMachineInfo ? 'visible opacity-100' : 'invisible opacity-0 md:invisible md:opacity-0'} md:group-hover:visible md:group-hover:opacity-100 transition-all duration-300 absolute top-full left-1/2 -translate-x-1/2 mt-2 w-[calc(100vw-2rem)] max-w-96 bg-gray-900 text-white text-xs rounded-lg shadow-2xl p-4 z-20 md:pointer-events-none border border-gray-700`}>
              <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-px">
                <div className="border-[6px] border-transparent border-b-gray-700"></div>
              </div>
              
              {/* Header */}
              <div className="font-semibold text-sm mb-3 pb-2 border-b border-gray-700 text-pink-400">
                Benchmark Environment
              </div>
              
              <div className="space-y-3">
                {/* Benchmark Configuration */}
                <div>
                  <div className="text-gray-400 font-medium mb-1.5 text-[10px] uppercase tracking-wider">
                    Benchmark Configuration
                  </div>
                  <div className="grid grid-cols-3 gap-x-3 gap-y-1 text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Threads:</span>
                      <span className="text-gray-300 font-mono">2</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Workers:</span>
                      <span className="text-gray-300 font-mono">4</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Max Conn:</span>
                      <span className="text-gray-300 font-mono">4096</span>
                    </div>
                  </div>
                </div>

                {/* Execution Info */}
                <div>
                  <div className="text-gray-400 font-medium mb-1.5 text-[10px] uppercase tracking-wider">
                    Execution
                  </div>
                  <div className="grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Date:</span>
                      <span className="text-gray-300 font-mono">{metaInfo.execution_date.split('T')[0]}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Time:</span>
                      <span className="text-gray-300 font-mono">{metaInfo.execution_date.split('T')[1].replace('Z', '')}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Mode:</span>
                      <span className="text-gray-300 capitalize">{metaInfo.mode}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Host:</span>
                      <span className="text-gray-300">{metaInfo.machine.hostname}</span>
                    </div>
                  </div>
                </div>

                {/* CPU Info */}
                <div>
                  <div className="text-gray-400 font-medium mb-1.5 text-[10px] uppercase tracking-wider">
                    CPU
                  </div>
                  <div className="space-y-1 text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Model:</span>
                      <span className="text-gray-300 text-right">{metaInfo.machine.cpu.model}</span>
                    </div>
                    <div className="grid grid-cols-2 gap-x-3">
                      <div className="flex justify-between">
                        <span className="text-gray-500">Cores:</span>
                        <span className="text-gray-300">{metaInfo.machine.cpu.cores.logical} logical</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500"></span>
                        <span className="text-gray-300">{metaInfo.machine.cpu.cores.physical} physical</span>
                      </div>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Frequency:</span>
                      <span className="text-gray-300">{metaInfo.machine.cpu.frequency.current_mhz} MHz (max: {metaInfo.machine.cpu.frequency.max_mhz} MHz)</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Cache:</span>
                      <span className="text-gray-300">L1: {metaInfo.machine.cpu.cache.l1_kb}KB, L2: {metaInfo.machine.cpu.cache.l2_kb}KB, L3: {metaInfo.machine.cpu.cache.l3_kb}KB</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Governor:</span>
                      <span className="text-gray-300 capitalize">{metaInfo.machine.cpu.governor}</span>
                    </div>
                  </div>
                </div>

                {/* Memory Info */}
                <div>
                  <div className="text-gray-400 font-medium mb-1.5 text-[10px] uppercase tracking-wider">
                    Memory
                  </div>
                  <div className="grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Total:</span>
                      <span className="text-gray-300">{metaInfo.machine.memory.total_gb} GB</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Available:</span>
                      <span className="text-gray-300">{metaInfo.machine.memory.available_gb} GB</span>
                    </div>
                  </div>
                </div>

                {/* OS Info */}
                <div>
                  <div className="text-gray-400 font-medium mb-1.5 text-[10px] uppercase tracking-wider">
                    Operating System
                  </div>
                  <div className="space-y-1 text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">OS:</span>
                      <span className="text-gray-300">{metaInfo.machine.os.name} {metaInfo.machine.os.arch}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Kernel:</span>
                      <span className="text-gray-300 text-right">{metaInfo.machine.os.version}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>


      {/* Comparison Table */}
      <div className="bg-gray-800 md:rounded-lg mb-0 md:mb-2">
        <div className="overflow-x-auto md:rounded-lg">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-gray-700">
                <th className="text-left p-2 md:p-4 font-semibold text-white border-b-2 border-gray-600 text-sm md:text-base">
                  Feature
                </th>
                {benchmarkData.map((fw) => (
                  <th
                    key={fw.name}
                    className="text-center p-2 md:p-4 font-semibold text-white border-b-2 border-gray-600 min-w-[80px] md:min-w-[120px] text-sm md:text-base"
                  >
                    <div className="flex flex-col items-center gap-1">
                      <span>{fw.name}</span>
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {comparisonData.map((category, catIdx) => (
                <React.Fragment key={`cat-${catIdx}`}>
                  {/* Category Header Row */}
                  <tr key={`cat-${catIdx}`} className="bg-gray-700/50">
                    <td
                      colSpan={benchmarkData.length + 1}
                      className="p-2 md:p-4 border-t-2 border-gray-600"
                    >
                      <div className="flex flex-col">
                        <h3 className="text-base md:text-lg font-bold text-white">
                          {category.category}
                        </h3>
                        <p className="text-xs text-gray-400 mt-1">
                          {category.description}
                        </p>
                      </div>
                    </td>
                  </tr>
                  {/* Feature Rows */}
                  {category.features.map((feature, fIdx) => (
                    <tr
                      key={`${catIdx}-${fIdx}`}
                      className="border-b border-gray-700 hover:bg-gray-700/30 transition-colors"
                    >
                      <td className="p-2 md:p-4">
                        <div className="flex flex-col">
                          <span className="font-medium text-white text-xs md:text-sm">
                            {feature.name}
                          </span>
                          <span className="text-xs text-gray-400 hidden md:block">
                            {feature.description}
                          </span>
                        </div>
                      </td>
                      {benchmarkData.map((fw) => {
                        const data = feature[fw.name as keyof typeof feature] as { value: string; status: string };
                        return (
                          <td key={fw.name} className="p-2 md:p-4 text-center">
                            <div className="flex flex-col items-center gap-1 md:gap-2">
                              <StatusIcon status={data.status} />
                              <span className="text-xs md:text-sm text-gray-300">
                                {data.value}
                              </span>
                            </div>
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// Status Icon Component
const StatusIcon = ({ status }: { status: string }) => {
  if (status === 'success') {
    return (
      <div className="w-5 h-5 md:w-6 md:h-6 rounded-full bg-green-500 flex items-center justify-center">
        <svg className="w-3 h-3 md:w-4 md:h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
      </div>
    );
  }
  if (status === 'warning') {
    return (
      <div className="w-5 h-5 md:w-6 md:h-6 rounded-full bg-yellow-500 flex items-center justify-center">
        <svg className="w-3 h-3 md:w-4 md:h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
      </div>
    );
  }
  if (status === 'error') {
    return (
      <div className="w-5 h-5 md:w-6 md:h-6 rounded-full bg-red-500 flex items-center justify-center">
        <svg className="w-3 h-3 md:w-4 md:h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </div>
    );
  }
  return null;
};

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


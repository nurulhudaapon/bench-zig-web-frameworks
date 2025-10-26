import { ZON } from 'zzon';

// Import benchmark results
import httpzResult from '../../results/httpz/bench.json';
import zapResult from '../../results/zap/bench.json';
import stdResult from '../../results/std/bench.json';
import zincResult from '../../results/zinc/bench.json';

// Type definitions
interface BuildManifest {
  name: string;
  version: string;
  minimum_zig_version: string;
  dependencies: Record<string, { url: string; hash: string }>;
}

interface BenchmarkResult {
  summary: {
    requestsPerSec: number;
    average: number;
    fastest: number;
    slowest: number;
    successRate: number;
  };
  latencyPercentiles: {
    p50: number;
    p95: number;
    p99: number;
  };
}

export interface BenchmarkData {
  name: string;
  rps: number;
  version: string;
  repoUrl: string;
  average: number;
  fastest: number;
  slowest: number;
  successRate: number;
  latencyP50: number;
  latencyP95: number;
  latencyP99: number;
}

// Utility functions
function extractVersion(hash: string): string {
  const match = hash.match(/^[a-z]+-([0-9]+\.[0-9]+\.[0-9]+(?:-(?:alpha|beta|canary|rc|dev)(?:\.[0-9]+)?)?)/);
  return match ? match[1] : 'unknown';
}

function extractRepoUrl(url: string): string {
  // Format: git+https://github.com/zon-dev/zinc.git#commit_hash
  const match = url.match(/^git\+(.+?)(?:\.git)?(?:#.*)?$/);
  return match ? match[1] : url;
}

function createBenchmarkEntry(
  name: string,
  result: BenchmarkResult,
  version: string,
  repoUrl: string
): BenchmarkData {
  return {
    name,
    rps: result.summary.requestsPerSec,
    version,
    repoUrl,
    average: result.summary.average,
    fastest: result.summary.fastest,
    slowest: result.summary.slowest,
    successRate: result.summary.successRate,
    latencyP50: result.latencyPercentiles.p50,
    latencyP95: result.latencyPercentiles.p95,
    latencyP99: result.latencyPercentiles.p99,
  };
}

export async function getBenchmarkData(): Promise<BenchmarkData[]> {
  // Fetch and parse build manifest
  const response = await fetch(
    'https://raw.githubusercontent.com/nurulhudaapon/bench-zig-web-frameworks/refs/heads/main/build.zig.zon',
    { cache: 'force-cache' } // Cache for 1 hour
  );
  const zonText = await response.text();
  const buildManifest = ZON.parse(zonText) as BuildManifest;

  // Extract versions and repository URLs
  const versions: Record<string, string> = {};
  const repoUrls: Record<string, string> = {};

  for (const [name, dep] of Object.entries(buildManifest.dependencies)) {
    versions[name] = extractVersion(dep.hash);
    repoUrls[name] = extractRepoUrl(dep.url);
  }

  // Add std library info
  versions.std = buildManifest.minimum_zig_version;
  repoUrls.std = 'https://github.com/ziglang/zig';

  // Create benchmark data array
 const benchmarkData: BenchmarkData[] = [
    createBenchmarkEntry('httpz', httpzResult as BenchmarkResult, versions.httpz, repoUrls.httpz),
    createBenchmarkEntry('zap', zapResult as BenchmarkResult, versions.zap, repoUrls.zap),
    createBenchmarkEntry('std', stdResult as BenchmarkResult, versions.std, repoUrls.std),
    createBenchmarkEntry('zinc', zincResult as BenchmarkResult, versions.zinc, repoUrls.zinc),
  ].sort((a, b) => b.rps - a.rps);
  return benchmarkData;
}
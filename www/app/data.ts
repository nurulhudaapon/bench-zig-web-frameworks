import { ZON } from 'zzon';

// Framework definitions
const frameworks = [
  'httpz',
  'zap',
  'std',
  'zinc',
  'zzz:0.14.0', // Has its own build.zig.zon inside the app
];

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
  const buildManifest = ZON.parse((await import('../../build.zig.zon')).default) as BuildManifest;

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

  // Process each framework dynamically
  const benchmarkData: BenchmarkData[] = [];

  for (const framework of frameworks) {
    // Check if framework has special notation (e.g., "zzz:0.14.0")
    const [frameworkName, separateBuildVersion] = framework.split(':');

    // Handle frameworks with separate build.zig.zon
    if (separateBuildVersion) {
      const frameworkManifest = ZON.parse(
        (await import(`../../src/frameworks/${frameworkName}/build.zig.zon`)).default
      ) as BuildManifest;

      if (frameworkManifest.dependencies[frameworkName]) {
        versions[frameworkName] = extractVersion(frameworkManifest.dependencies[frameworkName].hash);
        repoUrls[frameworkName] = extractRepoUrl(frameworkManifest.dependencies[frameworkName].url);
      }
    }

    // Dynamically import the benchmark result
    const result = (await import(`../../results/${frameworkName}/bench.json`)).default as BenchmarkResult;

    // Create benchmark entry
    benchmarkData.push(
      createBenchmarkEntry(frameworkName, result, versions[frameworkName], repoUrls[frameworkName])
    );
  }

  // Sort by requests per second (descending)
  return benchmarkData.sort((a, b) => b.rps - a.rps);
}
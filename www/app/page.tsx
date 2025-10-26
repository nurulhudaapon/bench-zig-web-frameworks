import BenchmarkClient from './component';
import { getBenchmarkData } from './data' with { type: 'macro' };

// Server Component
export default async function BenchmarkPage() {
  const benchmarkData = await getBenchmarkData();
  const maxRps = Math.max(...benchmarkData.map((d) => d.rps));

  return <BenchmarkClient benchmarkData={benchmarkData} maxRps={maxRps} />;
}

import type { Metadata } from 'next';
import type React from 'react';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Zig Web Frameworks Benchmark',
  description: 'Performance comparison of popular Zig web frameworks including httpz, zap, zinc, and std.http.',
  keywords: 'zig, web frameworks, benchmark, performance, httpz, zap, std, zinc',
  authors: [{ name: 'Nurul Huda (Apon)' }],
  creator: 'Nurul Huda (Apon)',
  publisher: 'Nurul Huda (Apon)',
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.className} light`}>
        {children}
      </body>
    </html>
  );
}
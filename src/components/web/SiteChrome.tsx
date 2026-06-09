'use client';
import Link from 'next/link';
import type { Site } from '@/lib/web/types';

interface Props {
  site: Site;
  children: React.ReactNode;
}

export function SiteChrome({ site, children }: Props) {
  return (
    <div style={{ '--site-primary': '#0b3d5c', '--site-accent': '#1fb6a6' } as any}>
      <header className="border-b">
        <div className="mx-auto max-w-6xl px-6 py-4 flex items-center justify-between">
          <Link href="/" className="font-bold">{site.name}</Link>
          <nav className="flex gap-8">
            <a href="/technology">Technology</a>
            <a href="/shop">Products</a>
            <a href="/research">Research</a>
            <a href="/about">About</a>
            <a href="/contact">Contact</a>
            <a href="/admin" className="bg-blue-600 text-white px-4 py-1 rounded">Admin</a>
          </nav>
        </div>
      </header>
      <main>{children}</main>
      <footer className="mt-16 border-t bg-slate-50">
        <div className="mx-auto max-w-6xl px-6 py-10 text-sm">
          <p>(c) {new Date().getFullYear()} {site.name}</p>
        </div>
      </footer>
    </div>
  );
}

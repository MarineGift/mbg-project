import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import './globals.css';

export const metadata: Metadata = {
  title: 'URM Platform',
  description: 'Universal Relationship Management Platform',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ko">
      <body className="font-sans antialiased bg-surface-subtle text-primary">
        {children}
      </body>
    </html>
  );
}

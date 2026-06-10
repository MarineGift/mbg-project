import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: {
    default: 'Marine Bio Group - Paper Mill & Filler Supplier Intelligence',
    template: '%s | Marine Bio Group',
  },
  description:
    'Global Paper Mill and Filler Supplier Intelligence Platform. Investor relations management and supply chain intelligence.',
  manifest: '/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Marine Bio',
  },
  icons: {
    icon: '/favicon.svg',
    apple: '/icons/home-192.svg',
  },
  formatDetection: {
    telephone: true,
    email: true,
    address: true,
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://marinebiogroup.com',
    siteName: 'Marine Bio Group',
    title: 'Marine Bio Group - Paper Mill & Filler Supplier Intelligence',
    description:
      'Global Paper Mill and Filler Supplier Intelligence Platform',
    images: [
      {
        url: '/icons/home-512.svg',
        width: 512,
        height: 512,
        alt: 'Marine Bio Group Logo',
      },
    ],
  },
  twitter: {
    card: 'summary',
    title: 'Marine Bio Group',
    description: 'Global Paper Mill & Filler Supplier Intelligence',
    images: ['/icons/home-512.svg'],
  },
};

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#1a73e8" />
      </head>
      <body>{children}</body>
    </html>
  );
}

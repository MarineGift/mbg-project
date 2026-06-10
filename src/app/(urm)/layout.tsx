import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: {
    default: 'URM Dashboard - Unified Relationship Management',
    template: '%s | URM',
  },
  description:
    'Investor Relations and Supplier Intelligence CRM System. Manage contacts, deals, and relationships.',
  manifest: '/urm/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'URM',
  },
  icons: {
    icon: '/favicon.svg',
    apple: '/icons/urm-192.svg',
  },
  formatDetection: {
    telephone: true,
    email: true,
    address: true,
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://marinebiogroup.com/urm',
    siteName: 'URM - Unified Relationship Management',
    title: 'URM Dashboard',
    description:
      'Investor Relations and Supplier Intelligence CRM System',
    images: [
      {
        url: '/icons/urm-512.svg',
        width: 512,
        height: 512,
        alt: 'URM Logo',
      },
    ],
  },
  twitter: {
    card: 'summary',
    title: 'URM Dashboard',
    description: 'Unified Relationship Management System',
    images: ['/icons/urm-512.svg'],
  },
};

export default function UrmLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#4285f4" />
      </head>
      <body>{children}</body>
    </html>
  );
}

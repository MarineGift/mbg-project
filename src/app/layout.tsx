/**
 * app/layout.tsx
 *
 * Root layout — 모든 페이지의 최상위 (login 포함).
 *   - 다국어 폰트 로드 (Inter, Noto Sans KR, Noto Sans JP)
 *   - locale + messages 결정 (next-intl)
 *   - 전역 providers (QueryProvider, IntlProvider, ToastProvider)
 *
 * 인증 가드는 (app) group의 하위 layout에서 처리.
 */

import type { Metadata } from 'next';
import { Inter, Noto_Sans_KR, Noto_Sans_JP } from 'next/font/google';
import { getLocale, getMessages } from 'next-intl/server';
import { QueryProvider } from '@/components/providers/query-provider';
import { IntlProvider } from '@/components/providers/intl-provider';
import { ToastProvider } from '@/components/providers/toast-provider';
import { normalizeLocale } from '@/i18n/routing';
import './globals.css';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});
const notoKr = Noto_Sans_KR({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-noto-kr',
  display: 'swap',
});
const notoJp = Noto_Sans_JP({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-noto-jp',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'URM Platform',
  description: 'AI-assisted CRM for solo founders',
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const localeRaw = await getLocale();
  const locale = normalizeLocale(localeRaw);
  const messages = await getMessages();

  return (
    <html
      lang={locale}
      className={`${inter.variable} ${notoKr.variable} ${notoJp.variable}`}
      suppressHydrationWarning
    >
      <body className="min-h-screen bg-background font-sans antialiased">
        <IntlProvider locale={locale} messages={messages}>
          <QueryProvider>
            {children}
            <ToastProvider />
          </QueryProvider>
        </IntlProvider>
      </body>
    </html>
  );
}

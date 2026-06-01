/**
 * components/providers/intl-provider.tsx
 *
 * next-intl client provider - receives from the Server Component (layout.tsx)
 * and passes locale/messages to the client.
 */

'use client';

import { NextIntlClientProvider, type AbstractIntlMessages } from 'next-intl';
import type { ReactNode } from 'react';
import type { Locale } from '@/i18n/routing';

interface IntlProviderProps {
  locale: Locale;
  messages: AbstractIntlMessages;
  timeZone?: string;
  children: ReactNode;
}

export function IntlProvider({
  locale,
  messages,
  timeZone,
  children,
}: IntlProviderProps) {
  return (
    <NextIntlClientProvider
      locale={locale}
      messages={messages}
      timeZone={timeZone ?? 'Asia/Seoul'}
    >
      {children}
    </NextIntlClientProvider>
  );
}

/**
 * i18n/request.ts
 *
 * Callback that the next-intl plugin calls on every request.
 *
 * Locale decision priority:
 *   1. authenticated user: app.users.preferred_language (JWT or DB)
 *   2. cookie('NEXT_LOCALE') - set by the UI toggle
 *   3. Accept-Language header negotiation
 *   4. default 'ko'
 *
 * Phase 1 uses only steps 1 and 2 (header negotiation is next-intl's default behavior).
 * Step 1 is decided server-side in layout.tsx and syncs the cookie, so
 * this callback only reads the cookie.
 */

import { getRequestConfig } from 'next-intl/server';
import type { AbstractIntlMessages } from 'next-intl';
import { cookies, headers } from 'next/headers';
import {
  defaultLocale,
  localeCookieName,
  locales,
  normalizeLocale,
  type Locale,
} from './routing';

export default getRequestConfig(async () => {
  const cookieStore = await cookies();
  const headerList = await headers();

  // Step 1: cookie (explicit user choice, or set from the user's preferred_language in layout)
  const cookieLocale = cookieStore.get(localeCookieName)?.value;
  if (cookieLocale && (locales as readonly string[]).includes(cookieLocale)) {
    return loadMessages(normalizeLocale(cookieLocale));
  }

  // Step 2: extract the preferred locale from the Accept-Language header
  const acceptLanguage = headerList.get('accept-language') ?? '';
  const negotiated = negotiateAcceptLanguage(acceptLanguage);
  if (negotiated) {
    return loadMessages(negotiated);
  }

  // Step 3: default
  return loadMessages(defaultLocale);
});

/**
 * Returns the first supported locale matched from the Accept-Language header.
 * e.g. "en-US,en;q=0.9,ko;q=0.8" -> 'en'
 */
function negotiateAcceptLanguage(header: string): Locale | null {
  if (!header) return null;

  const items = header.split(',').map((part) => {
    const [lang = '', qPart] = part.trim().split(';');
    const q = qPart?.startsWith('q=') ? Number(qPart.slice(2)) : 1;
    // shorten ko-KR -> ko
    const short = (lang.split('-')[0] ?? '').toLowerCase();
    return { lang: short, q: Number.isFinite(q) ? q : 1 };
  });

  items.sort((a, b) => b.q - a.q);

  for (const { lang } of items) {
    if ((locales as readonly string[]).includes(lang)) {
      return lang as Locale;
    }
  }
  return null;
}

async function loadMessages(locale: Locale) {
  // dynamic import - lazy-load the per-locale message bundle
  const messages = (
    (await import(`./messages/${locale}.json`)) as {
      default: AbstractIntlMessages;
    }
  ).default;
  return { locale, messages };
}

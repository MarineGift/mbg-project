/**
 * i18n/request.ts
 *
 * next-intl plugin이 매 요청에서 호출하는 콜백.
 *
 * locale 결정 우선순위:
 *   1. 인증된 사용자: app.users.preferred_language (JWT 또는 DB)
 *   2. cookie('NEXT_LOCALE') — UI 토글이 설정
 *   3. Accept-Language 헤더 협상
 *   4. 기본값 'ko'
 *
 * Phase 1에서는 1·2단계만 사용 (헤더 협상은 next-intl 기본 동작).
 * 1단계는 layout.tsx에서 server-side로 결정해 cookie를 동기화하므로
 * 본 콜백은 cookie 읽기만 수행.
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

  // 1단계: cookie (사용자 명시 선택 또는 layout에서 사용자 preferred_language로 설정)
  const cookieLocale = cookieStore.get(localeCookieName)?.value;
  if (cookieLocale && (locales as readonly string[]).includes(cookieLocale)) {
    return loadMessages(normalizeLocale(cookieLocale));
  }

  // 2단계: Accept-Language 헤더에서 선호 locale 추출
  const acceptLanguage = headerList.get('accept-language') ?? '';
  const negotiated = negotiateAcceptLanguage(acceptLanguage);
  if (negotiated) {
    return loadMessages(negotiated);
  }

  // 3단계: 기본값
  return loadMessages(defaultLocale);
});

/**
 * Accept-Language 헤더에서 지원 locale 중 첫 매칭 반환.
 * 예: "en-US,en;q=0.9,ko;q=0.8" → 'en'
 */
function negotiateAcceptLanguage(header: string): Locale | null {
  if (!header) return null;

  const items = header.split(',').map((part) => {
    const [lang = '', qPart] = part.trim().split(';');
    const q = qPart?.startsWith('q=') ? Number(qPart.slice(2)) : 1;
    // ko-KR → ko 로 축약
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
  // 동적 import — locale별 메시지 번들을 lazy-load
  const messages = (
    (await import(`./messages/${locale}.json`)) as {
      default: AbstractIntlMessages;
    }
  ).default;
  return { locale, messages };
}

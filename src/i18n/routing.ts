/**
 * i18n/routing.ts
 *
 * next-intl 라우팅 설정.
 *
 * 결정 (제안서 Q7 + 안정성):
 *   - 3개 locale 모두 완전 번역 (ko, en, ja)
 *   - URL 접두사 없음 (예: /ko/drafts 아닌 /drafts)
 *     → cookie('NEXT_LOCALE') + Accept-Language 헤더로 자동 선택
 *     → 사용자 설정(app.users.preferred_language)이 최우선
 */

export const locales = ['ko', 'en', 'ja'] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = 'ko';

/**
 * cookie 이름 — next-intl 표준. UI 토글 시 이 cookie를 갱신.
 */
export const localeCookieName = 'NEXT_LOCALE';

/**
 * 입력이 유효 locale인지 좁힘. 미지원 값은 기본값(ko)로 fallback.
 */
export function normalizeLocale(input: string | null | undefined): Locale {
  if (!input) return defaultLocale;
  return (locales as readonly string[]).includes(input)
    ? (input as Locale)
    : defaultLocale;
}

/**
 * 사람이 읽기 좋은 locale 이름 (UI 토글 표시용).
 */
export const localeDisplayNames: Record<Locale, string> = {
  ko: '한국어',
  en: 'English',
  ja: '日本語',
};

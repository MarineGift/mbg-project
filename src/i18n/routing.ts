/**
 * i18n/routing.ts
 *
 * next-intl routing configuration.
 *
 * Decision (proposal Q7 + stability):
 *   - all 3 locales fully translated (ko, en, ja)
 *   - no URL prefix (e.g. /drafts, not /ko/drafts)
 *     -> auto-selected via cookie('NEXT_LOCALE') + Accept-Language header
 *     -> the user setting (app.users.preferred_language) takes top priority
 */

export const locales = ['ko', 'en', 'ja'] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = 'ko';

/**
 * cookie name - next-intl standard. The UI toggle updates this cookie.
 */
export const localeCookieName = 'NEXT_LOCALE';

/**
 * Narrows whether the input is a valid locale. Unsupported values fall back to the default (ko).
 */
export function normalizeLocale(input: string | null | undefined): Locale {
  if (!input) return defaultLocale;
  return (locales as readonly string[]).includes(input)
    ? (input as Locale)
    : defaultLocale;
}

/**
 * Human-readable locale names (for the UI toggle display).
 */
export const localeDisplayNames: Record<Locale, string> = {
  ko: '한국어',
  en: 'English',
  ja: '日本語',
};

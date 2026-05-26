# Language Policy (effective 2026-05-18)

## Rule

All NEW code, comments, and UI strings MUST be in English.
- Comments: English only
- Variable / function / file names: English (already standard)
- Hard-coded UI strings: English (use `useTranslations()` for user-facing text)
- New SQL comments (`COMMENT ON ...`): English

Korean and Japanese are presentation-layer concerns handled by i18n
(`src/i18n/messages/{en,ja,ko}.json`). They never appear in source code.

## Why

PowerShell here-strings and clipboard paste have repeatedly corrupted
non-ASCII characters (mojibake), causing JSX/HTML to break in production.
Keeping source files ASCII-only eliminates this class of bug entirely.

## Migration plan for existing Korean strings

When touching a file that contains Korean comments or hard-coded strings:
1. Translate the comment to English in place
2. Move user-facing Korean text to `messages/ko.json` with an English fallback key
3. Verify file is valid UTF-8 (no BOM) after editing

Don't do a project-wide sweep — only update files you're already editing
for other reasons.

## i18n keys

When adding a new user-facing string, create the key in three files:
- `src/i18n/messages/en.json` (canonical English)
- `src/i18n/messages/ko.json` (Korean translation)
- `src/i18n/messages/ja.json` (Japanese translation)

Reference it in code:
```tsx
const t = useTranslations('dashboard');
return <h1>{t('title')}</h1>;
```
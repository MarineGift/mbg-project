/**
 * tests/i18n-completeness.test.ts
 *
 * 3개 언어 (ko/en/ja) 파일이 동일한 key 집합을 가지는지 검증.
 * Phase 1은 100% 동기화가 목표 (Q10 결정).
 */

import { describe, it, expect } from 'vitest';
import koMessages from '@/i18n/messages/ko.json';
import enMessages from '@/i18n/messages/en.json';
import jaMessages from '@/i18n/messages/ja.json';

type MessageObject = { [key: string]: string | MessageObject };

function flattenKeys(obj: MessageObject, prefix = ''): Set<string> {
  const keys = new Set<string>();
  for (const [k, v] of Object.entries(obj)) {
    const path = prefix ? `${prefix}.${k}` : k;
    if (typeof v === 'string') {
      keys.add(path);
    } else if (v && typeof v === 'object') {
      for (const sub of flattenKeys(v, path)) {
        keys.add(sub);
      }
    }
  }
  return keys;
}

describe('i18n completeness', () => {
  const koKeys = flattenKeys(koMessages as unknown as MessageObject);
  const enKeys = flattenKeys(enMessages as unknown as MessageObject);
  const jaKeys = flattenKeys(jaMessages as unknown as MessageObject);

  it('all three locales have the same number of keys', () => {
    expect(enKeys.size).toBe(koKeys.size);
    expect(jaKeys.size).toBe(koKeys.size);
  });

  it('ko has no key missing in en', () => {
    const missing = [...koKeys].filter((k) => !enKeys.has(k));
    expect(missing).toEqual([]);
  });

  it('ko has no key missing in ja', () => {
    const missing = [...koKeys].filter((k) => !jaKeys.has(k));
    expect(missing).toEqual([]);
  });

  it('en has no key missing in ko', () => {
    const missing = [...enKeys].filter((k) => !koKeys.has(k));
    expect(missing).toEqual([]);
  });

  it('ja has no key missing in ko', () => {
    const missing = [...jaKeys].filter((k) => !koKeys.has(k));
    expect(missing).toEqual([]);
  });

  it('all values are non-empty strings', () => {
    function checkValues(obj: MessageObject, lang: string, path = ''): string[] {
      const empties: string[] = [];
      for (const [k, v] of Object.entries(obj)) {
        const p = path ? `${path}.${k}` : k;
        if (typeof v === 'string') {
          if (v.trim().length === 0) empties.push(`${lang}: ${p}`);
        } else if (v && typeof v === 'object') {
          empties.push(...checkValues(v, lang, p));
        }
      }
      return empties;
    }
    expect([
      ...checkValues(koMessages as unknown as MessageObject, 'ko'),
      ...checkValues(enMessages as unknown as MessageObject, 'en'),
      ...checkValues(jaMessages as unknown as MessageObject, 'ja'),
    ]).toEqual([]);
  });

  it('all three locales have core namespaces present', () => {
    const requiredNamespaces = [
      'common',
      'nav',
      'modules',
      'drafts',
      'inbox',
      'partyDetail',
      'engagements',
      'tasks',
      'settings',
      'realtime',
      'partyForm',
      'engagementForm',
      'contactForm',
      'taskForm',
      'compose',
    ];
    for (const ns of requiredNamespaces) {
      expect(
        [...koKeys].some((k) => k.startsWith(`${ns}.`)),
        `ko missing namespace: ${ns}`,
      ).toBe(true);
      expect(
        [...enKeys].some((k) => k.startsWith(`${ns}.`)),
        `en missing namespace: ${ns}`,
      ).toBe(true);
      expect(
        [...jaKeys].some((k) => k.startsWith(`${ns}.`)),
        `ja missing namespace: ${ns}`,
      ).toBe(true);
    }
  });
});

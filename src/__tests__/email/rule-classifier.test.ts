/**
 * __tests__/email/rule-classifier.test.ts
 * Rule-based (no AI) inbound classifier.
 */
import { describe, it, expect } from 'vitest';
import {
  classifyByRules,
  detectLanguage,
  extractNewText,
} from '../../lib/email/rule-classifier';

const c = (subject: string, bodyPlain: string, extra: Partial<Parameters<typeof classifyByRules>[0]> = {}) =>
  classifyByRules({ subject, bodyPlain, fromAddress: 'jane@fund.example', ...extra });

describe('rule-classifier: automated mail', () => {
  it('flags List-Unsubscribe as automated', () => {
    const r = c('Weekly digest', 'news', { headers: { 'list-unsubscribe': '<mailto:x@y>' } });
    expect(r.isAutomated).toBe(true);
    expect(r.classification.category).toBe('other');
    expect(r.classification.urgency).toBe('low');
  });
  it('flags noreply senders and out-of-office subjects', () => {
    expect(c('Your receipt', 'hi', { fromAddress: 'no-reply@shop.example' }).isAutomated).toBe(true);
    expect(c('Automatic reply: MBG intro', 'I am away').isAutomated).toBe(true);
    expect(c('자동 회신: 문의', '부재중입니다').isAutomated).toBe(true);
    expect(c('Hello', 'hi', { headers: { 'auto-submitted': 'auto-replied' } }).isAutomated).toBe(true);
  });
  it('does not flag a normal person', () => {
    expect(c('Re: FCC licensing', 'Sounds interesting.').isAutomated).toBe(false);
  });
});

describe('rule-classifier: categories', () => {
  it.each([
    ['Re: MBG', 'Thanks for reaching out. Unfortunately this is not a fit for our fund.', 'rejection'],
    ['Re: MBG', 'Could we set up a call next Tuesday? Here is my Calendly.', 'meeting_scheduling'],
    ['NDA draft', 'Attached is our redline of the NDA.', 'contract_terms'],
    ['Re: 문의', '견적 단가를 알려주실 수 있을까요?', 'price_negotiation'],
    ['Intro: MBG <> Acme', 'Happy to introduce you to Tom at Acme.', 'introduction'],
    ['Re: deck', 'Just following up on my previous note.', 'follow_up'],
    ['Re: deck', 'Could you send the one-pager and technical data?', 'information_request'],
    ['Re: deck', 'Thank you, received.', 'simple_acknowledgment'],
    ['Re: deck', 'What is the particle size range?', 'information_request'],
    ['Hello', 'Hope you are well.', 'other'],
  ])('%s / %s -> %s', (subject, body, expected) => {
    expect(c(subject, body).classification.category).toBe(expected);
  });

  it('ignores quoted history', () => {
    const body = 'Thank you, received.\n\nOn Mon, Sep 14, 2026 at 9:00 AM YunYoung wrote:\n> Could we schedule a meeting to discuss pricing and the NDA?';
    expect(extractNewText(body).trim()).toBe('Thank you, received.');
    expect(c('Re: MBG', body).classification.category).toBe('simple_acknowledgment');
  });

  it('always requires human review and sets risk flags', () => {
    const r = c('Term sheet', 'Please review the term sheet and the pre-money valuation.').classification;
    expect(r.requiresHuman).toBe(true);
    expect(r.riskFlags).toEqual(expect.arrayContaining(['term_sheet_topic', 'valuation_topic']));
  });
});

describe('rule-classifier: language', () => {
  it('detects ko / ja / en', () => {
    expect(detectLanguage('안녕하세요, 자료 부탁드립니다.')).toBe('ko');
    expect(detectLanguage('お世話になっております。資料をお送りします。')).toBe('ja');
    expect(detectLanguage('Hello, please send the deck when you can.')).toBe('en');
  });
});

/**
 * __tests__/email/investor-intro.test.ts
 * Greentown Labs investor-intro detection (rule-based, no AI).
 */
import { describe, it, expect } from 'vitest';
import { detectInvestorIntro, domainMatches, extractIntroFirm, extractPairFirm, hostOf } from '../../lib/email/investor-intro';

describe('investor-intro', () => {
  it('reads the firm from the warm-intro subject', () => {
    expect(extractIntroFirm('Re: Marinebio Group Inc. — Exploring a potential fit with Strategic Ventures'))
      .toBe('Strategic Ventures');
    expect(extractIntroFirm('Re: hello')).toBeUndefined();
  });

  it('flags a reply on the warm-intro subject (mentor-matched person)', () => {
    const r = detectInvestorIntro({
      fromAddress: 'mitchell@strategic.example',
      subject: 'Re: Marinebio Group Inc. — Exploring a potential fit with Strategic Ventures',
      bodyPlain: "Hello Yun-Yong, Following up on Tony's email regarding coordinating a call.",
    });
    expect(r).toMatchObject({ isInvestorIntro: true, reason: 'intro_subject', firmHint: 'Strategic Ventures' });
  });

  it('flags a new investor that mentions a Greentown connection', () => {
    const r = detectInvestorIntro({
      fromAddress: 'josh@helios.example',
      subject: 'Greentown connected us',
      bodyPlain: 'Hello Yun-Young, I recently received a note from Greentown labs asking to be connected. I reviewed your deck.',
    });
    expect(r).toMatchObject({ isInvestorIntro: true, reason: 'greentown_mention' });
  });

  it('always flags Will at Greentown, even through a bulk platform', () => {
    const r = detectInvestorIntro({
      fromAddress: 'Will@greentownlabs.org',
      subject: 'Intro',
      bodyPlain: 'x',
      headers: { 'list-unsubscribe': '<mailto:u@x>' },
    });
    expect(r).toMatchObject({ isInvestorIntro: true, reason: 'greentown_sender' });
  });

  it('ignores Greentown newsletters, staff mail and quoted signatures', () => {
    expect(detectInvestorIntro({
      fromAddress: 'GreentownHTX@user.luma-mail.com',
      subject: 'Greentown Houston investor meetup',
      bodyPlain: 'Join us',
      headers: { 'list-unsubscribe': '<mailto:u@x>' },
    }).isInvestorIntro).toBe(false);
    expect(detectInvestorIntro({
      fromAddress: 'mteixeira@greentownlabs.com',
      subject: 'Greentown desk move',
      bodyPlain: 'Your desk call is Tuesday.',
    }).isInvestorIntro).toBe(false);
    expect(detectInvestorIntro({
      fromAddress: 'buyer@mill.example',
      subject: 'Re: FCC trial',
      bodyPlain: 'Thanks, see you on the call.\n\nOn Mon, YunYoung wrote:\n> MarineBio Group, Greentown Labs Houston',
    }).isInvestorIntro).toBe(false);
  });
});

describe('extractPairFirm', () => {
  it('reads the firm from meeting subjects', () => {
    expect(extractPairFirm('Invitation: Intro Meeting | MarineBio Group <> Strategic Ventures @ Thu Oct 1, 2026 2:30pm - 3pm (EDT) (yunyoung.heo@marinebiogroup.com)'))
      .toBe('Strategic Ventures');
    expect(extractPairFirm('Acme Capital <> MBG follow-up')).toBe('Acme Capital');
    expect(extractPairFirm('Re: FCC trial schedule')).toBeUndefined();
  });
});

describe('sender domain helpers', () => {
  it('normalises websites and matches sender domains', () => {
    expect(hostOf('https://www.APVentures.com/team')).toBe('apventures.com');
    expect(hostOf('apventures.com')).toBe('apventures.com');
    expect(hostOf('')).toBeUndefined();
    expect(domainMatches('apventures.com', 'apventures.com')).toBe(true);
    expect(domainMatches('mail.apventures.com', 'apventures.com')).toBe(true);
    expect(domainMatches('notapventures.com', 'apventures.com')).toBe(false);
  });
});

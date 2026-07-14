/**
 * __tests__/email/ndr-outcome.test.ts
 *
 * Pure-function tests for lib/email/ndr-outcome.ts (hard/soft NDR parsing).
 * Mirrors the real 2026-07-14 bounces (Planet A 550 5.2.1, Eclipse relay
 * rejection) plus soft-bounce and negative cases.
 */

import { describe, it, expect } from 'vitest';
import { detectNdrOutcome } from '../../lib/email/ndr-outcome';

const OWN = ['yunyoung.heo@marinebiogroup.com', 'marinebiogroup.com'];

describe('detectNdrOutcome', () => {
  it('parses an RFC-3464 hard bounce (550 5.2.1)', () => {
    const out = detectNdrOutcome({
      fromAddress: 'mailer-daemon@googlemail.com',
      fromName: 'Mail Delivery Subsystem',
      subject: 'Delivery Status Notification (Failure)',
      text: [
        'Your message could not be delivered.',
        'Final-Recipient: rfc822; startups@planet-a.com',
        'Action: failed',
        'Status: 5.2.1',
        'Diagnostic-Code: smtp; 550 5.2.1 The email account is disabled',
      ].join('\n'),
      contentType: 'multipart/report; report-type=delivery-status',
      ownAddresses: OWN,
    });
    expect(out).not.toBeNull();
    expect(out!.severity).toBe('hard');
    expect(out!.recipients).toEqual(['startups@planet-a.com']);
    expect(out!.smtpCode).toMatch(/^5/);
  });

  it('parses a soft bounce (4.2.2 mailbox full) as soft', () => {
    const out = detectNdrOutcome({
      fromAddress: 'postmaster@relay.example.net',
      subject: 'Undelivered Mail Returned to Sender',
      text: [
        '<jo@extantia.com>: host mx.extantia.com said:',
        '452 4.2.2 Mailbox full, try again later',
      ].join('\n'),
      ownAddresses: OWN,
    });
    expect(out).not.toBeNull();
    expect(out!.severity).toBe('soft');
    expect(out!.recipients).toEqual(['jo@extantia.com']);
  });

  it('parses the URM Korean self-notice (hard)', () => {
    const out = detectNdrOutcome({
      fromAddress: 'yunyoung.heo@marinebiogroup.com',
      subject: '[MailCarrier] 전송 실패',
      text: '받는 사람 <admin@eclipse.capital> 550 5.7.1 unauthorized external domain',
      ownAddresses: OWN,
    });
    expect(out).not.toBeNull();
    expect(out!.severity).toBe('hard');
    expect(out!.recipients).toEqual(['admin@eclipse.capital']);
  });

  it('never returns own or daemon addresses', () => {
    const out = detectNdrOutcome({
      fromAddress: 'mailer-daemon@example.com',
      subject: 'Undeliverable',
      text: [
        'From: yunyoung.heo@marinebiogroup.com',
        'RCPT TO:<craig@etvfund.com>',
        '550 5.1.1 User unknown',
      ].join('\n'),
      ownAddresses: OWN,
    });
    expect(out).not.toBeNull();
    expect(out!.recipients).toEqual(['craig@etvfund.com']);
  });

  it('returns null for a normal human reply', () => {
    const out = detectNdrOutcome({
      fromAddress: 'andrew@pangaeaventures.com',
      subject: 'Re: FCC intro',
      text: 'Thanks for reaching out - let us schedule a call.',
      ownAddresses: OWN,
    });
    expect(out).toBeNull();
  });

  it('returns null for an NDR-looking message without any SMTP code', () => {
    const out = detectNdrOutcome({
      fromAddress: 'postmaster@example.com',
      subject: 'Delivery incomplete',
      text: 'There was a temporary problem. No action is required.',
      ownAddresses: OWN,
    });
    expect(out).toBeNull();
  });
});

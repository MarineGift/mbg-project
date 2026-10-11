/**
 * lib/email/plain-to-html.ts
 *
 * The ONE plain-text -> HTML conversion for outbound mail (templates authored
 * as plain text, AI drafts, compose, sequences).
 *   - a blank line starts a new paragraph
 *   - lines inside a paragraph (e.g. "- bullet" lists) are joined with <br>,
 *     so lists stay tight instead of one paragraph per line
 *   - paragraph spacing is set inline (mail clients ignore <style> blocks and
 *     add their own <p> margins otherwise)
 *   - bare http(s) URLs become links
 */

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const URL_RE = /\bhttps?:\/\/[^\s<]+[^\s<.,;:!?)\]'"]/g;

function linkify(escaped: string): string {
  return escaped.replace(URL_RE, (u) => `<a href="${u}" style="color:#1d4ed8">${u}</a>`);
}

export function plainToHtml(text: string): string {
  if (!text) return '';
  const paragraphs = text
    .replace(/\r\n?/g, '\n')
    .split(/\n[ \t]*\n/)
    .map((p) => p.split('\n').map((l) => l.trim()).filter((l) => l !== ''))
    .filter((p) => p.length > 0);
  const html = paragraphs
    .map((lines) => `<p style="margin:0 0 12px 0">${lines.map((l) => linkify(escapeHtml(l))).join('<br>')}</p>`)
    .join('\n');
  return `<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;line-height:1.5;color:#222">${html}</div>`;
}

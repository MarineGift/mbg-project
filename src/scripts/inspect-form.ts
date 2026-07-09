// src/scripts/inspect-form.ts
//
// Selector collection helper for application web forms.
//
// Opens the given URL in a headed Chromium, then lets YOU navigate
// (dismiss cookie banners, log in, click through to the actual form).
// Each time you press Enter in this terminal it scans the CURRENT page
// (all frames) for input / textarea / select / contenteditable elements
// and writes the findings to a JSON file next to where you ran it.
//
// Usage:
//   npm run apply:inspect -- --url "https://app.dealum.com/#/company/application/new/72264/xxxx"
//   (or)  npx tsx --env-file=.env.local src/scripts/inspect-form.ts --url "<form url>"
//
// Commands at the prompt:
//   [Enter]  scan current page and save JSON
//   q        quit (closes the browser)
//
// The JSON rows map 1:1 onto app.application_form_fields columns:
//   suggestedSelector -> selector, suggestedSelectorType -> selector_type,
//   suggestedInputKind -> input_kind, maxLength -> max_length,
//   required -> is_required, label -> label
//
// LOCAL ONLY. Never run in CI or on a server.

import { chromium, type Frame, type Page } from '@playwright/test';
import * as fs from 'node:fs';
import * as readline from 'node:readline';

type ScannedField = {
  frameUrl: string;
  tag: string;
  type: string | null;
  id: string | null;
  name: string | null;
  placeholder: string | null;
  label: string | null;
  maxLength: number | null;
  required: boolean;
  options: string[] | null;
  suggestedSelector: string;
  suggestedSelectorType: 'css' | 'label' | 'placeholder';
  suggestedInputKind: 'fill' | 'check' | 'select_option' | 'upload';
};

function parseArg(flag: string): string | null {
  const i = process.argv.indexOf(flag);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : null;
}

async function scanFrame(frame: Frame): Promise<ScannedField[]> {
  try {
    return await frame.evaluate(() => {
      const cssEscape = (s: string) =>
        (window as any).CSS && (window as any).CSS.escape
          ? (window as any).CSS.escape(s)
          : s.replace(/([^a-zA-Z0-9_-])/g, '\\$1');

      const labelFor = (el: Element): string | null => {
        const id = el.getAttribute('id');
        if (id) {
          const l = document.querySelector(`label[for="${cssEscape(id)}"]`);
          if (l && l.textContent) return l.textContent.trim();
        }
        const wrap = el.closest('label');
        if (wrap && wrap.textContent) return wrap.textContent.trim();
        const aria = el.getAttribute('aria-label');
        if (aria) return aria.trim();
        const labelledBy = el.getAttribute('aria-labelledby');
        if (labelledBy) {
          const parts = labelledBy
            .split(/\s+/)
            .map((x) => document.getElementById(x)?.textContent?.trim() ?? '')
            .filter(Boolean);
          if (parts.length) return parts.join(' ');
        }
        return null;
      };

      const els = Array.from(
        document.querySelectorAll(
          'input, textarea, select, [contenteditable="true"]',
        ),
      ).filter((el) => {
        const t = (el.getAttribute('type') ?? '').toLowerCase();
        return t !== 'hidden' && t !== 'submit' && t !== 'button';
      });

      return els.map((el) => {
        const tag = el.tagName.toLowerCase();
        const type = el.getAttribute('type');
        const id = el.getAttribute('id');
        const name = el.getAttribute('name');
        const placeholder = el.getAttribute('placeholder');
        const label = labelFor(el);
        const maxAttr = el.getAttribute('maxlength');
        const maxLength = maxAttr ? parseInt(maxAttr, 10) : null;
        const required =
          el.hasAttribute('required') ||
          el.getAttribute('aria-required') === 'true';

        let options: string[] | null = null;
        if (tag === 'select') {
          options = Array.from((el as HTMLSelectElement).options).map(
            (o) => o.textContent?.trim() ?? o.value,
          );
        }

        // input_kind suggestion
        const t = (type ?? '').toLowerCase();
        let suggestedInputKind: 'fill' | 'check' | 'select_option' | 'upload' =
          'fill';
        if (tag === 'select') suggestedInputKind = 'select_option';
        else if (t === 'checkbox' || t === 'radio') suggestedInputKind = 'check';
        else if (t === 'file') suggestedInputKind = 'upload';

        // selector suggestion: id > name > placeholder > label
        let suggestedSelector = '';
        let suggestedSelectorType: 'css' | 'label' | 'placeholder' = 'css';
        if (id) {
          suggestedSelector = `#${cssEscape(id)}`;
        } else if (name) {
          suggestedSelector = `${tag}[name="${name}"]`;
        } else if (placeholder) {
          suggestedSelector = placeholder;
          suggestedSelectorType = 'placeholder';
        } else if (label) {
          suggestedSelector = label;
          suggestedSelectorType = 'label';
        } else {
          suggestedSelector = tag; // last resort, needs manual fix
        }

        return {
          frameUrl: location.href,
          tag,
          type,
          id,
          name,
          placeholder,
          label,
          maxLength,
          required,
          options,
          suggestedSelector,
          suggestedSelectorType,
          suggestedInputKind,
        };
      });
    });
  } catch {
    // cross-origin frame or detached frame: skip silently
    return [];
  }
}

async function scanPage(page: Page): Promise<ScannedField[]> {
  const all: ScannedField[] = [];
  for (const frame of page.frames()) {
    const rows = await scanFrame(frame);
    all.push(...rows);
  }
  return all;
}

function printSummary(rows: ScannedField[]): void {
  console.log('');
  console.log(`Found ${rows.length} candidate field(s):`);
  console.log('-'.repeat(88));
  rows.forEach((r, i) => {
    const lab = (r.label ?? r.placeholder ?? '(no label)').slice(0, 44);
    const max = r.maxLength != null ? ` max=${r.maxLength}` : '';
    const req = r.required ? ' required' : '';
    console.log(
      `[${String(i + 1).padStart(2)}] ${lab}`,
    );
    console.log(
      `     ${r.suggestedSelectorType}: ${r.suggestedSelector}  (${r.suggestedInputKind})${max}${req}`,
    );
  });
  console.log('-'.repeat(88));
}

async function main(): Promise<void> {
  const url = parseArg('--url') ?? process.argv[2];
  if (!url || !url.startsWith('http')) {
    console.error('Usage: npm run apply:inspect -- --url "<form url>"');
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  console.log('');
  console.log('Browser is open. Navigate to the actual form page yourself');
  console.log('(dismiss cookie banners, create an account or log in if needed).');
  console.log('');
  console.log('  [Enter] = scan the CURRENT page and save JSON');
  console.log('  q       = quit');
  console.log('');

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  let scanCount = 0;
  const ask = (): void => {
    rl.question('scan> ', async (answer) => {
      if (answer.trim().toLowerCase() === 'q') {
        rl.close();
        await browser.close();
        process.exit(0);
      }
      scanCount += 1;
      const rows = await scanPage(page);
      printSummary(rows);

      const host = new URL(page.url()).hostname.replace(/[^a-z0-9.-]/gi, '_');
      const file = `form-scan-${host}-${scanCount}.json`;
      fs.writeFileSync(file, JSON.stringify(rows, null, 2), 'utf8');
      console.log(`Saved: ${file}`);
      console.log('Paste that JSON back into the chat to generate the seed SQL.');
      ask();
    });
  };
  ask();
}

main().catch((err) => {
  console.error('inspect-form failed:', err);
  process.exit(1);
});

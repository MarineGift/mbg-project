// src/scripts/fill-application.ts
//
// Semi-automatic application form filler.
//
// DESIGN PRINCIPLES (do not weaken):
//   * NEVER auto-submits. Fills the fields, then page.pause() so a
//     human reviews everything and clicks Submit personally.
//     (many forms forbid automated submission in their terms; CAPTCHA,
//     login and file uploads need a human anyway; and a human eye is
//     the LAST line of defense against NDA-only text leaking out)
//   * HARD STOP if any field is nda_blocked. No browser is opened.
//   * Warns and asks for confirmation if any field is over_limit.
//   * LOCAL ONLY: uses the service-role key from .env.local.
//     Never run in CI or on a server.
//
// Usage:
//   npm run apply:fill -- --form <formId>
//
// Env (.env.local):
//   NEXT_PUBLIC_SUPABASE_URL   (already present)
//   SUPABASE_SERVICE_ROLE_KEY  (already present)
//   URM_ORG_ID                 org uuid; the service role bypasses RLS,
//                              so this script scopes every query manually
//   NDA_BLOCKLIST              optional, comma-separated partner terms.
//                              Kept OUT of the code on purpose: this repo
//                              is public, so the names live only in env.

import { chromium, type Page } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';
import * as readline from 'node:readline';

type FieldRow = {
  form_id: string;
  field_id: string | null;
  seq: number | null;
  label: string | null;
  field_type: string | null;
  max_length: number | null;
  is_required: boolean | null;
  final_text: string | null;
  char_count: number | null;
  field_state: 'empty' | 'over_limit' | 'nda_blocked' | 'ok' | null;
  selector: string | null;
  selector_type: 'css' | 'xpath' | 'label' | 'placeholder' | null;
  input_kind: 'fill' | 'check' | 'select_option' | 'upload' | null;
  party_name: string | null;
  form_url: string | null;
  submission_method: string | null;
  submit_email: string | null;
  login_required: boolean | null;
};

function parseArg(flag: string): string | null {
  const i = process.argv.indexOf(flag);
  // noUncheckedIndexedAccess: bind the indexed value once so it narrows.
  const v = i >= 0 ? process.argv[i + 1] : undefined;
  return v ?? null;
}

function requireEnv(key: string): string {
  const v = process.env[key];
  if (!v) {
    console.error(`Missing env: ${key} (check .env.local)`);
    process.exit(1);
  }
  return v;
}

function confirm(question: string): Promise<boolean> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(`${question} [y/N] `, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase() === 'y');
    });
  });
}

function waitForEnter(message: string): Promise<void> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(`${message} [Enter to continue] `, () => {
      rl.close();
      resolve();
    });
  });
}

function locatorFor(page: Page, row: FieldRow) {
  const sel = row.selector as string;
  switch (row.selector_type) {
    case 'xpath':
      return page.locator(`xpath=${sel}`);
    case 'label':
      return page.getByLabel(sel);
    case 'placeholder':
      return page.getByPlaceholder(sel);
    case 'css':
    default:
      return page.locator(sel);
  }
}

async function main(): Promise<void> {
  const formId = parseArg('--form');
  if (!formId) {
    console.error('Usage: npm run apply:fill -- --form <formId>');
    process.exit(1);
  }

  const url = requireEnv('NEXT_PUBLIC_SUPABASE_URL');
  const serviceKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
  const orgId = requireEnv('URM_ORG_ID');

  const supabase = createClient(url, serviceKey, {
    db: { schema: 'app' },
    auth: { persistSession: false },
  });

  // 1. Load field status (view already computes empty/over_limit/nda_blocked/ok)
  const { data, error } = await supabase
    .from('v_application_field_status')
    .select('*')
    .eq('form_id', formId)
    .eq('organization_id', orgId)
    .order('seq', { ascending: true });

  if (error) {
    console.error('Supabase query failed:', error.message);
    process.exit(1);
  }
  const rows = (data ?? []) as FieldRow[];
  // noUncheckedIndexedAccess: guard on rows[0] directly (process.exit is
  // typed `never`, so `head` narrows to FieldRow for the rest of main()).
  const head = rows[0];
  if (!head) {
    console.error('No form found for that id in this org.');
    process.exit(1);
  }
  console.log('');
  console.log(`Program : ${head.party_name}`);
  console.log(`Method  : ${head.submission_method}  login_required=${head.login_required}`);
  console.log(`URL     : ${head.form_url}`);

  const fields = rows.filter((r) => r.field_id != null);

  // 2. GUARD 1 — NDA. Hard stop, browser never opens.
  const ndaBlocked = fields.filter((r) => r.field_state === 'nda_blocked');
  if (ndaBlocked.length > 0) {
    console.error('');
    console.error('STOP: nda_only answers are bound to these fields.');
    console.error('These must NEVER be pasted into an external form.');
    for (const r of ndaBlocked) {
      console.error(`  [${r.seq}] ${r.label}`);
    }
    console.error('Rebind these fields to a public answer, then rerun.');
    process.exit(1);
  }

  // 2b. GUARD 1.5 — belt-and-suspenders text scan.
  //     Terms come from env (NDA_BLOCKLIST), never hardcoded: public repo.
  const blocklist = (process.env.NDA_BLOCKLIST ?? '')
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  if (blocklist.length > 0) {
    const hits = fields.filter((r) => {
      const t = (r.final_text ?? '').toLowerCase();
      return blocklist.some((term) => t.includes(term));
    });
    if (hits.length > 0) {
      console.error('');
      console.error('STOP: blocked partner terms found in final_text.');
      for (const r of hits) {
        console.error(`  [${r.seq}] ${r.label}`);
      }
      process.exit(1);
    }
  }

  // 3. GUARD 2 — over limit: warn, ask.
  const overLimit = fields.filter((r) => r.field_state === 'over_limit');
  if (overLimit.length > 0) {
    console.warn('');
    console.warn('WARNING: these fields exceed the form character limit:');
    for (const r of overLimit) {
      console.warn(`  [${r.seq}] ${r.label}  ${r.char_count}/${r.max_length}`);
    }
    const go = await confirm('Fill anyway (text may be cut off by the form)?');
    if (!go) process.exit(0);
  }

  // 3b. Required-but-empty: informational.
  const emptyRequired = fields.filter(
    (r) => r.field_state === 'empty' && r.is_required,
  );
  if (emptyRequired.length > 0) {
    console.warn('');
    console.warn('NOTE: required fields with no answer yet (will be skipped):');
    for (const r of emptyRequired) {
      console.warn(`  [${r.seq}] ${r.label}`);
    }
  }

  // 4. Email-based programs have nothing to fill.
  if (head.submission_method === 'email') {
    console.log('');
    console.log(`This program is email-based. Send to: ${head.submit_email}`);
    console.log('Use the /applications page to copy each answer.');
    process.exit(0);
  }

  // 5. Open the browser (headed) and go to the form.
  const fillable = fields.filter(
    (r) =>
      r.field_state === 'ok' &&
      r.selector != null &&
      r.final_text != null &&
      r.input_kind !== 'upload',
  );
  const uploads = fields.filter(
    (r) => r.input_kind === 'upload' && r.field_state !== 'empty',
  );

  console.log('');
  console.log(`Fillable fields: ${fillable.length}  (uploads left to human: ${uploads.length})`);

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(head.form_url as string, { waitUntil: 'domcontentloaded' });

  // 6. Portal login: human does it, script waits.
  if (head.login_required) {
    await waitForEnter(
      'Log in (or create the account) in the browser, navigate to the form,',
    );
  }

  // 7. Fill loop. Per-field try/catch so one bad selector never kills the run.
  const filledIds: string[] = [];
  for (const r of fillable) {
    const tag = `[${r.seq}] ${r.label}`;
    try {
      const loc = locatorFor(page, r).first();
      await loc.waitFor({ state: 'visible', timeout: 8000 });

      switch (r.input_kind) {
        case 'check':
          await loc.setChecked(true);
          break;
        case 'select_option':
          try {
            await loc.selectOption({ label: r.final_text as string });
          } catch {
            await loc.selectOption(r.final_text as string); // fall back to value
          }
          break;
        case 'fill':
        default:
          await loc.fill(r.final_text as string);
          break;
      }
      filledIds.push(r.field_id as string);
      console.log(`  OK    ${tag}`);
    } catch (err) {
      console.warn(
        `  FAIL  ${tag} -> ${err instanceof Error ? err.message.split('\n')[0] : err}`,
      );
    }
  }

  if (uploads.length > 0) {
    console.log('');
    console.log('Attach these files manually in the browser:');
    for (const r of uploads) {
      console.log(`  [${r.seq}] ${r.label}`);
    }
  }

  // 8. HAND OVER TO HUMAN. No auto submit, ever.
  console.log('');
  console.log('Filling done. Playwright Inspector will open and the browser stays up.');
  console.log('REVIEW EVERY FIELD, attach files, then click Submit YOURSELF.');
  console.log('Close the Inspector (Resume/close) when finished.');
  await page.pause();

  // 9. Bookkeeping after the human confirms.
  if (filledIds.length > 0) {
    const done = await confirm('Mark the filled answers as copied (is_copied=true)?');
    if (done) {
      const { error: updErr } = await supabase
        .from('application_field_answers')
        .update({ is_copied: true, updated_at: new Date().toISOString() })
        .in('field_id', filledIds)
        .eq('organization_id', orgId);
      if (updErr) console.error('is_copied update failed:', updErr.message);
      else console.log(`is_copied=true set on ${filledIds.length} answer(s).`);
    }
  }

  const submitted = await confirm('Did you actually submit the form?');
  if (submitted) {
    const { error: subErr } = await supabase
      .from('application_forms')
      .update({
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', formId)
      .eq('organization_id', orgId);
    if (subErr) console.error('status update failed:', subErr.message);
    else console.log('Form marked as submitted.');
  }

  await browser.close();
}

main().catch((err) => {
  console.error('fill-application failed:', err);
  process.exit(1);
});

/**
 * scripts/load-industry-db.ts
 *
 * Load V11.4 master DB from Excel into industry.* tables.
 * Idempotent — re-running updates existing rows by (market_code, legacy_id).
 *
 * Usage:
 *   tsx scripts/load-industry-db.ts [path/to/xlsx]
 *
 * Default path: ./data/Global_Paper_Filler_Master_Database_45_V11_4.xlsx
 *
 * Required env (from .env.local):
 *   NEXT_PUBLIC_SUPABASE_URL  (or SUPABASE_URL)
 *   SUPABASE_SERVICE_ROLE_KEY
 *
 * Required packages:
 *   npm i -D xlsx tsx
 */

import { config as loadEnv } from 'dotenv';
// .env.local 우선 (Next.js 컨벤션), .env fallback
loadEnv({ path: '.env.local' });
loadEnv({ path: '.env' });

import { createClient } from '@supabase/supabase-js';
import * as XLSXNS from 'xlsx';
const XLSX: any = (XLSXNS as any).default ?? XLSXNS;
import * as fs from 'node:fs';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const DEFAULT_XLSX = './data/Global_Paper_Filler_Master_Database_45_V11_4.xlsx';
const XLSX_PATH = process.argv[2] || DEFAULT_XLSX;
const BATCH = 500;

const SUPABASE_URL =
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  // fallback: derive from SUPABASE_DB_URL (postgresql://...@db.<ref>.supabase.co...)
  (() => {
    const db = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
    const m = db?.match(/@(?:db\.)?([^.]+)\.(?:supabase\.co|pooler\.supabase\.com)/);
    return m ? `https://${m[1]}.supabase.co` : undefined;
  })();
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('❌ Missing Supabase credentials in env');
  console.error(`   SUPABASE_URL resolved: ${SUPABASE_URL ?? '(none)'}`);
  console.error(`   SUPABASE_SERVICE_ROLE_KEY: ${SERVICE_KEY ? '(set)' : '(missing)'}`);
  console.error('   Checked: SUPABASE_URL, NEXT_PUBLIC_SUPABASE_URL, SUPABASE_DB_URL, DATABASE_URL');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});
const ind = () => supabase.schema('industry' as any);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function slugMarket(m: any): string | null {
  if (!m) return null;
  return String(m)
    .toLowerCase()
    .trim()
    .replace(/[\s\-]+/g, '_')
    .replace(/[()]/g, '')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

function txt(v: any): string | null {
  if (v === undefined || v === null) return null;
  const s = String(v).trim();
  return s.length === 0 ? null : s;
}

function int(v: any): number | null {
  if (v === undefined || v === null || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? Math.trunc(n) : null;
}

function parseArr(s: any): string[] | null {
  const t = txt(s);
  if (!t) return null;
  return t.split(/[,;]/).map((x) => x.trim()).filter(Boolean);
}

function gradeABC(s: any): string | null {
  const t = txt(s);
  if (!t) return null;
  const u = t.toUpperCase().charAt(0);
  return u === 'A' || u === 'B' || u === 'C' ? u : null;
}

async function upsertBatch(
  table: string,
  rows: any[],
  conflict: string,
  label: string,
) {
  let ok = 0;
  for (let i = 0; i < rows.length; i += BATCH) {
    const batch = rows.slice(i, i + BATCH);
    const { error } = await ind()
      .from(table)
      .upsert(batch, { onConflict: conflict });
    if (error) {
      console.error(`  ❌ [${label}] batch ${i}-${i + batch.length}:`, error.message);
      throw error;
    }
    ok += batch.length;
    process.stdout.write(`  [${label}] ${ok}/${rows.length}\r`);
  }
  process.stdout.write('\n');
  return ok;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log(`📂 Loading ${XLSX_PATH}\n`);
  if (!fs.existsSync(XLSX_PATH)) {
    console.error(`File not found: ${XLSX_PATH}`);
    process.exit(1);
  }
  const wb = XLSX.readFile(XLSX_PATH);

  // Validate markets seed
  const { data: markets, error: mErr } = await ind().from('markets').select('code');
  if (mErr) {
    console.error('Cannot read industry.markets — schema migration applied?', mErr.message);
    process.exit(1);
  }
  const validCodes = new Set((markets || []).map((m: any) => m.code));
  console.log(`✓ ${validCodes.size} markets seeded\n`);

  // -----------------------------------------------------------------------
  // Phase 1: paper_companies
  // -----------------------------------------------------------------------
  console.log('📋 Phase 1/6: paper_companies');
  const compRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Paper_Companies']);
  let compSkip = 0;
  const compRows = compRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    if (!mc || !validCodes.has(mc) || !r['Company']) { compSkip++; return []; }
    return [{
      market_code: mc,
      legacy_id: int(r['ID']),
      name: txt(r['Company']),
      headquarters: txt(r['Headquarters/Main Region']),
      europe_mills_footprint: txt(r['Key Europe Mills or Footprint']),
      main_product_category: txt(r['Main Product Category']),
      main_products: txt(r['Main Products']),
      filler_use_intensity: txt(r['Filler Use Intensity']),
      known_filler_types: parseArr(r['Known/Relevant Filler Types']),
      supply_structure_note: txt(r['Known/Likely Supply Structure']),
      onsite_pcc_evidence: txt(r['Public Evidence of On-site PCC']),
      evidence_level: gradeABC(r['Evidence Level']),
      source_url: txt(r['Source URL']),
      notes: txt(r['Notes']),
    }];
  });
  console.log(`  parsed=${compRows.length}, skipped=${compSkip}`);
  await upsertBatch('paper_companies', compRows, 'market_code,legacy_id', 'companies');

  // -----------------------------------------------------------------------
  // Phase 2: filler_suppliers
  // -----------------------------------------------------------------------
  console.log('\n📋 Phase 2/6: filler_suppliers');
  const supRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Filler_Suppliers']);
  let supSkip = 0;
  const supRows = supRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    if (!mc || !validCodes.has(mc) || !r['Supplier']) { supSkip++; return []; }
    return [{
      market_code: mc,
      legacy_id: int(r['ID']),
      name: txt(r['Supplier']),
      supplier_type: txt(r['Supplier Type']),
      market_role: txt(r['Europe Market Role']),
      relevant_filler_types: parseArr(r['Relevant Filler Types']),
      supply_model: txt(r['Supply Model']),
      europe_paper_evidence: txt(r['Public Europe Paper Evidence']),
      onsite_pcc_evidence: txt(r['Known Europe On-site/Near-site PCC Evidence']),
      evidence_level: gradeABC(r['Evidence Level']),
      source_url: txt(r['Source URL']),
      notes: txt(r['Notes']),
    }];
  });
  console.log(`  parsed=${supRows.length}, skipped=${supSkip}`);
  await upsertBatch('filler_suppliers', supRows, 'market_code,legacy_id', 'suppliers');

  // -----------------------------------------------------------------------
  // Phase 3: paper_mills (FK → paper_companies)
  // -----------------------------------------------------------------------
  console.log('\n📋 Phase 3/6: paper_mills');
  const { data: companies } = await ind()
    .from('paper_companies')
    .select('id, market_code, name');
  const companyIdx = new Map<string, number>();
  for (const c of companies || []) {
    companyIdx.set(`${c.market_code}::${c.name.toLowerCase().trim()}`, c.id);
  }

  const millRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Paper_Mills']);
  let millSkip = 0, millFkMiss = 0;
  const millRows = millRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    if (!mc || !validCodes.has(mc) || !r['Mill / Site']) { millSkip++; return []; }
    const compName = txt(r['Company']);
    let companyId: number | null = null;
    if (compName) {
      companyId = companyIdx.get(`${mc}::${compName.toLowerCase().trim()}`) ?? null;
      if (!companyId) millFkMiss++;
    }
    return [{
      paper_company_id: companyId,
      market_code: mc,
      legacy_id: int(r['ID']),
      company_name_raw: compName,
      mill_name: txt(r['Mill / Site']),
      city: txt(r['City / Region']),
      region: null,
      main_product_category: txt(r['Main Product Category']),
      main_products: txt(r['Main Products']),
      filler_probability: txt(r['Filler Probability']),
      basis_for_filler: txt(r['Basis']),
      likely_filler_types: parseArr(r['Likely Filler Type']),
      likely_supply_structure: txt(r['Likely Supply Structure']),
      likely_supplier_note: txt(r['Likely Supplier']),
      evidence_level: gradeABC(r['Evidence']),
      source_url: txt(r['Source URL']),
      notes: txt(r['Notes']),
    }];
  });
  console.log(`  parsed=${millRows.length}, skipped=${millSkip}, FK_unmatched=${millFkMiss}`);
  await upsertBatch('paper_mills', millRows, 'market_code,legacy_id', 'mills');

  // -----------------------------------------------------------------------
  // Phase 4: supplier_mill_linkages (FK × 3)
  // -----------------------------------------------------------------------
  console.log('\n📋 Phase 4/6: supplier_mill_linkages');
  const { data: suppliers } = await ind()
    .from('filler_suppliers').select('id, market_code, name');
  const supIdxByMarket = new Map<string, number>();
  const supIdxGlobal = new Map<string, number[]>();
  for (const s of suppliers || []) {
    supIdxByMarket.set(`${s.market_code}::${s.name.toLowerCase().trim()}`, s.id);
    const k = s.name.toLowerCase().trim();
    if (!supIdxGlobal.has(k)) supIdxGlobal.set(k, []);
    supIdxGlobal.get(k)!.push(s.id);
  }

  const { data: mills } = await ind()
    .from('paper_mills').select('id, market_code, mill_name');
  const millIdx = new Map<string, number>();
  for (const m of mills || []) {
    millIdx.set(`${m.market_code}::${(m.mill_name || '').toLowerCase().trim()}`, m.id);
  }

  const linkRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Reverse_Matrix']);
  let linkSkip = 0, lnkSupMiss = 0, lnkCompMiss = 0, lnkMillMiss = 0;
  const linkRows = linkRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    if (!mc || !validCodes.has(mc)) { linkSkip++; return []; }

    const supName = txt(r['Supplier']);
    let supId: number | null = null;
    if (supName) {
      const k = supName.toLowerCase().trim();
      supId = supIdxByMarket.get(`${mc}::${k}`) ?? null;
      if (!supId) {
        const ids = supIdxGlobal.get(k);
        if (ids && ids.length === 1) supId = ids[0];
      }
      if (!supId) lnkSupMiss++;
    }

    const compName = txt(r['Linked Paper Company']);
    let compId: number | null = null;
    if (compName) {
      compId = companyIdx.get(`${mc}::${compName.toLowerCase().trim()}`) ?? null;
      if (!compId) lnkCompMiss++;
    }

    const millName = txt(r['Linked Mill / Site']);
    let millId: number | null = null;
    if (millName) {
      millId = millIdx.get(`${mc}::${millName.toLowerCase().trim()}`) ?? null;
      if (!millId) lnkMillMiss++;
    }

    return [{
      market_code: mc,
      legacy_id: int(r['ID']),
      filler_supplier_id: supId,
      paper_company_id: compId,
      paper_mill_id: millId,
      supplier_name_raw: supName,
      paper_company_name_raw: compName,
      mill_site_raw: millName,
      country_region: txt(r['Country/Region']),
      relationship_type: txt(r['Relationship Type']),
      filler_type: txt(r['Filler Type']),
      supply_structure: txt(r['Supply Structure']),
      confirmation_status: txt(r['Confirmation Status']),
      confidence_grade: gradeABC(r['Confidence']),
      evidence_level: txt(r['Evidence Level']),
      supplier_evidence_url: txt(r['Supplier Evidence URL']),
      transaction_evidence_url: txt(r['Transaction Evidence URL']),
      customer_mill_evidence_url: txt(r['Customer/Mill Evidence URL']),
      current_status: txt(r['Current Status']),
      assessment_scope: txt(r['Assessment Scope']),
      notes: txt(r['Notes']),
    }];
  });
  console.log(`  parsed=${linkRows.length}, skipped=${linkSkip}`);
  console.log(`  FK_unmatched: supplier=${lnkSupMiss}, company=${lnkCompMiss}, mill=${lnkMillMiss}`);
  await upsertBatch('supplier_mill_linkages', linkRows, 'market_code,legacy_id', 'linkages');

  // -----------------------------------------------------------------------
  // Phase 5: market_findings (no legacy_id → delete-and-reload)
  // -----------------------------------------------------------------------
  console.log('\n📋 Phase 5/6: market_findings');
  const { error: delErr } = await ind()
    .from('market_findings').delete().gte('id', 0);
  if (delErr) console.warn(`  delete warning: ${delErr.message}`);

  const findRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Key_Findings']);
  let findSkip = 0;
  const findRows = findRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    const desc = txt(r['Description']);
    // skip header artifacts and empty rows
    if (!mc || !validCodes.has(mc) || !desc || desc === 'Detail') {
      findSkip++; return [];
    }
    return [{
      market_code: mc,
      finding_category: txt(r['Finding Category']),
      description: desc,
      evidence_source: txt(r['Evidence/Source']),
    }];
  });
  console.log(`  parsed=${findRows.length}, skipped=${findSkip}`);
  for (let i = 0; i < findRows.length; i += BATCH) {
    const batch = findRows.slice(i, i + BATCH);
    const { error } = await ind().from('market_findings').insert(batch);
    if (error) { console.error('  ❌ findings:', error.message); throw error; }
    process.stdout.write(`  [findings] ${Math.min(i + BATCH, findRows.length)}/${findRows.length}\r`);
  }
  process.stdout.write('\n');

  // -----------------------------------------------------------------------
  // Phase 6: verification_queue
  // -----------------------------------------------------------------------
  console.log('\n📋 Phase 6/6: verification_queue');
  const verRaw = XLSX.utils.sheet_to_json<any>(wb.Sheets['All_Needs_Verification']);
  let verSkip = 0, verFkMiss = 0;
  const verRows = verRaw.flatMap((r) => {
    const mc = slugMarket(r['Market']);
    if (!mc || !validCodes.has(mc)) { verSkip++; return []; }

    const supName = txt(r['Supplier']);
    let supId: number | null = null;
    if (supName) {
      const k = supName.toLowerCase().trim();
      supId = supIdxByMarket.get(`${mc}::${k}`) ?? null;
      if (!supId) {
        const ids = supIdxGlobal.get(k);
        if (ids && ids.length === 1) supId = ids[0];
      }
      if (!supId) verFkMiss++;
    }

    return [{
      market_code: mc,
      legacy_id: int(r['ID']),
      filler_supplier_id: supId,
      supplier_name_raw: supName,
      supplier_type: txt(r['Supplier Type']),
      country_market: txt(r['Country / Market']),
      potential_paper_company: txt(r['Potentially Linked Paper Company']),
      potential_mill_site: txt(r['Potentially Linked Mill / Site']),
      state_region: txt(r['State / Region']),
      city_district: txt(r['City / District']),
      hypothesized_relationship: txt(r['Hypothesized Relationship Type']),
      filler_type: txt(r['Filler Type']),
      likely_supply_structure: txt(r['Likely Supply Structure']),
      why_needs_verification: txt(r['Why It Needs Verification']),
      current_confidence: txt(r['Current Confidence']),
      best_evidence_url: txt(r['Best Available Evidence URL']),
      notes: txt(r['Notes']),
    }];
  });
  console.log(`  parsed=${verRows.length}, skipped=${verSkip}, FK_unmatched=${verFkMiss}`);
  await upsertBatch('verification_queue', verRows, 'market_code,legacy_id', 'verification');

  // -----------------------------------------------------------------------
  // Summary
  // -----------------------------------------------------------------------
  console.log('\n────────────────────────────────────────');
  console.log('✅ Load complete\n');
  console.log('다음 단계: RAG 임베딩 생성 (별도 스크립트)');
  console.log('  → scripts/embed-industry-findings.ts');
  console.log('  → OpenAI text-embedding-3-large 사용');
  console.log('────────────────────────────────────────');
}

main().catch((e) => {
  console.error('\n❌ Loader failed:', e);
  process.exit(1);
});

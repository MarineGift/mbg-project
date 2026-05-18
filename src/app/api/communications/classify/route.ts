// src/app/api/communications/classify/route.ts
// ============================================================
// Phase 22a — AI Sentiment Classification API
//
// Two usage modes:
//   1. POST single — body: { communication_id: "uuid" }
//      Called by IMAP handler right after insert (fire-and-forget OK)
//
//   2. POST batch (no body) — processes all pending inbound emails
//      Called by cron job every 1-5 minutes
//      Uses idx_communications_pending_classification index
//
// Protected by x-cron-secret header (same as sequence processor)
// ============================================================
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { classifyInboundEmail } from "@/lib/actions/email-compose";

const BATCH_SIZE = 20;        // process up to 20 per call
const MAX_AGE_MINUTES = 60;   // skip emails older than 1hr (likely already processed manually)

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function isAuthorized(req: NextRequest): boolean {
  const secret = req.headers.get("x-cron-secret");
  return secret === process.env.CRON_SECRET;
}

function getServiceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );
}

// ────────────────────────────────────────────────────────────
// POST /api/communications/classify
//   body: { communication_id?: string }
//   - if communication_id provided: classify just that one
//   - else: batch process all pending
// ────────────────────────────────────────────────────────────
export async function POST(req: NextRequest) {
  if (!isAuthorized(req)) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  // Try to read body (single mode)
  let singleId: string | null = null;
  try {
    const body = await req.json();
    if (body?.communication_id) {
      singleId = String(body.communication_id);
    }
  } catch {
    // no body or invalid JSON → batch mode
  }

  // ─── Single mode ───
  if (singleId) {
    const res = await classifyInboundEmail(singleId);
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: res.error, communication_id: singleId },
        { status: 500 }
      );
    }
    return NextResponse.json({
      ok: true,
      mode: "single",
      communication_id: singleId,
      classification: res.classification,
    });
  }

  // ─── Batch mode ───
  const supabase = getServiceClient();

  // Fetch pending inbound emails (uses idx_communications_pending_classification)
  const cutoff = new Date(Date.now() - MAX_AGE_MINUTES * 60_000).toISOString();
  const { data: pending, error } = await supabase
    .schema("app")
    .from("communications")
    .select("id, organization_id, occurred_at")
    .eq("direction", "inbound")
    .is("ai_classification", null)
    .is("deleted_at", null)
    .gte("occurred_at", cutoff)
    .order("occurred_at", { ascending: true })
    .limit(BATCH_SIZE);

  if (error) {
    console.error("[classify batch] fetch error", error);
    return NextResponse.json(
      { ok: false, error: error.message },
      { status: 500 }
    );
  }

  if (!pending || pending.length === 0) {
    return NextResponse.json({ ok: true, mode: "batch", processed: 0 });
  }

  // Mark as "processing" first to prevent double-classification
  const ids = pending.map((p) => p.id);
  await supabase
    .schema("app")
    .from("communications")
    .update({
      ai_processing_status: "processing",
      updated_at: new Date().toISOString(),
    })
    .in("id", ids);

  // Classify each (sequentially to control rate)
  let succeeded = 0;
  let failed = 0;
  const errors: Array<{ id: string; error: string }> = [];

  for (const row of pending) {
    try {
      const res = await classifyInboundEmail(row.id);
      if (res.ok) {
        succeeded++;
      } else {
        failed++;
        errors.push({ id: row.id, error: res.error });

        // Mark as failed (will retry on next cron run)
        await supabase
          .schema("app")
          .from("communications")
          .update({
            ai_processing_status: "failed",
            updated_at: new Date().toISOString(),
          })
          .eq("id", row.id);
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      failed++;
      errors.push({ id: row.id, error: msg });
    }
  }

  return NextResponse.json({
    ok: true,
    mode: "batch",
    processed: pending.length,
    succeeded,
    failed,
    errors: errors.slice(0, 5),  // truncate
  });
}

// ────────────────────────────────────────────────────────────
// GET /api/communications/classify  (status / health)
// ────────────────────────────────────────────────────────────
export async function GET(req: NextRequest) {
  if (!isAuthorized(req)) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const supabase = getServiceClient();

  // Count pending inbound
  const { count: pendingCount } = await supabase
    .schema("app")
    .from("communications")
    .select("*", { count: "exact", head: true })
    .eq("direction", "inbound")
    .is("ai_classification", null)
    .is("deleted_at", null);

  // Count classified last 24h
  const yesterday = new Date(Date.now() - 86_400_000).toISOString();
  const { count: classifiedRecent } = await supabase
    .schema("app")
    .from("communications")
    .select("*", { count: "exact", head: true })
    .eq("direction", "inbound")
    .not("ai_classification", "is", null)
    .gte("updated_at", yesterday);

  return NextResponse.json({
    ok: true,
    pending: pendingCount ?? 0,
    classified_last_24h: classifiedRecent ?? 0,
  });
}

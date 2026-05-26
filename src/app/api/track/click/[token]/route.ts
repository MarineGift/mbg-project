// src/app/api/track/click/[token]/route.ts
// Records a click event then 302-redirects to the original URL.
// This route is intentionally PUBLIC (no auth) — clicked from email clients.

import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const FALLBACK_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'https://example.com';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } }
);

export async function GET(
  req: NextRequest,
  { params }: { params: { token: string } }
) {
  const { token } = params;
  const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null;
  const ua = req.headers.get('user-agent') ?? null;

  const { data, error } = await supabase.rpc('record_email_click', {
    p_token: token,
    p_ip: ip,
    p_ua: ua,
  });

  const destination = (!error && typeof data === 'string' && data.length > 0)
    ? data
    : FALLBACK_URL;

  return NextResponse.redirect(destination, { status: 302 });
}

// src/app/api/sequences/process/route.ts
// Cron endpoint: POST /api/sequences/process
// Security: x-cron-secret header required
//
// Call example (external cron service):
//   curl -X POST https://yourdomain.com/api/sequences/process \
//     -H "x-cron-secret: YOUR_SECRET"
//
// Vercel Cron (add to vercel.json):
//   { "crons": [{ "path": "/api/sequences/process", "schedule": "0 * * * *" }] }
//   -> Vercel calls via GET, so a GET handler is also provided

import { NextRequest, NextResponse } from 'next/server';
import { processSequence } from '@/lib/utils/sequence-processor';

function isAuthorized(req: NextRequest): boolean {
  const secret = process.env.CRON_SECRET;
  if (!secret) return false; // secret not set = disabled
  const header = req.headers.get('x-cron-secret');
  // Vercel Cron uses Authorization: Bearer {CRON_SECRET}
  const bearer = req.headers.get('authorization')?.replace('Bearer ', '');
  return header === secret || bearer === secret;
}

export async function POST(req: NextRequest) {
  if (!isAuthorized(req)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  try {
    const result = await processSequence();
    return NextResponse.json(result);
  } catch (err) {
    console.error('[sequences/process] Error:', err);
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}

// Vercel Cron calls via the GET method
export async function GET(req: NextRequest) {
  return POST(req);
}

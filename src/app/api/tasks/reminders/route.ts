// src/app/api/tasks/reminders/route.ts
// Cron endpoint: POST (or GET) /api/tasks/reminders
// Security: CRON_SECRET, same convention as /api/sequences/process
//   - header  x-cron-secret: <CRON_SECRET>
//   - or      Authorization: Bearer <CRON_SECRET>   (Vercel Cron style)
//
// Frequency is up to the scheduler — the worker is idempotent per day via
// todo_items.reminded_at, so it is safe to run hourly OR once each morning:
//   Daily 08:00 : { "path": "/api/tasks/reminders", "schedule": "0 8 * * *" }
//   Hourly      : { "path": "/api/tasks/reminders", "schedule": "0 * * * *" }
// Running hourly simply means a task that becomes due mid-day still gets a
// same-day reminder, without ever double-sending.

import { NextRequest, NextResponse } from 'next/server';
import { runTaskReminders } from '@/lib/tasks/reminder-worker';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function isAuthorized(req: NextRequest): boolean {
  const secret = process.env.CRON_SECRET;
  if (!secret) return false; // not configured = disabled
  const header = req.headers.get('x-cron-secret');
  const bearer = req.headers.get('authorization')?.replace('Bearer ', '');
  return header === secret || bearer === secret;
}

export async function POST(req: NextRequest) {
  if (!isAuthorized(req)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  try {
    const result = await runTaskReminders();
    return NextResponse.json(result);
  } catch (err) {
    console.error('[tasks/reminders] Error:', err);
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}

// Vercel Cron issues GET requests.
export async function GET(req: NextRequest) {
  return POST(req);
}

// src/app/api/sequences/debug-auth/route.ts
// TEMPORARY diagnostic endpoint for the sequence processor 401.
// Does NOT expose the secret value -- only lengths and a match flag.
// DELETE this file once the 401 is resolved.

import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const envSecret = process.env.CRON_SECRET ?? null;
  const header = req.headers.get('x-cron-secret');
  const bearer = req.headers.get('authorization')?.replace('Bearer ', '') ?? null;

  return NextResponse.json({
    build_marker: 'debug-auth-v1', // confirms this NEW code is deployed
    env_secret_present: envSecret !== null && envSecret !== '',
    env_secret_length: envSecret ? envSecret.length : 0,
    header_present: header !== null,
    header_length: header ? header.length : 0,
    header_matches_env: !!envSecret && header === envSecret,
    bearer_present: bearer !== null,
    bearer_matches_env: !!envSecret && bearer === envSecret,
  });
}

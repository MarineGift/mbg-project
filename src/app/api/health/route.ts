import { NextResponse } from 'next/server';
import { getAdminSupabase } from '@/lib/supabase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

interface HealthResponse {
  status: 'ok' | 'degraded' | 'down';
  version: string;
  timestamp: string;
  checks: {
    database: 'ok' | 'fail';
    storage: 'ok' | 'fail' | 'unknown';
  };
  errors?: string[];
}

export async function GET(): Promise<NextResponse<HealthResponse>> {
  const errors: string[] = [];
  const checks: HealthResponse['checks'] = { database: 'ok', storage: 'unknown' };

  try {
    const supa = getAdminSupabase();
    // app.communications에 대한 가벼운 SELECT (RLS 우회 — service role)
    const { error } = await supa
      .schema('app')
      .from('communications')
      .select('id', { head: true, count: 'exact' })
      .limit(1);
    if (error) {
      checks.database = 'fail';
      errors.push(`DB: ${error.message}`);
    }
  } catch (err) {
    checks.database = 'fail';
    errors.push(`DB exception: ${(err as Error).message}`);
  }

  const status: HealthResponse['status'] = checks.database === 'ok' ? 'ok' : 'down';

  const body: HealthResponse = {
    status,
    version: process.env.npm_package_version ?? '0.2.0',
    timestamp: new Date().toISOString(),
    checks,
    errors: errors.length > 0 ? errors : undefined,
  };

  return NextResponse.json(body, { status: status === 'ok' ? 200 : 503 });
}

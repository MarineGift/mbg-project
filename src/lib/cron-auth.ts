import 'server-only';
import { env } from '@/lib/env';
import type { NextRequest } from 'next/server';

/**
 * Vercel Cron이 호출 시 자동으로 보내는 헤더:
 *   Authorization: Bearer <CRON_SECRET 환경변수>
 *
 * 참고: https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs
 *
 * @returns 인증 통과 시 null, 실패 시 에러 메시지
 */
export function verifyCronAuth(request: NextRequest): string | null {
  if (!env.CRON_SECRET) {
    return 'CRON_SECRET environment variable is not set';
  }
  const authHeader = request.headers.get('authorization');
  const expected = `Bearer ${env.CRON_SECRET}`;
  if (!authHeader || authHeader !== expected) {
    return 'invalid_or_missing_cron_secret';
  }
  return null;
}

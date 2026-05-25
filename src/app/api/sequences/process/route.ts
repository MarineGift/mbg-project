// src/app/api/sequences/process/route.ts
// Cron 엔드포인트: POST /api/sequences/process
// 보안: x-cron-secret 헤더 필수
//
// 호출 예시 (외부 cron 서비스):
//   curl -X POST https://yourdomain.com/api/sequences/process \
//     -H "x-cron-secret: YOUR_SECRET"
//
// Vercel Cron (vercel.json에 추가):
//   { "crons": [{ "path": "/api/sequences/process", "schedule": "0 * * * *" }] }
//   → Vercel은 GET으로 호출하므로 GET 핸들러도 제공

import { NextRequest, NextResponse } from 'next/server';
import { processSequence } from '@/lib/utils/sequence-processor';

function isAuthorized(req: NextRequest): boolean {
  const secret = process.env.CRON_SECRET;
  if (!secret) return false; // secret 미설정 = 비활성화
  const header = req.headers.get('x-cron-secret');
  // Vercel Cron은 Authorization: Bearer {CRON_SECRET} 사용
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

// Vercel Cron은 GET 메서드로 호출
export async function GET(req: NextRequest) {
  return POST(req);
}

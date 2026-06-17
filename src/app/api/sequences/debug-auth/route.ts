// src/app/api/sequences/debug-auth/route.ts
// TEMPORARY diagnostic endpoint. Does NOT expose secret/SMTP values --
// only presence + lengths. DELETE this file once the issue is resolved.

import { NextRequest, NextResponse } from 'next/server';

function info(v: string | undefined | null) {
  return { present: !!v && v !== '', length: v ? v.length : 0 };
}

export async function GET(req: NextRequest) {
  const envSecret = process.env.CRON_SECRET ?? null;
  const header = req.headers.get('x-cron-secret');

  return NextResponse.json({
    build_marker: 'debug-auth-v2',
    cron: {
      env_secret_present: envSecret !== null && envSecret !== '',
      env_secret_length: envSecret ? envSecret.length : 0,
      header_matches_env: !!envSecret && header === envSecret,
    },
    smtp: {
      TABS_MAILER_HOST: info(process.env.TABS_MAILER_HOST),
      TABS_MAILER_PORT: info(process.env.TABS_MAILER_PORT),
      TABS_MAILER_USERNAME: info(process.env.TABS_MAILER_USERNAME),
      TABS_MAILER_PASSWORD: info(process.env.TABS_MAILER_PASSWORD),
      TABS_MAILER_USE_MOCK: process.env.TABS_MAILER_USE_MOCK ?? null,
    },
    // also check the alternative mail var names that DO appear in Railway
    alt_mail: {
      MAILCARRIER_HOST: info(process.env.MAILCARRIER_HOST),
      MAIL_PERSONAL_USERNAME: info(process.env.MAIL_PERSONAL_USERNAME),
      MAIL_ROLE_USERNAME: info(process.env.MAIL_ROLE_USERNAME),
    },
  });
}

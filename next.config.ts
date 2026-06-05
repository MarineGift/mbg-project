import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,

  // STEP 3 워커들은 Node 전용 패키지(imapflow, mailparser, pg 등)를 사용.
  // App Router에서 서버 액션·라우트 핸들러가 import 시 webpack이 외부화하도록.
  serverExternalPackages: [
    'imapflow',
    'mailparser',
    'nodemailer',
    'pg',
    '@anthropic-ai/sdk',
    'openai',
  ],

  // Supabase Storage public URL 패턴 (첨부·아바타용)
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },

  // 빌드 시간에 typecheck/lint는 별도 스크립트로 (CI에서 명시 실행)
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },
};

export default withNextIntl(nextConfig);

/**
 * @type {import('next').NextConfig}
 *
 * Next.js 14.2.13는 next.config.ts를 정식 지원하지 않음 → .mjs 형식 사용.
 * Next 15에서 .ts 지원 안정화 후 마이그레이션 가능.
 */

import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,

  // STEP 3 워커들이 사용하는 Node 전용 패키지를 webpack이 외부화하도록.
  // (Next 14는 experimental.serverComponentsExternalPackages, Next 15는 serverExternalPackages.
  //  현재 버전은 experimental 안에 두어야 함)
  experimental: {
    serverComponentsExternalPackages: [
      'imapflow',
      'mailparser',
      'nodemailer',
      'pg',
      '@anthropic-ai/sdk',
      'openai',
    ],
  },

  // Supabase Storage public URL 패턴 (첨부·아바타용)
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },

  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },
};

export default withNextIntl(nextConfig);

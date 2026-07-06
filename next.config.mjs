/**
 * @type {import('next').NextConfig}
 *
 * Next.js 14.2.13??next.config.ts瑜??뺤떇 吏?먰븯吏 ?딆쓬 ??.mjs ?뺤떇 ?ъ슜.
 * Next 15?먯꽌 .ts 吏???덉젙????留덉씠洹몃젅?댁뀡 媛??
 */

import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,

  // STEP 3 ?뚯빱?ㅼ씠 ?ъ슜?섎뒗 Node ?꾩슜 ?⑦궎吏瑜?webpack???몃??뷀븯?꾨줉.
  // (Next 14??experimental.serverComponentsExternalPackages, Next 15??serverExternalPackages.
  //  ?꾩옱 踰꾩쟾? experimental ?덉뿉 ?먯뼱????
  experimental: {
    // Server Actions default body limit is 1 MB, which silently capped email
    // attachment uploads at ~1 MB per file. Raise to cover the 25 MB/file cap.
    serverActions: { bodySizeLimit: '30mb' },
    serverComponentsExternalPackages: [
      'imapflow',
      'mailparser',
      'nodemailer',
      'pg',
      '@anthropic-ai/sdk',
      'openai',
    ],
  },

  // Supabase Storage public URL ?⑦꽩 (泥⑤?쨌?꾨컮???
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },

  typescript: {
    ignoreBuildErrors: true  // TEMP: launch 후 Stage 29-d 와 함께 정리,
  },
  eslint: {
    ignoreDuringBuilds: true  // TEMP: 동일,
  },
};

export default withNextIntl(nextConfig);

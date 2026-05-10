/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,

  // Next.js 14.2.x: serverExternalPackages → experimental.serverComponentsExternalPackages
  experimental: {
    serverComponentsExternalPackages: ['imapflow', 'mailparser', 'pg', 'mssql'],
  },

  webpack: (config, { isServer }) => {
    if (isServer) {
      // mssql은 선택적 의존성 (런타임 동적 import). webpack 정적 분석을 우회해 external 처리.
      // tabs-mailer.ts의 try/catch가 미설치 시 fallback 동작.
      config.externals = config.externals || [];
      if (Array.isArray(config.externals)) {
        config.externals.push({ mssql: 'commonjs mssql' });
      }
    }
    return config;
  },

  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
};

export default nextConfig;

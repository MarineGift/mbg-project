import type { Config } from 'tailwindcss';

/**
 * URM Platform 디자인 토큰.
 *
 * 색상 결정 근거:
 * - neutral 계열은 zinc (회색이 약간 따뜻함, Stripe/Linear 류와 유사)
 * - primary는 한국 SaaS 톤(차분한 indigo/slate)에 맞춰 slate-900 (거의 검정)
 * - accent (CTA)는 emerald-600 (긍정 액션 — 승인·발송)
 * - destructive는 red-600 (거절·삭제·실패)
 * - warning은 amber-500 (위험 플래그·차단)
 *
 * 향후 다크 모드를 도입할 때는 CSS 변수 기반(`hsl(var(--bg))` 등)으로 전환하면 됨.
 * 현재는 라이트 단일이라 직접 색상 사용.
 */
const config: Config = {
  content: [
    './src/app/**/*.{ts,tsx}',
    './src/lib/**/*.{ts,tsx}',
    './src/types/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // 의미적 alias — 컴포넌트에서 'bg-surface', 'text-muted-foreground' 사용
        surface: {
          DEFAULT: '#ffffff',
          subtle: '#fafafa',
          muted: '#f4f4f5',
        },
        border: {
          DEFAULT: '#e5e5e5',
          subtle: '#f0f0f0',
          strong: '#d4d4d8',
        },
        // primary = 차분한 거의 검정 (CTA 외 텍스트·강조)
        primary: {
          DEFAULT: '#18181b',
          foreground: '#fafafa',
        },
        // accent = CTA 긍정 액션 (승인·발송)
        accent: {
          DEFAULT: '#15803d',
          hover: '#166534',
          foreground: '#ffffff',
          subtle: '#dcfce7',
        },
        // destructive = 거절·삭제
        destructive: {
          DEFAULT: '#b91c1c',
          hover: '#991b1b',
          foreground: '#ffffff',
          subtle: '#fef2f2',
          border: '#fecaca',
        },
        // warning = 위험 플래그·차단·자동발송 사유
        warning: {
          DEFAULT: '#b45309',
          foreground: '#92400e',
          subtle: '#fef3c7',
          border: '#fde68a',
        },
        // info = 정보·읽지 않음·신규
        info: {
          DEFAULT: '#1e40af',
          foreground: '#1e40af',
          subtle: '#dbeafe',
          border: '#bfdbfe',
        },
        // muted = 보조 텍스트
        muted: {
          DEFAULT: '#737373',
          foreground: '#666666',
        },
      },
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          '"Helvetica Neue"',
          'Arial',
          'sans-serif',
          // 한국어 fallback (Pretendard 도입 시 여기 prepend)
          '"Apple SD Gothic Neo"',
          '"Malgun Gothic"',
        ],
        mono: [
          'ui-monospace',
          'SFMono-Regular',
          '"SF Mono"',
          'Menlo',
          'Consolas',
          '"Liberation Mono"',
          'monospace',
        ],
      },
      fontSize: {
        // 기본 1rem=16px. 본 프로젝트는 13~14px 본문이 표준이라 명시.
        xs: ['0.6875rem', { lineHeight: '1rem' }], // 11px
        sm: ['0.75rem', { lineHeight: '1.125rem' }], // 12px
        base: ['0.8125rem', { lineHeight: '1.375rem' }], // 13px
        md: ['0.875rem', { lineHeight: '1.5rem' }], // 14px
        lg: ['1rem', { lineHeight: '1.625rem' }], // 16px
        xl: ['1.125rem', { lineHeight: '1.75rem' }], // 18px
        '2xl': ['1.375rem', { lineHeight: '2rem' }], // 22px
        '3xl': ['1.75rem', { lineHeight: '2.25rem' }], // 28px
      },
      borderRadius: {
        sm: '4px',
        DEFAULT: '6px',
        md: '8px',
        lg: '12px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(0,0,0,0.04)',
        focus: '0 0 0 2px rgba(24,24,27,0.1)',
      },
    },
  },
  plugins: [],
};

export default config;

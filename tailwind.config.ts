import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/app/**/*.{ts,tsx}',
    './src/components/**/*.{ts,tsx}',
    './src/hooks/**/*.{ts,tsx}',
    './src/lib/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '1rem',
      screens: {
        '2xl': '1400px',
      },
    },
    extend: {
      fontFamily: {
        sans: [
          'var(--font-inter)',
          'var(--font-noto-kr)',
          'var(--font-noto-jp)',
          'system-ui',
          'sans-serif',
        ],
        mono: ['var(--font-jetbrains-mono)', 'ui-monospace', 'monospace'],
      },
      colors: {
        // shadcn 표준 HSL 변수 (globals.css에서 정의)
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },

        // 7개 모듈 컬러 토큰 (마스터 §3.1 모듈 enum과 일치)
        party: {
          investor: { DEFAULT: '#7c3aed', foreground: '#ffffff' },
          buyer: { DEFAULT: '#2563eb', foreground: '#ffffff' },
          partner: { DEFAULT: '#16a34a', foreground: '#ffffff' },
          customer: { DEFAULT: '#ea580c', foreground: '#ffffff' },
          crowdfunding: { DEFAULT: '#db2777', foreground: '#ffffff' },
        },

        // ai.draft_status enum 6개에 대한 상태 컬러
        status: {
          pending_review: 'hsl(45 95% 55%)',  // 노랑 — 검토 대기
          approved: 'hsl(143 64% 45%)',        // 초록 — 승인
          sent: 'hsl(217 91% 60%)',            // 파랑 — 발송 완료
          rejected: 'hsl(0 84% 60%)',          // 빨강 — 거부
          expired: 'hsl(0 0% 60%)',            // 회색 — 만료
          auto_sent: 'hsl(173 80% 40%)',       // 청록 — 자동 발송
        },

        // 위험 표시
        risk: {
          DEFAULT: 'hsl(0 84% 60%)',
          foreground: '#ffffff',
        },

        // 신뢰도 단계 컬러 (큐 정렬 시 시각 신호)
        confidence: {
          low: 'hsl(0 84% 60%)',     // < 0.7
          medium: 'hsl(45 95% 55%)', // 0.7 ~ 0.9
          high: 'hsl(143 64% 45%)',  // ≥ 0.9
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;

'use client';

// src/components/schedule/load-template-button.tsx
// 06:00~23:00 기본 일과표를 현재 사용자에게 주입하는 버튼.

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2, Sparkles } from 'lucide-react';
import { loadDefaultTemplate } from '@/app/actions/schedule';

export function LoadTemplateButton() {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  return (
    <button
      type="button"
      disabled={isPending}
      onClick={() =>
        startTransition(async () => {
          const res = await loadDefaultTemplate();
          if (!res.success) {
            alert(`불러오기 실패: ${res.error}`);
            return;
          }
          router.refresh();
        })
      }
      className="inline-flex items-center gap-1.5 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
    >
      {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
      기본 일정표 불러오기
    </button>
  );
}

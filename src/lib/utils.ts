/**
 * lib/utils.ts
 *
 * 클래스 이름 병합 유틸. shadcn/ui 표준 패턴.
 *
 *   cn('px-2 py-1', condition && 'bg-blue-500', 'px-4')
 *     → 'py-1 bg-blue-500 px-4'  (px-2가 px-4로 덮어쓰여짐)
 *
 * tailwind-merge가 충돌 클래스(예: px-2 vs px-4)를 후자로 통합.
 */

import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

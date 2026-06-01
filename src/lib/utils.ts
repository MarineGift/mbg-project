/**
 * lib/utils.ts
 *
 * Class-name merge utility. Standard shadcn/ui pattern.
 *
 *   cn('px-2 py-1', condition && 'bg-blue-500', 'px-4')
 *     -> 'py-1 bg-blue-500 px-4'  (px-2 is overwritten by px-4)
 *
 * tailwind-merge consolidates conflicting classes (e.g. px-2 vs px-4) to the latter.
 */

import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

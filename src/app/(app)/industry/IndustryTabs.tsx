// src/app/(app)/industry/IndustryTabs.tsx
// 변경: 경로만 (app)/industry, 코드 자체는 동일
// 주의: '@/lib/utils'의 cn 함수가 있어야 함 (shadcn init 시 자동 생성)
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const tabs = [
  { href: '/industry/paper-mills', label: 'Paper Mills' },
  { href: '/industry/paper-companies', label: 'Paper Companies' },
  { href: '/industry/filler-suppliers', label: 'Filler Suppliers' },
]

export function IndustryTabs() {
  const pathname = usePathname()
  return (
    <nav className="flex gap-1 border-b">
      {tabs.map(tab => {
        const isActive = pathname.startsWith(tab.href)
        return (
          <Link
            key={tab.href}
            href={tab.href}
            className={cn(
              "px-4 py-2 text-sm font-medium -mb-px border-b-2",
              isActive
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            )}
          >
            {tab.label}
          </Link>
        )
      })}
    </nav>
  )
}
// src/app/(app)/industry/layout.tsx
// 변경: 원본 (authenticated)/industry → (app)/industry, 코드 자체는 동일
import { IndustryTabs } from './IndustryTabs'

export default function IndustryLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-baseline justify-between">
        <div>
          <h1 className="text-3xl font-bold">Industry Data</h1>
          <p className="text-sm text-muted-foreground">
            Paper mills, paper companies, and filler suppliers — master data
          </p>
        </div>
      </div>
      <IndustryTabs />
      <div>{children}</div>
    </div>
  )
}
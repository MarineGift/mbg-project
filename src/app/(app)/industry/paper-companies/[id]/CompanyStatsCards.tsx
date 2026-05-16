// src/app/(app)/industry/paper-companies/[id]/CompanyStatsCards.tsx
// v5.8 Step B1 EN
'use client'

import { Card, CardContent } from '@/components/ui/card'

type Stats = {
  totalMills: number
  millsWithSuppliers: number
  totalSupplierCount: number
  millsWithLikelyOnly: number
}

export function CompanyStatsCards({ stats }: { stats: Stats }) {
  const coverage =
    stats.totalMills > 0
      ? Math.round((stats.millsWithSuppliers / stats.totalMills) * 100)
      : 0

  const cards = [
    {
      label: 'Total Mills',
      value: stats.totalMills,
      hint: 'Mills owned by company',
    },
    {
      label: 'Mills w/ Confirmed Supplier',
      value: stats.millsWithSuppliers,
      hint: `${coverage}% coverage`,
    },
    {
      label: 'Unique Suppliers',
      value: stats.totalSupplierCount,
      hint: 'Active suppliers',
    },
    {
      label: 'Likely-Only Mills',
      value: stats.millsWithLikelyOnly,
      hint: '⭐ Sales priority — no confirmed supplier',
      highlight: stats.millsWithLikelyOnly > 0,
    },
  ]

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {cards.map((card) => (
        <Card key={card.label} className={card.highlight ? 'border-primary/50' : ''}>
          <CardContent className="p-4 space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">
              {card.label}
            </div>
            <div className="text-2xl font-bold">{card.value}</div>
            <div className="text-xs text-muted-foreground">{card.hint}</div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

// src/app/(app)/industry/filler-suppliers/[id]/SupplierStatsCards.tsx
// v5.8 Step B3 EN
'use client'

import { Card, CardContent } from '@/components/ui/card'

type Stats = {
  totalLinks: number
  millSpecificCount: number
  footprintCount: number
  uniquePaperCompanies: number
  uniqueMills: number
}

export function SupplierStatsCards({ stats }: { stats: Stats }) {
  const cards = [
    {
      label: 'Total Linkages',
      value: stats.totalLinks,
      hint: 'Mill-Specific + Footprint',
    },
    {
      label: 'Mill-Specific',
      value: stats.millSpecificCount,
      hint: `${stats.uniqueMills} unique mills`,
    },
    {
      label: 'Footprint',
      value: stats.footprintCount,
      hint: 'Region-level only',
    },
    {
      label: 'Unique Paper Companies',
      value: stats.uniquePaperCompanies,
      hint: 'Active paper companies',
      highlight: stats.uniquePaperCompanies > 0,
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

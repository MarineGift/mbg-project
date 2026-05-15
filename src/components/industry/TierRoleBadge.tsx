// src/components/industry/TierRoleBadge.tsx
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

type TierRole = 'HQ' | 'Regional' | 'Country' | 'Plant'

const tierStyles: Record<TierRole, string> = {
  HQ:       'bg-purple-100 text-purple-900 border-purple-200',
  Regional: 'bg-blue-100   text-blue-900   border-blue-200',
  Country:  'bg-green-100  text-green-900  border-green-200',
  Plant:    'bg-amber-100  text-amber-900  border-amber-200',
}

export function TierRoleBadge({ tier }: { tier: TierRole | null }) {
  if (!tier) return <span className="text-xs text-muted-foreground">—</span>
  return (
    <Badge variant="outline" className={cn('font-mono text-xs', tierStyles[tier])}>
      {tier}
    </Badge>
  )
}
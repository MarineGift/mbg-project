// src/components/industry/EvidenceBadge.tsx
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export function EvidenceBadge({ level }: { level: string | null }) {
  if (!level) return <span className="text-xs text-muted-foreground">—</span>
  const styles: Record<string, string> = {
    A: 'bg-emerald-100 text-emerald-900',
    B: 'bg-lime-100    text-lime-900',
    C: 'bg-yellow-100  text-yellow-900',
    D: 'bg-orange-100  text-orange-900',
    E: 'bg-rose-100    text-rose-900',
  }
  return (
    <Badge variant="outline" className={cn('font-mono text-xs', styles[level] ?? '')}>
      {level}
    </Badge>
  )
}
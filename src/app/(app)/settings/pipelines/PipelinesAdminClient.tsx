// src/app/(app)/settings/pipelines/PipelinesAdminClient.tsx
// v5.9 Step C-3: Main admin UI with module cards + stage tables
'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Plus, Edit, Trash2, ChevronUp, ChevronDown } from 'lucide-react'
import { StageFormDialog } from './StageFormDialog'
import { deleteStage, moveStageUp, moveStageDown } from '@/lib/actions/pipeline-stages'

export type Stage = {
  id: string
  pipeline_id: string
  code: string
  name: string
  description: string | null
  sort_order: number
  default_probability_pct: number
  is_terminal: boolean
  is_won: boolean
  is_lost: boolean
  color_hex: string | null
}

export type Definition = {
  id: string
  organization_id: string
  module: string
  name: string
  description: string | null
  is_default: boolean
  is_active: boolean
}

export type PartyTypeGroup = {
  definition: Definition
  stages: Stage[]
}

// 사이드바 라벨과 일치 (영어 기본)
const PARTY_TYPE_NAMES: Record<string, string> = {
  investor: 'Investors',
  paper_mill: 'Paper Mills',
  partner: 'Partners',
  customer: 'Customers',
  filler_supplier: 'Filler Suppliers',
}

function partyTypeDisplayName(module: string): string {
  return PARTY_TYPE_NAMES[module] || module
}

export function PipelinesAdminClient({ partyTypeGroups }: { partyTypeGroups: PartyTypeGroup[] }) {
  const [editing, setEditing] = useState<
    | { stage: Stage | null; definitionId: string; nextSortOrder: number }
    | null
  >(null)
  const [isPending, startTransition] = useTransition()

  const handleDelete = (stageId: string, stageName: string) => {
    if (!confirm(`Delete stage "${stageName}"?\nThis cannot be undone.`)) return
    startTransition(async () => {
      const result = await deleteStage(stageId)
      if (result?.error) alert(`Delete failed: ${result.error}`)
    })
  }

  const handleMoveUp = (stageId: string) => {
    startTransition(async () => {
      await moveStageUp(stageId)
    })
  }

  const handleMoveDown = (stageId: string) => {
    startTransition(async () => {
      await moveStageDown(stageId)
    })
  }

  return (
    <div className="space-y-6">
      {partyTypeGroups.length === 0 && (
        <div className="rounded-md border p-8 text-center text-sm text-muted-foreground">
          No pipeline definitions found. Pipeline definitions are created automatically per module.
        </div>
      )}

      {partyTypeGroups.map((group) => {
        // 다음 stage의 sort_order 계산 (마지막 + 10)
        const lastSort =
          group.stages.length > 0 ? group.stages[group.stages.length - 1]!.sort_order : 0
        const nextSortOrder = lastSort + 10

        return (
          <Card key={group.definition.id}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg flex items-center gap-2">
                    {partyTypeDisplayName(group.definition.module)}
                    <Badge variant="outline" className="text-xs font-mono">
                      {group.definition.module}
                    </Badge>
                    {!group.definition.is_active && (
                      <Badge variant="destructive" className="text-xs">inactive</Badge>
                    )}
                  </CardTitle>
                  <p className="text-sm text-muted-foreground mt-1">
                    {group.definition.name}
                    {group.definition.description && (
                      <span className="ml-2 text-xs">· {group.definition.description}</span>
                    )}
                  </p>
                </div>
                <Button
                  size="sm"
                  onClick={() =>
                    setEditing({
                      stage: null,
                      definitionId: group.definition.id,
                      nextSortOrder,
                    })
                  }
                  disabled={isPending}
                >
                  <Plus className="h-4 w-4 mr-1" />
                  Add Stage
                </Button>
              </div>
            </CardHeader>

            <CardContent>
              {group.stages.length === 0 ? (
                <div className="rounded-md border p-6 text-center text-sm text-muted-foreground">
                  No stages defined. Click "Add Stage" to create the first one.
                </div>
              ) : (
                <div className="rounded-md border overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="w-12 text-center">Step</TableHead>
                        <TableHead>Name</TableHead>
                        <TableHead className="w-28">Code</TableHead>
                                <TableHead className="w-20 text-center">Prob %</TableHead>
                        <TableHead className="w-20">Color</TableHead>
                        <TableHead className="w-28">Status</TableHead>
                        <TableHead className="w-32 text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {group.stages.map((stage, idx) => (
                        <TableRow key={stage.id}>
                          <TableCell className="text-center text-muted-foreground font-mono text-xs">
                            {stage.sort_order}
                          </TableCell>
                          <TableCell className="font-medium">{stage.name}</TableCell>
                          <TableCell>
                            <code className="text-xs text-muted-foreground">{stage.code}</code>
                          </TableCell>

                          <TableCell className="text-center">
                            {stage.default_probability_pct}%
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1.5">
                              <div
                                className="w-4 h-4 rounded border border-gray-300"
                                style={{ backgroundColor: stage.color_hex ?? '#ccc' }}
                                title={stage.color_hex ?? ''}
                              />
                              <code className="text-[10px] text-muted-foreground">
                                {stage.color_hex ?? '—'}
                              </code>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-wrap gap-1">
                              {stage.is_won && (
                                <Badge className="text-[10px] bg-green-500 hover:bg-green-600">
                                  Won
                                </Badge>
                              )}
                              {stage.is_lost && (
                                <Badge variant="destructive" className="text-[10px]">
                                  Lost
                                </Badge>
                              )}
                              {stage.is_terminal && !stage.is_won && !stage.is_lost && (
                                <Badge variant="outline" className="text-[10px]">
                                  Terminal
                                </Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-0.5">
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-7 w-7"
                                disabled={idx === 0 || isPending}
                                onClick={() => handleMoveUp(stage.id)}
                                title="Move up"
                              >
                                <ChevronUp className="h-3.5 w-3.5" />
                              </Button>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-7 w-7"
                                disabled={idx === group.stages.length - 1 || isPending}
                                onClick={() => handleMoveDown(stage.id)}
                                title="Move down"
                              >
                                <ChevronDown className="h-3.5 w-3.5" />
                              </Button>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-7 w-7"
                                disabled={isPending}
                                onClick={() =>
                                  setEditing({
                                    stage,
                                    definitionId: group.definition.id,
                                    nextSortOrder: stage.sort_order,
                                  })
                                }
                                title="Edit"
                              >
                                <Edit className="h-3.5 w-3.5" />
                              </Button>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-7 w-7 text-destructive hover:text-destructive"
                                disabled={isPending}
                                onClick={() => handleDelete(stage.id, stage.name)}
                                title="Delete"
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        )
      })}

      {editing && (
        <StageFormDialog
          stage={editing.stage}
          definitionId={editing.definitionId}
          defaultSortOrder={editing.nextSortOrder}
          onClose={() => setEditing(null)}
        />
      )}
    </div>
  )
}

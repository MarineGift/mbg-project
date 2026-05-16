// src/app/(app)/settings/pipelines/StageFormDialog.tsx
// v5.9 Step C-3: Modal for create / edit stage
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { createStage, updateStage } from '@/lib/actions/pipeline-stages'
import type { Stage } from './PipelinesAdminClient'

const STAGE_TYPES = ['lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost']

// 일반적인 색상 팔레트 (klein 클릭 가능)
const COLOR_PRESETS = [
  '#6B7280', // gray
  '#3B82F6', // blue
  '#0EA5E9', // sky
  '#06B6D4', // cyan
  '#14B8A6', // teal
  '#10B981', // emerald
  '#22C55E', // green
  '#84CC16', // lime
  '#EAB308', // yellow
  '#F59E0B', // amber
  '#EF4444', // red
  '#EC4899', // pink
  '#8B5CF6', // violet
  '#A855F7', // purple
]

export function StageFormDialog({
  stage,
  definitionId,
  defaultSortOrder,
  onClose,
}: {
  stage: Stage | null
  definitionId: string
  defaultSortOrder: number
  onClose: () => void
}) {
  const isEditing = stage !== null
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    code: stage?.code ?? '',
    name: stage?.name ?? '',
    description: stage?.description ?? '',
    stage_type: stage?.stage_type ?? 'lead',
    sort_order: stage?.sort_order ?? defaultSortOrder,
    default_probability_pct: stage?.default_probability_pct ?? 50,
    is_terminal: stage?.is_terminal ?? false,
    is_won: stage?.is_won ?? false,
    is_lost: stage?.is_lost ?? false,
    color_hex: stage?.color_hex ?? '#3B82F6',
  })

  // is_won 또는 is_lost를 체크하면 is_terminal도 자동 true
  const handleWonChange = (checked: boolean) => {
    setFormData({
      ...formData,
      is_won: checked,
      is_lost: checked ? false : formData.is_lost,
      is_terminal: checked ? true : formData.is_terminal,
    })
  }

  const handleLostChange = (checked: boolean) => {
    setFormData({
      ...formData,
      is_lost: checked,
      is_won: checked ? false : formData.is_won,
      is_terminal: checked ? true : formData.is_terminal,
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)

    try {
      const result = isEditing
        ? await updateStage(stage!.id, formData)
        : await createStage({ pipeline_definition_id: definitionId, ...formData })

      if (result?.error) {
        setError(result.error)
      } else {
        onClose()
      }
    } catch (err) {
      setError((err as Error).message || 'Unknown error')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    // Backdrop
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={(e) => {
        if (e.target === e.currentTarget && !submitting) onClose()
      }}
    >
      {/* Dialog */}
      <div className="bg-background rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 space-y-4">
          {/* Header */}
          <div>
            <h2 className="text-xl font-bold">
              {isEditing ? 'Edit Stage' : 'New Stage'}
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              {isEditing
                ? 'Update stage properties'
                : 'Add a new stage to this pipeline'}
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md border border-destructive bg-destructive/10 p-2 text-sm text-destructive">
                {error}
              </div>
            )}

            {/* Name + Code */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium" htmlFor="name">Name *</label>
                <Input
                  id="name"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Contact"
                />
              </div>
              <div>
                <label className="text-sm font-medium" htmlFor="code">Code *</label>
                <Input
                  id="code"
                  required
                  pattern="[a-z0-9_]+"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  placeholder="contact"
                  title="Lowercase letters, numbers, underscore only"
                />
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="text-sm font-medium" htmlFor="description">Description</label>
              <Input
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Initial outreach to potential supplier"
              />
            </div>

            {/* Type / Step / Prob% */}
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="text-sm font-medium">Type *</label>
                <select
                  value={formData.stage_type}
                  onChange={(e) => setFormData({ ...formData, stage_type: e.target.value })}
                  className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                >
                  {STAGE_TYPES.map((t) => (
                    <option key={t} value={t}>{t}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium" htmlFor="sort_order">Step *</label>
                <Input
                  id="sort_order"
                  type="number"
                  required
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData({ ...formData, sort_order: Number(e.target.value) })
                  }
                />
              </div>
              <div>
                <label className="text-sm font-medium" htmlFor="prob">Prob %</label>
                <Input
                  id="prob"
                  type="number"
                  min={0}
                  max={100}
                  value={formData.default_probability_pct}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      default_probability_pct: Number(e.target.value),
                    })
                  }
                />
              </div>
            </div>

            {/* Color */}
            <div>
              <label className="text-sm font-medium">Color</label>
              <div className="flex items-center gap-2">
                <input
                  type="color"
                  value={formData.color_hex}
                  onChange={(e) => setFormData({ ...formData, color_hex: e.target.value })}
                  className="w-16 h-10 rounded border border-input cursor-pointer"
                />
                <Input
                  value={formData.color_hex}
                  onChange={(e) => setFormData({ ...formData, color_hex: e.target.value })}
                  className="flex-1 font-mono"
                  placeholder="#3B82F6"
                />
              </div>
              <div className="flex flex-wrap gap-1 mt-2">
                {COLOR_PRESETS.map((c) => (
                  <button
                    key={c}
                    type="button"
                    onClick={() => setFormData({ ...formData, color_hex: c })}
                    className="w-6 h-6 rounded border border-gray-300 hover:scale-110 transition"
                    style={{ backgroundColor: c }}
                    title={c}
                  />
                ))}
              </div>
            </div>

            {/* Flags */}
            <div className="space-y-2 border-t pt-3">
              <label className="text-sm font-medium block">Flags</label>
              <div className="grid grid-cols-3 gap-3">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.is_terminal}
                    onChange={(e) =>
                      setFormData({ ...formData, is_terminal: e.target.checked })
                    }
                    className="rounded"
                  />
                  <span className="text-sm">Terminal</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.is_won}
                    onChange={(e) => handleWonChange(e.target.checked)}
                    className="rounded"
                  />
                  <span className="text-sm">Won</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.is_lost}
                    onChange={(e) => handleLostChange(e.target.checked)}
                    className="rounded"
                  />
                  <span className="text-sm">Lost</span>
                </label>
              </div>
              <p className="text-xs text-muted-foreground">
                Terminal = no further stages. Won/Lost auto-set Terminal.
              </p>
            </div>

            {/* Footer */}
            <div className="flex justify-end gap-2 pt-3 border-t">
              <Button
                type="button"
                variant="outline"
                onClick={onClose}
                disabled={submitting}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={submitting}>
                {submitting ? 'Saving...' : isEditing ? 'Update' : 'Create'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

'use client'
// src/components/calendar/email-attendees-modal.tsx
// Phase 3 - email the attendees of a calendar event.
// Reuses the verified outbound pipeline (sendOutboundManual -> sendOutboundEmail)
// via sendEventEmailAction. The To field is prefilled from item.attendees and
// the body from the event details; everything stays editable before send.
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import type { CalendarItem } from '@/lib/queries/calendar'
import { sendEventEmailAction } from '@/app/actions/calendar'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Button }   from '@/components/ui/button'
import { Input }    from '@/components/ui/input'
import { Label }    from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { AlertTriangle, Mail, CheckCircle2 } from 'lucide-react'

function buildBody(item: CalendarItem): string {
  const start = new Date(item.start_at)
  const end   = new Date(item.end_at)
  const lines: string[] = []
  lines.push(`You are invited to: ${item.title}`)
  lines.push('')
  if (item.is_all_day) {
    lines.push(`When: ${start.toLocaleDateString('en-US')} (all day)`)
  } else {
    const endStr = end.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
    lines.push(`When: ${start.toLocaleString('en-US')} - ${endStr}`)
  }
  if (item.location)    lines.push(`Where: ${item.location}`)
  if (item.meeting_url) lines.push(`Link: ${item.meeting_url}`)
  if (item.description) { lines.push(''); lines.push(item.description) }
  return lines.join('\n')
}

export function EmailAttendeesModal({
  item, onClose,
}: { item: CalendarItem | null; onClose: () => void }) {
  const router = useRouter()
  const [to,      setTo]      = useState('')
  const [cc,      setCc]      = useState('')
  const [subject, setSubject] = useState('')
  const [body,    setBody]    = useState('')
  const [sending, setSending] = useState(false)
  const [error,   setError]   = useState<string | null>(null)
  const [sentOk,  setSentOk]  = useState(false)

  useEffect(() => {
    if (!item) return
    const emails = (item.attendees ?? [])
      .map(a => a.email)
      .filter(Boolean)
    setTo(emails.join(', '))
    setCc('')
    setSubject(item.title ? `Invitation: ${item.title}` : 'Invitation')
    setBody(buildBody(item))
    setError(null)
    setSentOk(false)
  }, [item])

  if (!item) return null

  const canSend = !!to.trim() && !!subject.trim() && !!body.trim()

  async function handleSend() {
    if (!item || !canSend) return
    setSending(true)
    setError(null)
    try {
      const res = await sendEventEmailAction({
        to:        to.trim(),
        cc:        cc.trim() || undefined,
        subject:   subject.trim(),
        bodyPlain: body,
        partyId:   item.party_id ?? null,
      })
      if (res.ok) {
        setSentOk(true)
        router.refresh()
        setTimeout(() => { onClose() }, 900)
      } else {
        const map: Record<string, string> = {
          not_whitelisted: 'A recipient is not whitelisted. Add them to the email whitelist and try again.',
          unauthorized:    'Your session expired. Please sign in again.',
          validation:      'Please check the recipient address and required fields.',
          no_sending_email:'No sending email is configured for your account.',
          send_failed:     'The email failed to send. Please try again.',
          database:        'Could not record the message. Please try again.',
          not_found:       'Related record not found.',
        }
        setError(res.errorMessage || map[res.errorCode ?? ''] || 'Failed to send email')
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to send email')
    } finally {
      setSending(false)
    }
  }

  return (
    <Dialog open={!!item} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Mail className="w-4 h-4" /> Email attendees
          </DialogTitle>
        </DialogHeader>

        {sentOk ? (
          <div className="flex items-center gap-2 rounded-md border border-emerald-300 bg-emerald-50 px-3 py-3 text-sm text-emerald-800">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>Email sent.</span>
          </div>
        ) : (
          <>
            <div className="space-y-3 py-1">
              <div className="space-y-1">
                <Label>To (comma-separated)</Label>
                <Input
                  placeholder="a@example.com, b@example.com"
                  value={to}
                  onChange={e => setTo(e.target.value)}
                />
              </div>

              <div className="space-y-1">
                <Label>Cc (optional)</Label>
                <Input
                  placeholder="c@example.com"
                  value={cc}
                  onChange={e => setCc(e.target.value)}
                />
              </div>

              <div className="space-y-1">
                <Label>Subject</Label>
                <Input value={subject} onChange={e => setSubject(e.target.value)} />
              </div>

              <div className="space-y-1">
                <Label>Message</Label>
                <Textarea rows={8} value={body} onChange={e => setBody(e.target.value)} />
              </div>

              {error && (
                <div className="flex gap-2 rounded-md border border-red-300 bg-red-50 px-3 py-2 text-xs text-red-700">
                  <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{error}</span>
                </div>
              )}
            </div>

            <div className="flex items-center justify-end gap-2 pt-1">
              <Button variant="outline" size="sm" onClick={onClose} disabled={sending}>
                Cancel
              </Button>
              <Button
                size="sm"
                className="bg-blue-600 hover:bg-blue-700 text-white"
                onClick={handleSend}
                disabled={sending || !canSend}
              >
                {sending ? 'Sending...' : 'Send'}
              </Button>
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  )
}

'use client';

/**
 * PartyMindmap — a balanced "mind map" view centered on a single party.
 * Center node = the party (+ status badges). Branches (cards) fan out left/right:
 * Contacts, Deals, Activity, Investor focus, Location, Status. Each branch lists
 * its leaves (the actual connected records / figures) and can be collapsed.
 *
 * Pure presentational client component: it receives an already-assembled, plain
 * data object (see MindmapData) so there is no data fetching here.
 */

import { useMemo, useState, type ReactNode } from 'react';
import {
  Users, Handshake, Activity, Target, MapPin, Gauge, Building2,
  type LucideIcon,
} from 'lucide-react';

export interface MindLeaf {
  label: string;
  sub?: string | null;
}
export interface MindmapData {
  id: string;
  name: string;
  partyType: string;
  tier: string | null;
  status: string | null;
  priority: 'high' | 'medium' | 'low' | null;
  country: string | null;
  region: string | null;
  city: string | null;
  website: string | null;
  source: string | null;
  counts: {
    contacts: number;
    communications: number;
    pendingDrafts: number;
    openEngagements: number;
    openTasks: number;
  };
  contacts: MindLeaf[];
  engagements: MindLeaf[];
  activity: MindLeaf[];
  investorFocus: MindLeaf[];
}

type Tone = 'sky' | 'violet' | 'amber' | 'emerald' | 'rose' | 'slate';
interface Branch {
  key: string;
  label: string;
  icon: LucideIcon;
  tone: Tone;
  count?: number;
  leaves: MindLeaf[];
}

const TONE: Record<Tone, { dot: string; head: string; ring: string }> = {
  sky:     { dot: '#0ea5e9', head: 'bg-sky-50 dark:bg-sky-950/40',         ring: 'border-sky-200 dark:border-sky-900' },
  violet:  { dot: '#8b5cf6', head: 'bg-violet-50 dark:bg-violet-950/40',   ring: 'border-violet-200 dark:border-violet-900' },
  amber:   { dot: '#f59e0b', head: 'bg-amber-50 dark:bg-amber-950/40',     ring: 'border-amber-200 dark:border-amber-900' },
  emerald: { dot: '#10b981', head: 'bg-emerald-50 dark:bg-emerald-950/40', ring: 'border-emerald-200 dark:border-emerald-900' },
  rose:    { dot: '#f43f5e', head: 'bg-rose-50 dark:bg-rose-950/40',       ring: 'border-rose-200 dark:border-rose-900' },
  slate:   { dot: '#64748b', head: 'bg-slate-50 dark:bg-slate-900/40',     ring: 'border-slate-200 dark:border-slate-800' },
};

// Layout constants (px)
const PAD = 28;
const CENTER_W = 220;
const CENTER_H = 104;
const CARD_W = 256;
const COL_GAP = 110;
const HEAD_H = 46;
const LEAF_H = 30;
const LIST_PAD = 12;
const V_GAP = 22;

function fmtPriority(p: string | null) {
  return p ? p.charAt(0).toUpperCase() + p.slice(1) : null;
}

export function PartyMindmap({ data }: { data: MindmapData }) {
  const branches = useMemo<Branch[]>(() => {
    const list: Branch[] = [];
    if (data.counts.contacts > 0 || data.contacts.length > 0) {
      list.push({ key: 'contacts', label: 'Contacts', icon: Users, tone: 'sky', count: data.counts.contacts, leaves: data.contacts });
    }
    if (data.counts.openEngagements > 0 || data.engagements.length > 0) {
      list.push({ key: 'deals', label: 'Deals & Engagements', icon: Handshake, tone: 'violet', count: data.engagements.length, leaves: data.engagements });
    }
    {
      const actLeaves: MindLeaf[] = [
        { label: `${data.counts.communications} communications`, sub: data.counts.pendingDrafts > 0 ? `${data.counts.pendingDrafts} pending AI drafts` : null },
        ...data.activity,
      ];
      list.push({ key: 'activity', label: 'Activity', icon: Activity, tone: 'amber', count: data.counts.communications, leaves: actLeaves });
    }
    if (data.partyType === 'investor' && data.investorFocus.length > 0) {
      list.push({ key: 'focus', label: 'Investor focus', icon: Target, tone: 'emerald', leaves: data.investorFocus });
    }
    {
      const loc: MindLeaf[] = [];
      const place = [data.city, data.region, data.country].filter(Boolean).join(', ');
      if (place) loc.push({ label: place });
      if (data.website) loc.push({ label: 'Website', sub: data.website.replace(/^https?:\/\//, '') });
      if (loc.length) list.push({ key: 'location', label: 'Location', icon: MapPin, tone: 'rose', leaves: loc });
    }
    {
      const st: MindLeaf[] = [];
      if (data.tier) st.push({ label: 'Tier', sub: data.tier });
      if (data.status) st.push({ label: 'Status', sub: data.status });
      if (data.partyType === 'investor' && data.priority) st.push({ label: 'Priority', sub: fmtPriority(data.priority) });
      st.push({ label: 'Open tasks', sub: String(data.counts.openTasks) });
      st.push({ label: 'Open engagements', sub: String(data.counts.openEngagements) });
      if (data.source) st.push({ label: 'Source', sub: data.source });
      list.push({ key: 'status', label: 'Status', icon: Gauge, tone: 'slate', leaves: st });
    }
    return list;
  }, [data]);

  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const toggle = (k: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(k)) next.delete(k);
      else next.add(k);
      return next;
    });

  // Split branches left/right (alternate for balance).
  const right: Branch[] = [];
  const left: Branch[] = [];
  branches.forEach((b, i) => (i % 2 === 0 ? right : left).push(b));

  const cardHeight = (b: Branch) =>
    HEAD_H + (collapsed.has(b.key) ? 0 : b.leaves.length * LEAF_H + LIST_PAD);

  const sideHeight = (side: Branch[]) =>
    side.reduce((acc, b) => acc + cardHeight(b), 0) + Math.max(0, side.length - 1) * V_GAP;

  const hR = sideHeight(right);
  const hL = sideHeight(left);
  const innerH = Math.max(hR, hL, CENTER_H);
  const height = innerH + PAD * 2;
  const width = CENTER_W + 2 * (COL_GAP + CARD_W) + PAD * 2;
  const centerX = width / 2;
  const centerY = height / 2;

  // Compute absolute positions for each card + connector endpoints.
  type Placed = { b: Branch; x: number; y: number; h: number; side: 'L' | 'R' };
  const placed: Placed[] = [];
  const layoutSide = (side: Branch[], which: 'L' | 'R') => {
    const total = sideHeight(side);
    let y = PAD + (innerH - total) / 2;
    for (const b of side) {
      const h = cardHeight(b);
      const x = which === 'R' ? centerX + CENTER_W / 2 + COL_GAP : centerX - CENTER_W / 2 - COL_GAP - CARD_W;
      placed.push({ b, x, y, h, side: which });
      y += h + V_GAP;
    }
  };
  layoutSide(right, 'R');
  layoutSide(left, 'L');

  const connector = (p: Placed) => {
    const sx = p.side === 'R' ? centerX + CENTER_W / 2 : centerX - CENTER_W / 2;
    const sy = centerY;
    const ex = p.side === 'R' ? p.x : p.x + CARD_W;
    const ey = p.y + HEAD_H / 2;
    const mx = (sx + ex) / 2;
    return `M ${sx} ${sy} C ${mx} ${sy}, ${mx} ${ey}, ${ex} ${ey}`;
  };

  return (
    <div className="w-full overflow-x-auto">
      <div className="relative mx-auto" style={{ width, height, minWidth: width }}>
        {/* connectors */}
        <svg className="absolute inset-0" width={width} height={height} style={{ pointerEvents: 'none' }}>
          {placed.map((p) => (
            <path
              key={p.b.key}
              d={connector(p)}
              fill="none"
              stroke={TONE[p.b.tone].dot}
              strokeWidth={2}
              strokeOpacity={0.5}
            />
          ))}
        </svg>

        {/* center node */}
        <div
          className="absolute rounded-2xl border bg-card shadow-sm flex flex-col items-center justify-center text-center px-4"
          style={{ left: centerX - CENTER_W / 2, top: centerY - CENTER_H / 2, width: CENTER_W, height: CENTER_H }}
        >
          <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
            <Building2 className="h-3.5 w-3.5" />
            {data.partyType.replace('_', ' ')}
          </div>
          <div className="font-semibold leading-tight mt-1 line-clamp-2">{data.name}</div>
          <div className="mt-1.5 flex flex-wrap items-center justify-center gap-1">
            {data.tier && <Badge>{data.tier}</Badge>}
            {data.partyType === 'investor' && data.priority && (
              <Badge tone={data.priority === 'high' ? 'emerald' : data.priority === 'low' ? 'slate' : 'amber'}>
                {fmtPriority(data.priority)}
              </Badge>
            )}
            {data.country && <Badge tone="slate">{data.country}</Badge>}
          </div>
        </div>

        {/* branch cards */}
        {placed.map((p) => {
          const Icon = p.b.icon;
          const isCollapsed = collapsed.has(p.b.key);
          const t = TONE[p.b.tone];
          return (
            <div
              key={p.b.key}
              className={`absolute rounded-xl border ${t.ring} bg-card shadow-sm overflow-hidden`}
              style={{ left: p.x, top: p.y, width: CARD_W }}
            >
              <button
                type="button"
                onClick={() => toggle(p.b.key)}
                className={`w-full flex items-center gap-2 px-3 ${t.head} text-left`}
                style={{ height: HEAD_H }}
              >
                <span className="grid h-6 w-6 place-items-center rounded-md" style={{ background: t.dot + '22' }}>
                  <Icon className="h-3.5 w-3.5" style={{ color: t.dot }} />
                </span>
                <span className="text-sm font-medium flex-1">{p.b.label}</span>
                {typeof p.b.count === 'number' && (
                  <span className="text-xs tabular-nums text-muted-foreground font-mono">{p.b.count}</span>
                )}
                <span className="text-muted-foreground text-xs">{isCollapsed ? '+' : '\u2212'}</span>
              </button>
              {!isCollapsed && (
                <ul className="py-1.5">
                  {p.b.leaves.map((lf, i) => (
                    <li
                      key={i}
                      className="flex items-center gap-2 px-3 text-sm"
                      style={{ height: LEAF_H }}
                    >
                      <span className="h-1.5 w-1.5 rounded-full shrink-0" style={{ background: t.dot }} />
                      <span className="truncate">{lf.label}</span>
                      {lf.sub && (
                        <span className="ml-auto truncate text-xs text-muted-foreground max-w-[45%] text-right">{lf.sub}</span>
                      )}
                    </li>
                  ))}
                  {p.b.leaves.length === 0 && (
                    <li className="px-3 text-xs text-muted-foreground" style={{ height: LEAF_H, lineHeight: `${LEAF_H}px` }}>
                      None
                    </li>
                  )}
                </ul>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

function Badge({ children, tone = 'sky' }: { children: ReactNode; tone?: Tone }) {
  const t = TONE[tone];
  return (
    <span
      className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium"
      style={{ background: t.dot + '1f', color: t.dot }}
    >
      {children}
    </span>
  );
}

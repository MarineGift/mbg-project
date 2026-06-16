'use client';

/**
 * PartyMindmap — a balanced "mind map" centered on one party.
 * Center node = the party. Branch cards fan out left/right and each branch can
 * contain multiple levels: a row may expand into child rows (e.g. a Contact ->
 * email / phone as clickable links). Connectors are measured from the live DOM
 * so cards can grow/shrink (expand, wrap) without breaking the layout.
 *
 * Presentational client component: receives an assembled plain data object.
 */

import {
  useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState,
  type ReactNode,
} from 'react';
import {
  Users, Handshake, Activity, Target, MapPin, Gauge, Building2,
  FileText, StickyNote, ChevronRight,
  type LucideIcon,
} from 'lucide-react';

export interface MindLeaf {
  label: string;
  sub?: string | null;
  href?: string | null;      // makes the label a link (mailto:/tel:/http)
  wrap?: boolean;            // render full text (wrapped) instead of truncated
  children?: MindLeaf[];     // second+ level — revealed on click
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
  introKo: string | null;
  introEn: string | null;
  notes: string | null;
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

type Tone = 'sky' | 'violet' | 'amber' | 'emerald' | 'rose' | 'slate' | 'indigo' | 'teal';
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
  indigo:  { dot: '#6366f1', head: 'bg-indigo-50 dark:bg-indigo-950/40',   ring: 'border-indigo-200 dark:border-indigo-900' },
  teal:    { dot: '#14b8a6', head: 'bg-teal-50 dark:bg-teal-950/40',       ring: 'border-teal-200 dark:border-teal-900' },
};

const CARD_W = 264;
const COL_GAP = 120;

function fmtPriority(p: string | null) {
  return p ? p.charAt(0).toUpperCase() + p.slice(1) : null;
}
function preview(s: string, n = 42) {
  const t = s.replace(/\s+/g, ' ').trim();
  return t.length > n ? t.slice(0, n) + '\u2026' : t;
}

export function PartyMindmap({ data }: { data: MindmapData }) {
  const branches = useMemo<Branch[]>(() => {
    const list: Branch[] = [];
    if (data.contacts.length > 0) {
      list.push({ key: 'contacts', label: 'Contacts', icon: Users, tone: 'sky', count: data.counts.contacts, leaves: data.contacts });
    }
    if (data.engagements.length > 0) {
      list.push({ key: 'deals', label: 'Deals & Engagements', icon: Handshake, tone: 'violet', count: data.engagements.length, leaves: data.engagements });
    }
    {
      const actLeaves: MindLeaf[] = [
        { label: `${data.counts.communications} communications`, sub: data.counts.pendingDrafts > 0 ? `${data.counts.pendingDrafts} pending` : null },
        ...data.activity,
      ];
      list.push({ key: 'activity', label: 'Activity', icon: Activity, tone: 'amber', count: data.counts.communications, leaves: actLeaves });
    }
    if (data.partyType === 'investor' && data.investorFocus.length > 0) {
      list.push({ key: 'focus', label: 'Investor focus', icon: Target, tone: 'emerald', leaves: data.investorFocus });
    }
    if (data.introKo || data.introEn) {
      const lv: MindLeaf[] = [];
      if (data.introKo) lv.push({ label: 'Korean', sub: preview(data.introKo), children: [{ label: data.introKo, wrap: true }] });
      if (data.introEn) lv.push({ label: 'English', sub: preview(data.introEn), children: [{ label: data.introEn, wrap: true }] });
      list.push({ key: 'introduction', label: 'Introduction', icon: FileText, tone: 'indigo', leaves: lv });
    }
    if (data.notes && data.notes.trim()) {
      list.push({ key: 'notes', label: 'Notes', icon: StickyNote, tone: 'teal',
        leaves: [{ label: 'Notes', sub: preview(data.notes), children: [{ label: data.notes, wrap: true }] }] });
    }
    {
      const loc: MindLeaf[] = [];
      const place = [data.city, data.region, data.country].filter(Boolean).join(', ');
      if (place) loc.push({ label: place });
      if (data.website) loc.push({ label: data.website.replace(/^https?:\/\//, ''), sub: 'website', href: data.website });
      if (loc.length) list.push({ key: 'location', label: 'Location', icon: MapPin, tone: 'rose', leaves: loc });
    }
    {
      const st: MindLeaf[] = [];
      if (data.status) st.push({ label: 'Status', sub: data.status });
      if (data.partyType === 'investor' && data.priority) st.push({ label: 'Priority', sub: fmtPriority(data.priority) });
      if (data.tier) st.push({ label: 'Tier', sub: data.tier });
      st.push({ label: 'Open tasks', sub: String(data.counts.openTasks) });
      st.push({ label: 'Open engagements', sub: String(data.counts.openEngagements) });
      if (data.source) st.push({ label: 'Source', sub: data.source });
      list.push({ key: 'status', label: 'Status', icon: Gauge, tone: 'slate', leaves: st });
    }
    return list;
  }, [data]);

  // collapse whole branch; expand individual rows (multi-level)
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const toggleSet = (set: Set<string>, setter: (s: Set<string>) => void, k: string) => {
    const next = new Set(set);
    if (next.has(k)) next.delete(k); else next.add(k);
    setter(next);
  };

  const right: Branch[] = [];
  const left: Branch[] = [];
  branches.forEach((b, i) => (i % 2 === 0 ? right : left).push(b));

  // ---- measured connectors ----
  const containerRef = useRef<HTMLDivElement>(null);
  const centerRef = useRef<HTMLDivElement>(null);
  const headerRefs = useRef<Map<string, HTMLElement>>(new Map());
  const setHeaderRef = (key: string) => (el: HTMLElement | null) => {
    if (el) headerRefs.current.set(key, el);
    else headerRefs.current.delete(key);
  };
  const [paths, setPaths] = useState<{ key: string; d: string; color: string }[]>([]);
  const [size, setSize] = useState({ w: 0, h: 0 });

  const recompute = useCallback(() => {
    const cont = containerRef.current, cen = centerRef.current;
    if (!cont || !cen) return;
    const cr = cont.getBoundingClientRect();
    const ce = cen.getBoundingClientRect();
    const cenY = ce.top - cr.top + ce.height / 2;
    const out: { key: string; d: string; color: string }[] = [];
    const add = (side: Branch[], which: 'L' | 'R') => {
      for (const b of side) {
        const el = headerRefs.current.get(b.key);
        if (!el) continue;
        const r = el.getBoundingClientRect();
        const ey = r.top - cr.top + r.height / 2;
        const sx = which === 'R' ? ce.right - cr.left : ce.left - cr.left;
        const ex = which === 'R' ? r.left - cr.left : r.right - cr.left;
        const mx = (sx + ex) / 2;
        out.push({ key: b.key, d: `M ${sx} ${cenY} C ${mx} ${cenY}, ${mx} ${ey}, ${ex} ${ey}`, color: TONE[b.tone].dot });
      }
    };
    add(right, 'R');
    add(left, 'L');
    setPaths(out);
    setSize({ w: cont.scrollWidth, h: cont.scrollHeight });
  }, [right, left]);

  useLayoutEffect(() => { recompute(); }, [recompute, collapsed, expanded]);
  useEffect(() => {
    const ro = new ResizeObserver(() => recompute());
    if (containerRef.current) ro.observe(containerRef.current);
    window.addEventListener('resize', recompute);
    const t = setTimeout(recompute, 50);
    return () => { ro.disconnect(); window.removeEventListener('resize', recompute); clearTimeout(t); };
  }, [recompute]);

  return (
    <div className="w-full overflow-x-auto">
      <div
        ref={containerRef}
        className="relative mx-auto flex items-stretch justify-center"
        style={{ gap: COL_GAP, minWidth: CARD_W * 2 + 220 + COL_GAP * 2 + 48, paddingBlock: 8 }}
      >
        <svg className="absolute inset-0 pointer-events-none" width={size.w} height={size.h}>
          {paths.map((p) => (
            <path key={p.key} d={p.d} fill="none" stroke={p.color} strokeWidth={2} strokeOpacity={0.5} />
          ))}
        </svg>

        {/* left column */}
        <div className="flex flex-col justify-center gap-5" style={{ width: CARD_W }}>
          {left.map((b) => (
            <BranchCard key={b.key} b={b} headerRef={setHeaderRef(b.key)}
              collapsed={collapsed} expanded={expanded}
              onCollapse={() => toggleSet(collapsed, setCollapsed, b.key)}
              onExpandRow={(k) => toggleSet(expanded, setExpanded, k)} />
          ))}
        </div>

        {/* center */}
        <div className="flex items-center">
          <div ref={centerRef}
            className="rounded-2xl border bg-card shadow-sm flex flex-col items-center justify-center text-center px-4 py-3"
            style={{ width: 220 }}>
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
        </div>

        {/* right column */}
        <div className="flex flex-col justify-center gap-5" style={{ width: CARD_W }}>
          {right.map((b) => (
            <BranchCard key={b.key} b={b} headerRef={setHeaderRef(b.key)}
              collapsed={collapsed} expanded={expanded}
              onCollapse={() => toggleSet(collapsed, setCollapsed, b.key)}
              onExpandRow={(k) => toggleSet(expanded, setExpanded, k)} />
          ))}
        </div>
      </div>
    </div>
  );
}

function BranchCard({
  b, headerRef, collapsed, expanded, onCollapse, onExpandRow,
}: {
  b: Branch;
  headerRef: (el: HTMLElement | null) => void;
  collapsed: Set<string>;
  expanded: Set<string>;
  onCollapse: () => void;
  onExpandRow: (k: string) => void;
}) {
  const Icon = b.icon;
  const t = TONE[b.tone];
  const isCollapsed = collapsed.has(b.key);
  return (
    <div className={`rounded-xl border ${t.ring} bg-card shadow-sm overflow-hidden`} style={{ width: CARD_W }}>
      <button ref={headerRef} type="button" onClick={onCollapse}
        className={`w-full flex items-center gap-2 px-3 py-2.5 ${t.head} text-left`}>
        <span className="grid h-6 w-6 place-items-center rounded-md" style={{ background: t.dot + '22' }}>
          <Icon className="h-3.5 w-3.5" style={{ color: t.dot }} />
        </span>
        <span className="text-sm font-medium flex-1">{b.label}</span>
        {typeof b.count === 'number' && (
          <span className="text-xs tabular-nums text-muted-foreground font-mono">{b.count}</span>
        )}
        <span className="text-muted-foreground text-xs w-3 text-center">{isCollapsed ? '+' : '\u2212'}</span>
      </button>
      {!isCollapsed && (
        <ul className="py-1.5">
          {b.leaves.map((lf, i) => (
            <LeafRow key={i} leaf={lf} pathKey={`${b.key}:${i}`} depth={0}
              tone={t.dot} expanded={expanded} onToggle={onExpandRow} />
          ))}
          {b.leaves.length === 0 && (
            <li className="px-3 py-1 text-xs text-muted-foreground">None</li>
          )}
        </ul>
      )}
    </div>
  );
}

function LeafRow({
  leaf, pathKey, depth, tone, expanded, onToggle,
}: {
  leaf: MindLeaf;
  pathKey: string;
  depth: number;
  tone: string;
  expanded: Set<string>;
  onToggle: (k: string) => void;
}) {
  const hasChildren = !!leaf.children?.length;
  const isOpen = expanded.has(pathKey);
  const labelEl = leaf.href ? (
    <a href={leaf.href} className="truncate hover:underline" onClick={(e) => e.stopPropagation()}>{leaf.label}</a>
  ) : leaf.wrap ? (
    <span className="whitespace-pre-wrap break-words text-xs text-muted-foreground leading-relaxed">{leaf.label}</span>
  ) : (
    <span className="truncate">{leaf.label}</span>
  );
  return (
    <li>
      <div
        className={`flex items-center gap-2 pr-3 text-sm ${hasChildren ? 'cursor-pointer hover:bg-muted/50' : ''} ${leaf.wrap ? 'py-1.5 items-start' : 'py-1'}`}
        style={{ paddingLeft: 12 + depth * 14 }}
        onClick={hasChildren ? () => onToggle(pathKey) : undefined}
      >
        {!leaf.wrap && <span className="h-1.5 w-1.5 rounded-full shrink-0" style={{ background: tone }} />}
        {labelEl}
        {leaf.sub && !leaf.wrap && (
          <span className="ml-auto truncate text-xs text-muted-foreground max-w-[45%] text-right">{leaf.sub}</span>
        )}
        {hasChildren && (
          <ChevronRight className={`h-3.5 w-3.5 shrink-0 text-muted-foreground transition-transform ${isOpen ? 'rotate-90' : ''} ${leaf.sub ? '' : 'ml-auto'}`} />
        )}
      </div>
      {hasChildren && isOpen && (
        <ul>
          {leaf.children!.map((ch, i) => (
            <LeafRow key={i} leaf={ch} pathKey={`${pathKey}.${i}`} depth={depth + 1}
              tone={tone} expanded={expanded} onToggle={onToggle} />
          ))}
        </ul>
      )}
    </li>
  );
}

function Badge({ children, tone = 'sky' }: { children: ReactNode; tone?: Tone }) {
  const t = TONE[tone];
  return (
    <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium"
      style={{ background: t.dot + '1f', color: t.dot }}>
      {children}
    </span>
  );
}

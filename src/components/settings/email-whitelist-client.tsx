// src/components/settings/email-whitelist-client.tsx
"use client";
import { useEffect, useState, useTransition } from "react";
import {
  Globe, Mail, Plus, Trash2, ToggleLeft, ToggleRight,
  Download, Loader2, CheckCircle2, AlertCircle, X, Check, Building2, ArrowRight,
  Search, ChevronLeft, ChevronRight,
} from "lucide-react";
import {
  addWhitelistEntry, bulkAddDomains,
  toggleWhitelistEntry, deleteWhitelistEntry,
  searchPartiesForWhitelist, registerAddressEntry,
} from "@/lib/actions/email-whitelist";
import type {
  WhitelistEntry, UnregisteredDomain, PartyOption, AddressAssignment,
} from "@/lib/actions/email-whitelist";

const FREE = new Set(["gmail.com","naver.com","yahoo.com","hotmail.com","outlook.com","icloud.com"]);

const CONTACT_TYPES: Array<{ id: number; label: string }> = [
  { id: 1, label: "Employee" },
  { id: 2, label: "Partner" },
  { id: 5, label: "Executive" },
  { id: 4, label: "Advisor" },
  { id: 3, label: "Consultant" },
];

export function EmailWhitelistClient({
  initialEntries,
  unregisteredDomains,
  initialAssignments,
}: {
  initialEntries: WhitelistEntry[];
  unregisteredDomains: UnregisteredDomain[];
  initialAssignments: Record<string, AddressAssignment>;
}) {
  const [entries, setEntries] = useState(initialEntries);
  const [assignments, setAssignments] = useState(initialAssignments);
  const [unregistered, setUnregistered] = useState(unregisteredDomains);
  const [showAdd, setShowAdd] = useState(false);
  const [assignFor, setAssignFor] = useState<string | null>(null); // email to (re)assign
  const [showImport, setShowImport] = useState(false);
  const [filter, setFilter] = useState("");
  const [isPending, start] = useTransition();
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  };

  const handleToggle = (id: string, cur: boolean) =>
    start(async () => {
      await toggleWhitelistEntry(id, !cur);
      setEntries(p => p.map(e => e.id === id ? { ...e, is_active: !cur } : e));
    });

  const handleDelete = (id: string, pattern: string) => {
    if (!confirm('Delete "' + pattern + '"?')) return;
    start(async () => {
      await deleteWhitelistEntry(id);
      setEntries(p => p.filter(e => e.id !== id));
      showToast('"' + pattern + '" deleted');
    });
  };

  const handleRegistered = (
    entry: WhitelistEntry | null,
    email: string,
    assignment: AddressAssignment,
    msg: string,
  ) => {
    if (entry && !entries.some(e => e.kind === "address" && e.pattern === email)) {
      setEntries(p => [...p, entry]);
    }
    setAssignments(p => ({ ...p, [email]: assignment }));
    setShowAdd(false);
    setAssignFor(null);
    showToast(msg);
  };

  const norm = filter.trim().toLowerCase();
  const match = (e: WhitelistEntry) => {
    if (!norm) return true;
    if (e.pattern.toLowerCase().includes(norm)) return true;
    if ((e.notes ?? "").toLowerCase().includes(norm)) return true;
    const a = assignments[e.pattern];
    if (a && (a.partyName.toLowerCase().includes(norm) || (a.fullName ?? "").toLowerCase().includes(norm))) return true;
    return false;
  };
  const domains = entries.filter(e => e.kind === "domain" && match(e));
  const addresses = entries.filter(e => e.kind === "address" && match(e));

  return (
    <div className="space-y-6">
      {toast && (
        <div className={["fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg shadow-lg text-white text-sm", toast.ok ? "bg-green-600" : "bg-red-600"].join(" ")}>
          {toast.ok ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
          {toast.msg}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold">Email Whitelist</h2>
          <p className="text-sm text-gray-500 mt-1">
            Emails from registered domains and addresses are automatically approved.
            Addresses can be pinned to a specific party for exact inbound routing.
          </p>
        </div>
        <div className="flex gap-2">
          {unregistered.length > 0 && (
            <button
              onClick={() => setShowImport(true)}
              className="inline-flex items-center gap-1.5 px-3 py-2 bg-emerald-600 text-white rounded-md text-sm hover:bg-emerald-700"
            >
              <Download className="w-4 h-4" />
              Import Party Domains ({unregistered.length})
            </button>
          )}
          <button
            onClick={() => { setAssignFor(null); setShowAdd(true); }}
            className="inline-flex items-center gap-1.5 px-3 py-2 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
          >
            <Plus className="w-4 h-4" /> Add
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <StatCard label="Total Registered" value={entries.length} />
        <StatCard label="Domains" value={domains.length} color="text-blue-600" />
        <StatCard label="Email Addresses" value={addresses.length} color="text-purple-600" />
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
        <input
          type="text"
          value={filter}
          onChange={e => setFilter(e.target.value)}
          placeholder="Search pattern, notes, or party..."
          className="w-full pl-9 pr-9 py-2 border rounded-md text-sm"
        />
        {filter && (
          <button onClick={() => setFilter("")} className="absolute right-3 top-2.5">
            <X className="w-4 h-4 text-gray-400 hover:text-gray-600" />
          </button>
        )}
      </div>

      {/* Add / Assign form */}
      {(showAdd || assignFor) && (
        <AddForm
          fixedEmail={assignFor ?? undefined}
          existingAssignment={assignFor ? assignments[assignFor] ?? null : null}
          onClose={() => { setShowAdd(false); setAssignFor(null); }}
          onDomainAdded={entry => {
            setEntries(p => [...p, entry]);
            setShowAdd(false);
            showToast('"' + entry.pattern + '" registered');
          }}
          onAddressRegistered={handleRegistered}
          onError={msg => showToast(msg, false)}
        />
      )}

      {/* Domain section */}
      <Section
        title="Domains"
        icon={<Globe className="w-4 h-4" />}
        entries={domains} onToggle={handleToggle} onDelete={handleDelete} isPending={isPending}
        resetKey={norm}
      />

      {/* Address section (party-aware) */}
      <Section
        title="Email Addresses"
        icon={<Mail className="w-4 h-4" />}
        entries={addresses} onToggle={handleToggle} onDelete={handleDelete} isPending={isPending}
        assignments={assignments}
        onAssign={email => { setShowAdd(false); setAssignFor(email); }}
        resetKey={norm}
      />

      {/* Import modal */}
      {showImport && (
        <ImportModal
          domains={unregistered}
          onClose={() => setShowImport(false)}
          onImported={added => { setShowImport(false); setUnregistered([]); showToast(added + " domains registered"); }}
        />
      )}
    </div>
  );
}

function StatCard({ label, value, color = "text-gray-900" }: { label: string; value: number; color?: string }) {
  return (
    <div className="border rounded-lg p-4 text-center bg-white">
      <div className={["text-2xl font-bold", color].join(" ")}>{value}</div>
      <div className="text-xs text-gray-500 mt-1">{label}</div>
    </div>
  );
}

const PAGE_SIZE = 25;

function Section({
  title, icon, entries, onToggle, onDelete, isPending, assignments, onAssign, resetKey,
}: {
  title: string;
  icon: React.ReactNode;
  entries: WhitelistEntry[];
  onToggle: (id: string, cur: boolean) => void;
  onDelete: (id: string, p: string) => void;
  isPending: boolean;
  assignments?: Record<string, AddressAssignment>;
  onAssign?: (email: string) => void;
  resetKey?: string;
}) {
  const withParty = !!assignments;
  const [page, setPage] = useState(0);
  useEffect(() => { setPage(0); }, [resetKey]);
  const pages = Math.max(1, Math.ceil(entries.length / PAGE_SIZE));
  const cur = Math.min(page, pages - 1);
  const pageEntries = entries.slice(cur * PAGE_SIZE, cur * PAGE_SIZE + PAGE_SIZE);
  return (
    <div className="border rounded-lg overflow-hidden">
      <div className="px-4 py-3 bg-gray-50 border-b flex items-center gap-2 font-medium text-sm">
        {icon}
        {title}
        <span className="ml-auto text-gray-500 font-normal">{entries.length}</span>
      </div>
      {entries.length === 0 ? (
        <div className="px-4 py-8 text-center text-gray-400 text-sm">
          No registered {title}.
        </div>
      ) : (
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-gray-50/50 text-xs text-gray-500">
              <th className="px-4 py-2 text-left">Pattern</th>
              {withParty && <th className="px-4 py-2 text-left">Party</th>}
              <th className="px-4 py-2 text-left">Notes</th>
              <th className="px-4 py-2 text-left">Registered</th>
              <th className="px-4 py-2 text-center">Status</th>
              <th className="px-4 py-2 text-center">Delete</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {pageEntries.map(e => {
              const a = assignments?.[e.pattern];
              return (
                <tr key={e.id} className={e.is_active ? "hover:bg-gray-50" : "hover:bg-gray-50 opacity-50"}>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <code className="text-sm font-mono">{e.pattern}</code>
                      {FREE.has(e.pattern) && (
                        <span className="text-xs bg-yellow-100 text-yellow-700 px-1.5 py-0.5 rounded">
                          Free email
                        </span>
                      )}
                    </div>
                  </td>
                  {withParty && (
                    <td className="px-4 py-3">
                      {a ? (
                        <button
                          onClick={() => onAssign?.(e.pattern)}
                          className="text-left group"
                          title="Change party"
                        >
                          <span className="inline-flex items-center gap-1.5 font-medium text-gray-800 group-hover:text-blue-700">
                            <Building2 className="w-3.5 h-3.5 text-gray-400" />
                            {a.partyName}
                          </span>
                          {a.fullName && (
                            <div className="text-xs text-gray-500">{a.fullName}</div>
                          )}
                        </button>
                      ) : (
                        <button
                          onClick={() => onAssign?.(e.pattern)}
                          className="text-xs text-blue-600 hover:underline"
                        >
                          Assign party
                        </button>
                      )}
                    </td>
                  )}
                  <td className="px-4 py-3 text-gray-600">{e.notes || "-"}</td>
                  <td className="px-4 py-3 text-gray-500">
                    {new Date(e.created_at).toLocaleDateString("en-US")}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={() => onToggle(e.id, e.is_active)} disabled={isPending}>
                      {e.is_active
                        ? <ToggleRight className="w-5 h-5 text-green-500" />
                        : <ToggleLeft className="w-5 h-5 text-gray-400" />}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button
                      onClick={() => onDelete(e.id, e.pattern)}
                      disabled={isPending}
                      className="text-gray-400 hover:text-red-500"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
      {pages > 1 && (
        <div className="flex items-center justify-between px-4 py-2.5 border-t bg-gray-50 text-xs text-gray-600">
          <span>
            Showing {cur * PAGE_SIZE + 1}-{Math.min((cur + 1) * PAGE_SIZE, entries.length)} of {entries.length}
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage(p => Math.max(0, p - 1))}
              disabled={cur === 0}
              className="p-1.5 border rounded-md bg-white disabled:opacity-40 hover:bg-gray-100"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <span className="px-2">{cur + 1} / {pages}</span>
            <button
              onClick={() => setPage(p => Math.min(pages - 1, p + 1))}
              disabled={cur >= pages - 1}
              className="p-1.5 border rounded-md bg-white disabled:opacity-40 hover:bg-gray-100"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function AddForm({
  fixedEmail, existingAssignment, onClose, onDomainAdded, onAddressRegistered, onError,
}: {
  fixedEmail?: string;
  existingAssignment?: AddressAssignment | null;
  onClose: () => void;
  onDomainAdded: (e: WhitelistEntry) => void;
  onAddressRegistered: (
    entry: WhitelistEntry | null,
    email: string,
    assignment: AddressAssignment,
    msg: string,
  ) => void;
  onError: (m: string) => void;
}) {
  const [kind, setKind] = useState<"domain" | "address">(fixedEmail ? "address" : "domain");
  const [pattern, setPattern] = useState(fixedEmail ?? "");
  const [notes, setNotes] = useState("");
  const [fullName, setFullName] = useState(existingAssignment?.fullName ?? "");
  const [contactTypeId, setContactTypeId] = useState(1);
  const [party, setParty] = useState<PartyOption | null>(null);
  const [q, setQ] = useState("");
  const [opts, setOpts] = useState<PartyOption[]>([]);
  const [searching, setSearching] = useState(false);
  const [conflict, setConflict] = useState<{ partyName: string } | null>(null);
  const [isPending, start] = useTransition();
  const [err, setErr] = useState<string | null>(null);

  // debounced party search
  useEffect(() => {
    if (kind !== "address") return;
    const t = setTimeout(async () => {
      const query = q.trim();
      if (query.length < 2) { setOpts([]); return; }
      setSearching(true);
      try { setOpts(await searchPartiesForWhitelist(query)); }
      finally { setSearching(false); }
    }, 250);
    return () => clearTimeout(t);
  }, [q, kind]);

  const submit = (force = false) => {
    setErr(null);
    if (kind === "domain") {
      start(async () => {
        const res = await addWhitelistEntry(pattern, "domain", notes);
        if (!res.ok) { setErr(res.error || "Error"); return; }
        onDomainAdded({
          id: crypto.randomUUID(),
          pattern: pattern.trim().toLowerCase(),
          kind: "domain", notes: notes || null,
          is_active: true,
          created_at: new Date().toISOString(),
        });
      });
      return;
    }
    // address: requires a party
    if (!party) { setErr("Select a party for this address"); return; }
    start(async () => {
      const email = pattern.trim().toLowerCase();
      const res = await registerAddressEntry({
        email, partyId: party.id,
        fullName: fullName || undefined,
        contactTypeId, notes, force,
      });
      if (!res.ok) {
        if ("conflict" in res) { setConflict({ partyName: res.conflict.partyName }); return; }
        setErr(res.error || "Error");
        return;
      }
      if (res.warning) onError(res.warning);
      const actionMsg =
        res.action === "moved" ? `${email} moved to ${res.partyName}`
        : res.action === "linked" ? `${email} linked to ${res.partyName}`
        : `${email} registered under ${res.partyName}`;
      onAddressRegistered(
        fixedEmail ? null : {
          id: crypto.randomUUID(), pattern: email, kind: "address",
          notes: notes || null, is_active: true, created_at: new Date().toISOString(),
        },
        email,
        {
          contactId: existingAssignment?.contactId ?? crypto.randomUUID(),
          partyId: party.id, partyName: res.partyName,
          fullName: fullName || existingAssignment?.fullName || null,
        },
        actionMsg,
      );
    });
  };

  return (
    <div className="border rounded-lg p-4 bg-blue-50 space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="font-medium text-sm">
          {fixedEmail ? `Assign party — ${fixedEmail}` : "Add New Entry"}
        </h3>
        <button onClick={onClose}><X className="w-4 h-4 text-gray-500" /></button>
      </div>

      {!fixedEmail && (
        <div className="flex gap-2">
          {(["domain", "address"] as const).map(k => (
            <button
              key={k}
              onClick={() => { setKind(k); setConflict(null); setErr(null); }}
              className={["flex-1 py-2 rounded-md text-sm border", kind === k ? "bg-blue-600 text-white border-blue-600" : "bg-white"].join(" ")}
            >
              {k === "domain" ? "Domain" : "Email Address"}
            </button>
          ))}
        </div>
      )}

      <input
        type="text" value={pattern} onChange={e => { setPattern(e.target.value); setConflict(null); }}
        onKeyDown={e => e.key === "Enter" && kind === "domain" && submit()}
        placeholder={kind === "domain" ? "e.g. marinepad.com" : "e.g. jane@marinepad.com"}
        disabled={!!fixedEmail}
        className="w-full px-3 py-2 border rounded-md text-sm disabled:bg-gray-100 disabled:text-gray-500"
      />

      {kind === "address" && (
        <>
          {/* party type-ahead */}
          <div className="space-y-1">
            <label className="text-xs font-medium text-gray-600">
              Party <span className="text-red-500">*</span>
              {existingAssignment && (
                <span className="ml-2 font-normal text-gray-500">
                  currently: {existingAssignment.partyName}
                </span>
              )}
            </label>
            {party ? (
              <div className="flex items-center gap-2 px-3 py-2 bg-white border border-blue-300 rounded-md text-sm">
                <Building2 className="w-4 h-4 text-blue-500" />
                <span className="font-medium">{party.name}</span>
                {party.country && <span className="text-xs text-gray-500">{party.country}</span>}
                {party.typeCode && (
                  <span className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded">{party.typeCode}</span>
                )}
                <button onClick={() => { setParty(null); setConflict(null); }} className="ml-auto">
                  <X className="w-3.5 h-3.5 text-gray-400" />
                </button>
              </div>
            ) : (
              <div className="relative">
                <input
                  type="text" value={q} onChange={e => setQ(e.target.value)}
                  placeholder="Search party by name (e.g. Omya)"
                  className="w-full px-3 py-2 border rounded-md text-sm"
                />
                {searching && (
                  <Loader2 className="w-4 h-4 animate-spin absolute right-3 top-2.5 text-gray-400" />
                )}
                {opts.length > 0 && (
                  <ul className="absolute z-10 mt-1 w-full bg-white border rounded-md shadow-lg max-h-52 overflow-y-auto divide-y">
                    {opts.map(o => (
                      <li key={o.id}>
                        <button
                          onClick={() => { setParty(o); setOpts([]); setQ(""); setConflict(null); }}
                          className="w-full text-left px-3 py-2 text-sm hover:bg-blue-50 flex items-center gap-2"
                        >
                          <Building2 className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                          <span className="font-medium">{o.name}</span>
                          {o.country && <span className="text-xs text-gray-500">{o.country}</span>}
                          {o.typeCode && (
                            <span className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded ml-auto">{o.typeCode}</span>
                          )}
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2">
            <input
              type="text" value={fullName} onChange={e => setFullName(e.target.value)}
              placeholder="Contact name (optional)" className="px-3 py-2 border rounded-md text-sm"
            />
            <select
              value={contactTypeId}
              onChange={e => setContactTypeId(Number(e.target.value))}
              className="px-3 py-2 border rounded-md text-sm bg-white"
            >
              {CONTACT_TYPES.map(t => (
                <option key={t.id} value={t.id}>{t.label}</option>
              ))}
            </select>
          </div>
        </>
      )}

      <input
        type="text" value={notes} onChange={e => setNotes(e.target.value)}
        placeholder="Notes (optional)" className="w-full px-3 py-2 border rounded-md text-sm"
      />

      {conflict && party && (
        <div className="border border-amber-300 bg-amber-50 rounded-md p-3 text-sm space-y-2">
          <p className="text-amber-800">
            <AlertCircle className="w-4 h-4 inline mr-1 -mt-0.5" />
            This address is currently assigned to <b>{conflict.partyName}</b>.
          </p>
          <button
            onClick={() => submit(true)} disabled={isPending}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-amber-600 text-white rounded-md text-xs hover:bg-amber-700 disabled:opacity-50"
          >
            {isPending ? <Loader2 className="w-3 h-3 animate-spin" /> : <ArrowRight className="w-3 h-3" />}
            Move to {party.name}
          </button>
        </div>
      )}

      {err && <p className="text-xs text-red-600">Error: {err}</p>}

      <div className="flex gap-2 justify-end">
        <button onClick={onClose} className="px-3 py-1.5 border rounded-md text-sm bg-white">Cancel</button>
        <button
          onClick={() => submit(false)}
          disabled={!pattern.trim() || isPending || (kind === "address" && !party)}
          className="px-3 py-1.5 bg-blue-600 text-white rounded-md text-sm disabled:opacity-50 inline-flex items-center gap-1"
        >
          {isPending ? <Loader2 className="w-3 h-3 animate-spin" /> : <Plus className="w-3 h-3" />}
          {fixedEmail ? "Save" : "Add"}
        </button>
      </div>
    </div>
  );
}

function ImportModal({
  domains, onClose, onImported,
}: {
  domains: UnregisteredDomain[];
  onClose: () => void;
  onImported: (n: number) => void;
}) {
  const [selected, setSelected] = useState(
    new Set(domains.filter(d => !FREE.has(d.domain)).map(d => d.domain))
  );
  const [isPending, start] = useTransition();

  const toggle = (d: string) =>
    setSelected(p => { const n = new Set(p); n.has(d) ? n.delete(d) : n.add(d); return n; });

  const doImport = () =>
    start(async () => {
      const res = await bulkAddDomains(
        domains.filter(d => selected.has(d.domain)).map(d => ({ domain: d.domain, notes: d.party_names }))
      );
      onImported(res.added);
    });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-lg w-full">
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <h2 className="font-semibold flex items-center gap-2">
            <Download className="w-4 h-4" /> Import Party Domains
          </h2>
          <button onClick={onClose}><X className="w-4 h-4 text-gray-400" /></button>
        </div>
        <p className="px-5 py-3 bg-gray-50 border-b text-xs text-gray-600">
          Domains found in party contact emails.
        </p>
        <div className="divide-y max-h-72 overflow-y-auto">
          {domains.map(d => (
            <label key={d.domain} className="flex items-center gap-3 px-5 py-3 hover:bg-gray-50 cursor-pointer">
              <input type="checkbox" checked={selected.has(d.domain)} onChange={() => toggle(d.domain)} />
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <code className="font-mono text-sm">{d.domain}</code>
                  {FREE.has(d.domain) && (
                    <span className="text-xs bg-yellow-100 text-yellow-700 px-1.5 py-0.5 rounded">
                      Warning: Free email
                    </span>
                  )}
                  <span className="text-xs text-gray-500">{d.contact_count}</span>
                </div>
                <div className="text-xs text-gray-500 truncate">{d.party_names}</div>
              </div>
            </label>
          ))}
        </div>
        <div className="flex items-center justify-between px-5 py-4 border-t bg-gray-50">
          <span className="text-sm text-gray-600">{selected.size} selected</span>
          <div className="flex gap-2">
            <button onClick={onClose} className="px-3 py-1.5 border rounded-md text-sm bg-white">Cancel</button>
            <button
              onClick={doImport} disabled={selected.size === 0 || isPending}
              className="px-3 py-1.5 bg-emerald-600 text-white rounded-md text-sm disabled:opacity-50 inline-flex items-center gap-1"
            >
              {isPending
                ? <><Loader2 className="w-3 h-3 animate-spin" /> Registering...</>
                : <><Check className="w-3 h-3" /> Register {selected.size}</>}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

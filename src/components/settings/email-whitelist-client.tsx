// src/components/settings/email-whitelist-client.tsx
"use client";
import { useState, useTransition } from "react";
import {
  Globe, Mail, Plus, Trash2, ToggleLeft, ToggleRight,
  Download, Loader2, CheckCircle2, AlertCircle, X, Check,
} from "lucide-react";
import {
  addWhitelistEntry, bulkAddDomains,
  toggleWhitelistEntry, deleteWhitelistEntry,
} from "@/lib/actions/email-whitelist";
import type { WhitelistEntry, UnregisteredDomain } from "@/lib/actions/email-whitelist";

const FREE = new Set(["gmail.com","naver.com","yahoo.com","hotmail.com","outlook.com","icloud.com"]);

export function EmailWhitelistClient({
  initialEntries,
  unregisteredDomains,
}: {
  initialEntries: WhitelistEntry[];
  unregisteredDomains: UnregisteredDomain[];
}) {
  const [entries, setEntries] = useState(initialEntries);
  const [unregistered, setUnregistered] = useState(unregisteredDomains);
  const [showAdd, setShowAdd] = useState(false);
  const [showImport, setShowImport] = useState(false);
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

  const domains = entries.filter(e => e.kind === "domain");
  const addresses = entries.filter(e => e.kind === "address");

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
            onClick={() => setShowAdd(true)}
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

      {/* Add form */}
      {showAdd && (
        <AddForm
          onClose={() => setShowAdd(false)}
          onAdded={entry => { setEntries(p => [...p, entry]); setShowAdd(false); showToast('"' + entry.pattern + '" registered'); }}
          onError={msg => showToast(msg, false)}
        />
      )}

      {/* Domain section */}
      <Section
        title="Domains"
        icon={<Globe className="w-4 h-4" />}
        entries={domains} onToggle={handleToggle} onDelete={handleDelete} isPending={isPending}
      />

      {/* Address section */}
      <Section
        title="Email Addresses"
        icon={<Mail className="w-4 h-4" />}
        entries={addresses} onToggle={handleToggle} onDelete={handleDelete} isPending={isPending}
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

function Section({
  title, icon, entries, onToggle, onDelete, isPending,
}: {
  title: string;
  icon: React.ReactNode;
  entries: WhitelistEntry[];
  onToggle: (id: string, cur: boolean) => void;
  onDelete: (id: string, p: string) => void;
  isPending: boolean;
}) {
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
              <th className="px-4 py-2 text-left">Notes</th>
              <th className="px-4 py-2 text-left">Registered</th>
              <th className="px-4 py-2 text-center">Status</th>
              <th className="px-4 py-2 text-center">Delete</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {entries.map(e => (
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
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function AddForm({
  onClose, onAdded, onError,
}: {
  onClose: () => void;
  onAdded: (e: WhitelistEntry) => void;
  onError: (m: string) => void;
}) {
  const [kind, setKind] = useState<"domain" | "address">("domain");
  const [pattern, setPattern] = useState("");
  const [notes, setNotes] = useState("");
  const [isPending, start] = useTransition();
  const [err, setErr] = useState<string | null>(null);

  const submit = () => {
    setErr(null);
    start(async () => {
      const res = await addWhitelistEntry(pattern, kind, notes);
      if (!res.ok) { setErr(res.error || "Error"); return; }
      onAdded({
        id: crypto.randomUUID(),
        pattern: pattern.trim().toLowerCase(),
        kind, notes: notes || null,
        is_active: true,
        created_at: new Date().toISOString(),
      });
    });
  };

  return (
    <div className="border rounded-lg p-4 bg-blue-50 space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="font-medium text-sm">Add New Entry</h3>
        <button onClick={onClose}><X className="w-4 h-4 text-gray-500" /></button>
      </div>
      <div className="flex gap-2">
        {(["domain", "address"] as const).map(k => (
          <button
            key={k}
            onClick={() => setKind(k)}
            className={["flex-1 py-2 rounded-md text-sm border", kind === k ? "bg-blue-600 text-white border-blue-600" : "bg-white"].join(" ")}
          >
            {k === "domain" ? "Domain" : "Email Address"}
          </button>
        ))}
      </div>
      <input
        type="text" value={pattern} onChange={e => setPattern(e.target.value)}
        onKeyDown={e => e.key === "Enter" && submit()}
        placeholder={kind === "domain" ? "e.g. marinepad.com" : "e.g. jane@marinepad.com"}
        className="w-full px-3 py-2 border rounded-md text-sm"
      />
      <input
        type="text" value={notes} onChange={e => setNotes(e.target.value)}
        placeholder="Notes (optional)" className="w-full px-3 py-2 border rounded-md text-sm"
      />
      {err && <p className="text-xs text-red-600">Error: {err}</p>}
      <div className="flex gap-2 justify-end">
        <button onClick={onClose} className="px-3 py-1.5 border rounded-md text-sm bg-white">Cancel</button>
        <button
          onClick={submit} disabled={!pattern.trim() || isPending}
          className="px-3 py-1.5 bg-blue-600 text-white rounded-md text-sm disabled:opacity-50 inline-flex items-center gap-1"
        >
          {isPending ? <Loader2 className="w-3 h-3 animate-spin" /> : <Plus className="w-3 h-3" />}
          Add
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

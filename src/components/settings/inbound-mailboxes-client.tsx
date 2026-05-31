// src/components/settings/inbound-mailboxes-client.tsx
"use client";
import { useState, useTransition } from "react";
import {
  Inbox, Plus, Trash2, ToggleLeft, ToggleRight,
  Loader2, CheckCircle2, AlertCircle, X,
} from "lucide-react";
import {
  addMailbox, toggleMailbox, deleteMailbox,
} from "@/lib/actions/inbound-mailboxes";
import type { InboundMailbox } from "@/lib/actions/inbound-mailboxes";

// 자주 쓰는 IMAP 호스트 프리셋 (선택 시 host/port 자동 채움)
const PRESETS: Record<string, { host: string; port: number }> = {
  "gmail.com":   { host: "imap.gmail.com",          port: 993 },
  "naver.com":   { host: "imap.naver.com",          port: 993 },
  "daum.net":    { host: "imap.daum.net",           port: 993 },
  "hanmail.net": { host: "imap.daum.net",           port: 993 },
  "outlook.com": { host: "outlook.office365.com",   port: 993 },
  "hotmail.com": { host: "outlook.office365.com",   port: 993 },
  "yahoo.com":   { host: "imap.mail.yahoo.com",     port: 993 },
};

export function InboundMailboxesClient({
  initialMailboxes,
}: {
  initialMailboxes: InboundMailbox[];
}) {
  const [boxes, setBoxes] = useState(initialMailboxes);
  const [showAdd, setShowAdd] = useState(false);
  const [isPending, start] = useTransition();
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  };

  const handleToggle = (id: string, cur: boolean) =>
    start(async () => {
      await toggleMailbox(id, !cur);
      setBoxes(p => p.map(b => b.id === id ? { ...b, is_active: !cur } : b));
    });

  const handleDelete = (id: string, address: string) => {
    if (!confirm('Delete "' + address + '"?')) return;
    start(async () => {
      await deleteMailbox(id);
      setBoxes(p => p.filter(b => b.id !== id));
      showToast('"' + address + '" deleted');
    });
  };

  const activeCount = boxes.filter(b => b.is_active).length;

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
          <h2 className="text-xl font-semibold">Inbound Mailboxes</h2>
          <p className="text-sm text-gray-500 mt-1">
            등록한 계정에서 IMAP으로 메일을 수신합니다. 추가/삭제 후 워커를 재시작하세요.
          </p>
        </div>
        <button
          onClick={() => setShowAdd(true)}
          className="inline-flex items-center gap-1.5 px-3 py-2 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
        >
          <Plus className="w-4 h-4" /> Add Mailbox
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard label="Total Mailboxes" value={boxes.length} />
        <StatCard label="Active" value={activeCount} color="text-green-600" />
      </div>

      {/* Add form */}
      {showAdd && (
        <AddForm
          onClose={() => setShowAdd(false)}
          onAdded={(box) => { setBoxes(p => [...p, box]); setShowAdd(false); showToast('"' + box.address + '" registered. Restart worker to apply.'); }}
          onError={(msg) => showToast(msg, false)}
        />
      )}

      {/* List */}
      <div className="border rounded-lg overflow-hidden">
        <div className="px-4 py-3 bg-gray-50 border-b flex items-center gap-2 font-medium text-sm">
          <Inbox className="w-4 h-4" />
          Mailboxes
          <span className="ml-auto text-gray-500 font-normal">{boxes.length}</span>
        </div>
        {boxes.length === 0 ? (
          <div className="px-4 py-8 text-center text-gray-400 text-sm">
            No mailboxes registered.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50/50 text-xs text-gray-500">
                <th className="px-4 py-2 text-left">Address</th>
                <th className="px-4 py-2 text-left">Label</th>
                <th className="px-4 py-2 text-left">IMAP Host</th>
                <th className="px-4 py-2 text-left">Registered</th>
                <th className="px-4 py-2 text-center">Active</th>
                <th className="px-4 py-2 text-center">Delete</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {boxes.map(b => (
                <tr key={b.id} className={b.is_active ? "hover:bg-gray-50" : "hover:bg-gray-50 opacity-50"}>
                  <td className="px-4 py-3">
                    <code className="text-sm font-mono">{b.address}</code>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{b.label || "-"}</td>
                  <td className="px-4 py-3 text-gray-500 font-mono text-xs">{b.imap_host}:{b.imap_port}</td>
                  <td className="px-4 py-3 text-gray-500">
                    {new Date(b.created_at).toLocaleDateString("en-US")}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={() => handleToggle(b.id, b.is_active)} disabled={isPending}>
                      {b.is_active
                        ? <ToggleRight className="w-5 h-5 text-green-500" />
                        : <ToggleLeft className="w-5 h-5 text-gray-400" />}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button
                      onClick={() => handleDelete(b.id, b.address)}
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

function AddForm({
  onClose, onAdded, onError,
}: {
  onClose: () => void;
  onAdded: (b: InboundMailbox) => void;
  onError: (m: string) => void;
}) {
  const [address, setAddress] = useState("");
  const [host, setHost] = useState("");
  const [port, setPort] = useState(993);
  const [label, setLabel] = useState("");
  const [useTls, setUseTls] = useState(true);
  const [password, setPassword] = useState("");
  const [isPending, start] = useTransition();
  const [err, setErr] = useState<string | null>(null);

  // 주소 입력 시 도메인 프리셋으로 host/port 자동 추천 (host 비어있을 때만)
  const onAddressChange = (v: string) => {
    setAddress(v);
    const dom = v.trim().toLowerCase().split("@")[1];
    if (dom && PRESETS[dom] && !host) {
      setHost(PRESETS[dom].host);
      setPort(PRESETS[dom].port);
    }
  };

  const submit = () => {
    setErr(null);
    start(async () => {
      const res = await addMailbox(address, host, port, label, useTls, password);
      if (!res.ok) { setErr(res.error || "Error"); onError(res.error || "Error"); return; }
      onAdded({
        id: crypto.randomUUID(),
        address: address.trim().toLowerCase(),
        label: label.trim() || null,
        imap_host: host.trim(),
        imap_port: port,
        use_tls: useTls,
        is_active: true,
        created_at: new Date().toISOString(),
      });
      setPassword(""); // 비번 즉시 비움
    });
  };

  return (
    <div className="border rounded-lg p-4 bg-blue-50 space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="font-medium text-sm">Add New Mailbox</h3>
        <button onClick={onClose}><X className="w-4 h-4 text-gray-500" /></button>
      </div>

      <div className="space-y-2">
        <label className="block text-xs text-gray-600">Email Address</label>
        <input
          type="email" value={address} onChange={e => onAddressChange(e.target.value)}
          placeholder="e.g. you@company.com"
          className="w-full px-3 py-2 border rounded-md text-sm"
        />
      </div>

      <div className="grid grid-cols-3 gap-2">
        <div className="col-span-2 space-y-2">
          <label className="block text-xs text-gray-600">IMAP Host</label>
          <input
            type="text" value={host} onChange={e => setHost(e.target.value)}
            placeholder="e.g. imap.gmail.com"
            className="w-full px-3 py-2 border rounded-md text-sm font-mono"
          />
        </div>
        <div className="space-y-2">
          <label className="block text-xs text-gray-600">Port</label>
          <input
            type="number" value={port} onChange={e => setPort(Number(e.target.value))}
            className="w-full px-3 py-2 border rounded-md text-sm"
          />
        </div>
      </div>

      <div className="space-y-2">
        <label className="block text-xs text-gray-600">Label (optional)</label>
        <input
          type="text" value={label} onChange={e => setLabel(e.target.value)}
          placeholder="e.g. Company Gmail"
          className="w-full px-3 py-2 border rounded-md text-sm"
        />
      </div>

      <div className="space-y-2">
        <label className="block text-xs text-gray-600">
          IMAP Password / App Password
        </label>
        <input
          type="password" value={password} onChange={e => setPassword(e.target.value)}
          onKeyDown={e => e.key === "Enter" && submit()}
          placeholder="앱 비밀번호 (저장 시 암호화됨)"
          autoComplete="new-password"
          className="w-full px-3 py-2 border rounded-md text-sm"
        />
        <p className="text-xs text-gray-500">
          2단계 인증 계정은 앱 비밀번호가 필요합니다. 비밀번호는 암호화되어 저장되며 다시 표시되지 않습니다.
        </p>
      </div>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={useTls} onChange={e => setUseTls(e.target.checked)} />
        Use TLS (권장)
      </label>

      {err && <p className="text-xs text-red-600">Error: {err}</p>}

      <div className="flex gap-2 justify-end">
        <button onClick={onClose} className="px-3 py-1.5 border rounded-md text-sm bg-white">Cancel</button>
        <button
          onClick={submit}
          disabled={!address.trim() || !host.trim() || !password || isPending}
          className="px-3 py-1.5 bg-blue-600 text-white rounded-md text-sm disabled:opacity-50 inline-flex items-center gap-1"
        >
          {isPending ? <Loader2 className="w-3 h-3 animate-spin" /> : <Plus className="w-3 h-3" />}
          Add
        </button>
      </div>
    </div>
  );
}

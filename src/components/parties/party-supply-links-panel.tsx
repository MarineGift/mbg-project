"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { Factory, Package, Plus, Trash2, TrendingUp, Loader2, X, MapPin } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface SupplyLink {
  id: string;
  linked_id: string;
  linked_name: string;
  linked_module: string;
  linked_country: string | null;
  link_type: string;
  product_grade: string | null;
  volume_estimate: string | null;
  notes: string | null;
}

interface Candidate {
  id: string;
  name: string;
  country_code: string | null;
}

const SUPPLY_TYPES = [
  { value: "active",     label: "Active",     color: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300" },
  { value: "potential",  label: "Potential",  color: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300" },
  { value: "pilot",      label: "Pilot",      color: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300" },
  { value: "historical", label: "Historical", color: "bg-muted text-muted-foreground" },
];

const GRADES = ["PCC", "GCC", "PCC+GCC", "Kaolin", "Talc", "TiO2", "Other"];

function cn(...classes: (string | undefined | false)[]) {
  return classes.filter(Boolean).join(" ");
}

interface Props {
  partyId: string;
  partyType: "filler_supplier" | "paper_mill";
  orgId: string;
}

export function PartySupplyLinksPanel({ partyId, partyType, orgId }: Props) {
  const isFillerPage = partyType === "filler_supplier";
  const linkedPartyType = isFillerPage ? "paper_mill" : "filler_supplier";
  const title = isFillerPage ? "Paper Mills supplied" : "Filler suppliers in use";
  const Icon = isFillerPage ? Factory : Package;

  const [links, setLinks] = useState<SupplyLink[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);

  const loadLinks = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/supply-links?partyId=${partyId}&role=${partyType}`);
      if (res.ok) setLinks(await res.json());
    } finally {
      setLoading(false);
    }
  }, [partyId, partyType]);

  useEffect(() => {
    loadLinks();
  }, [loadLinks]);

  async function removeLink(linkId: string) {
    if (!confirm("Delete this link?")) return;
    await fetch(`/api/supply-links/${linkId}`, { method: "DELETE" });
    setLinks((prev) => prev.filter((l) => l.id !== linkId));
  }

  return (
    <Card>
      <CardHeader className="pb-0">
        <CardTitle className="text-sm flex items-center justify-between">
          <span className="flex items-center gap-2">
            <Icon className="h-4 w-4 text-muted-foreground" />
            {title}
            {!loading && <span className="text-xs font-normal text-muted-foreground ml-1">{links.length}</span>}
          </span>
          <button
            onClick={() => setShowAdd(true)}
            className="inline-flex items-center gap-1 rounded-md bg-blue-600 hover:bg-blue-700 text-white px-2.5 py-1.5 text-xs"
            aria-label="Add link"
          >
            <Plus className="h-3.5 w-3.5" /> Add
          </button>
        </CardTitle>
      </CardHeader>

      <CardContent className="p-0 mt-2">
        {loading ? (
          <div className="flex justify-center py-6">
            <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
          </div>
        ) : links.length === 0 ? (
          <p className="px-4 py-6 text-center text-sm text-muted-foreground italic">
            {isFillerPage ? "No paper mills supplied yet." : "No filler suppliers in use."}
          </p>
        ) : (
          <div className="divide-y max-h-[380px] overflow-y-auto">
            {links.map((lk) => {
              const route = lk.linked_module === "paper_mill" ? "paper_mill" : "filler_supplier";
              const typeInfo = SUPPLY_TYPES.find((t) => t.value === lk.link_type) ?? SUPPLY_TYPES[0];
              return (
                <div key={lk.id} className="flex items-start gap-2 px-4 py-3 hover:bg-muted/30 group">
                  <Link href={`/${route}/parties/${lk.linked_id}`} className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-1.5 mb-0.5">
                      <span className="text-sm font-medium group-hover:text-primary truncate">{lk.linked_name}</span>
                      {lk.linked_country && (
                        <span className="text-xs text-muted-foreground shrink-0">{lk.linked_country}</span>
                      )}
                      <span className={cn("text-[10px] font-medium px-1.5 py-0.5 rounded-full shrink-0", typeInfo!.color)}>
                        {typeInfo!.label}
                      </span>
                    </div>
                    <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                      {lk.product_grade && (
                        <span className="flex items-center gap-0.5">
                          <Package className="h-3 w-3" />
                          {lk.product_grade}
                        </span>
                      )}
                      {lk.volume_estimate && (
                        <span className="flex items-center gap-0.5">
                          <TrendingUp className="h-3 w-3" />
                          {lk.volume_estimate} t/yr
                        </span>
                      )}
                      {lk.notes && <span className="truncate max-w-[180px] italic">{lk.notes}</span>}
                    </div>
                  </Link>
                  <button
                    onClick={() => removeLink(lk.id)}
                    className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-destructive/10 hover:text-destructive transition-all shrink-0"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>

      {showAdd && (
        <AddLinkModal
          partyId={partyId}
          partyType={partyType}
          orgId={orgId}
          linkedPartyType={linkedPartyType}
          onClose={() => setShowAdd(false)}
          onChanged={loadLinks}
        />
      )}
    </Card>
  );
}

function AddLinkModal({
  partyId,
  partyType,
  orgId,
  linkedPartyType,
  onClose,
  onChanged,
}: {
  partyId: string;
  partyType: string;
  orgId: string;
  linkedPartyType: string;
  onClose: () => void;
  onChanged: () => void;
}) {
  const isFillerPage = partyType === "filler_supplier";
  const linkedLabel = isFillerPage ? "Paper Mills" : "Filler suppliers";

  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [country, setCountry] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [addingId, setAddingId] = useState<string | null>(null);

  const [supplyType, setSupplyType] = useState("active");
  const [grade, setGrade] = useState("");
  const [volume, setVolume] = useState("");
  const [notes, setNotes] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/supply-links/candidates?partyId=${partyId}&role=${partyType}`);
      if (res.ok) {
        const j = await res.json();
        setCandidates(j.candidates ?? []);
        setCountry(j.country ?? null);
      }
    } finally {
      setLoading(false);
    }
  }, [partyId, partyType]);

  useEffect(() => {
    load();
  }, [load]);

  async function add(c: Candidate) {
    setAddingId(c.id);
    try {
      const body = {
        organization_id: orgId,
        filler_party_id: isFillerPage ? partyId : c.id,
        mill_party_id: isFillerPage ? c.id : partyId,
        link_type: supplyType,
        volume_estimate: volume.trim() || null,
        notes: notes.trim() || null,
        extra_data: grade ? { product_grade: grade } : null,
      };
      const res = await fetch("/api/supply-links", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (res.ok) {
        setCandidates((prev) => prev.filter((x) => x.id !== c.id));
        onChanged();
      } else {
        alert("Failed to add link.");
      }
    } finally {
      setAddingId(null);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-background rounded-xl shadow-xl w-full max-w-md mx-4 overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <h3 className="font-semibold text-sm flex items-center gap-1.5">
            <MapPin className="h-4 w-4 text-muted-foreground" />
            Add {linkedLabel}
            {country ? ` in ${country}` : ""}
          </h3>
          <button onClick={onClose} className="p-1 hover:bg-muted rounded">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="px-5 py-4 space-y-3 border-b bg-muted/20">
          <div>
            <label className="text-xs font-medium text-muted-foreground mb-1 block">Supply status (applied to each add)</label>
            <div className="flex flex-wrap gap-1.5">
              {SUPPLY_TYPES.map((t) => (
                <button
                  key={t.value}
                  onClick={() => setSupplyType(t.value)}
                  className={cn(
                    "px-2.5 py-1 rounded-full text-xs font-medium transition-colors",
                    supplyType === t.value ? t.color + " ring-1 ring-current" : "bg-muted text-muted-foreground hover:bg-muted/80",
                  )}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-1 block">Product grade</label>
              <select
                value={grade}
                onChange={(e) => setGrade(e.target.value)}
                className="w-full h-8 px-2 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
              >
                <option value="">Not selected</option>
                {GRADES.map((g) => (
                  <option key={g} value={g}>
                    {g}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-1 block">Annual volume (t/yr)</label>
              <input
                type="text"
                value={volume}
                onChange={(e) => setVolume(e.target.value)}
                placeholder="50000"
                className="w-full h-8 px-2 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
              />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground mb-1 block">Notes</label>
            <input
              type="text"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Contract status, special notes, etc..."
              className="w-full h-8 px-3 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
            />
          </div>
        </div>

        <div className="p-3">
          <p className="px-1 pb-2 text-xs text-muted-foreground">
            {linkedLabel} in the same country. Click + to register (you can add several).
          </p>
          {loading ? (
            <div className="flex justify-center py-6">
              <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
            </div>
          ) : candidates.length === 0 ? (
            <p className="px-3 py-6 text-center text-sm text-muted-foreground italic">
              {country ? `No more ${linkedLabel.toLowerCase()} in ${country}.` : "This party has no country set."}
            </p>
          ) : (
            <div className="divide-y max-h-[300px] overflow-y-auto border rounded-md">
              {candidates.map((c) => (
                <div key={c.id} className="flex items-center gap-2 px-3 py-2">
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium truncate">{c.name}</div>
                    <div className="text-xs text-muted-foreground">{c.country_code}</div>
                  </div>
                  <button
                    onClick={() => add(c)}
                    disabled={addingId === c.id}
                    className="inline-flex items-center gap-1 rounded-md bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-40 px-2.5 py-1 text-xs"
                  >
                    {addingId === c.id ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
                    Add
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="flex justify-end px-5 py-4 border-t bg-muted/20">
          <button onClick={onClose} className="px-4 py-1.5 text-sm rounded-md bg-primary text-primary-foreground hover:bg-primary/90">
            Done
          </button>
        </div>
      </div>
    </div>
  );
}

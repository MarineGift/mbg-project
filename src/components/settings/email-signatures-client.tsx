// src/components/settings/email-signatures-client.tsx
// Phase 22b: Email Signatures Management UI (CRUD)
"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Loader2, Plus, Pencil, Trash2, Star } from "lucide-react";
import {
  listEmailSignatures,
  upsertEmailSignature,
  deleteEmailSignature,
} from "@/lib/actions/email-compose";
import { toast } from "sonner";

interface Signature {
  id: string;
  name: string;
  html_content: string;
  is_default: boolean;
}

export function EmailSignaturesClient() {
  const [signatures, setSignatures] = useState<Signature[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Signature | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState<string | null>(null);

  // Form state
  const [formName, setFormName] = useState("");
  const [formHtml, setFormHtml] = useState("");
  const [formIsDefault, setFormIsDefault] = useState(false);

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    const result = await listEmailSignatures();
    if (result.success) {
      setSignatures(result.data ?? []);
    } else {
      toast.error(result.error ?? "Failed to load");
    }
    setLoading(false);
  }

  function openNew() {
    setEditing(null);
    setFormName("");
    setFormHtml(
      `<p style="font-family:sans-serif;font-size:13px;color:#555;line-height:1.6;">
  <strong>Your Name</strong><br>
  Title | Company<br>
  Email: email@example.com
</p>`
    );
    setFormIsDefault(signatures.length === 0); // First signature becomes default
    setDialogOpen(true);
  }

  function openEdit(sig: Signature) {
    setEditing(sig);
    setFormName(sig.name);
    setFormHtml(sig.html_content);
    setFormIsDefault(sig.is_default);
    setDialogOpen(true);
  }

  async function handleSave() {
    if (!formName.trim()) { toast.error("Signature name is required"); return; }
    if (!formHtml.trim()) { toast.error("Signature content is required"); return; }

    setSaving(true);
    const result = await upsertEmailSignature({
      id: editing?.id,
      name: formName.trim(),
      htmlContent: formHtml,
      isDefault: formIsDefault,
    });

    if (result.success) {
      toast.success(editing ? "Signature updated" : "Signature created");
      setDialogOpen(false);
      await load();
    } else {
      toast.error(result.error ?? "Save failed");
    }
    setSaving(false);
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this signature?")) return;
    setDeleting(id);
    const result = await deleteEmailSignature(id);
    if (result.success) {
      toast.success("Signature deleted");
      await load();
    } else {
      toast.error(result.error ?? "Delete failed");
    }
    setDeleting(null);
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-sm text-muted-foreground py-8">
        <Loader2 className="h-4 w-4 animate-spin" />
        Loading...
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Signature list */}
      {signatures.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="py-12 text-center">
            <p className="text-sm text-muted-foreground mb-3">No signatures registered.</p>
            <Button size="sm" onClick={openNew}>
              <Plus className="h-4 w-4 mr-1" />
              Add First Signature
            </Button>
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="flex justify-end">
            <Button size="sm" onClick={openNew}>
              <Plus className="h-4 w-4 mr-1" />
              Add Signature
            </Button>
          </div>
          <div className="space-y-3">
            {signatures.map((sig) => (
              <Card key={sig.id}>
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <CardTitle className="text-base">{sig.name}</CardTitle>
                      {sig.is_default && (
                        <Badge variant="secondary" className="gap-1 text-xs">
                          <Star className="h-3 w-3 fill-current" />
                          Default
                        </Badge>
                      )}
                    </div>
                    <div className="flex gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8"
                        onClick={() => openEdit(sig)}
                      >
                        <Pencil className="h-3.5 w-3.5" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive hover:text-destructive"
                        onClick={() => handleDelete(sig.id)}
                        disabled={deleting === sig.id}
                      >
                        {deleting === sig.id ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <Trash2 className="h-3.5 w-3.5" />
                        )}
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  {/* Preview */}
                  <div
                    className="rounded border bg-muted/30 px-4 py-3 text-sm"
                    dangerouslySetInnerHTML={{ __html: sig.html_content }}
                  />
                </CardContent>
              </Card>
            ))}
          </div>
        </>
      )}

      {/* Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Signature" : "Add New Signature"}</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            {/* Name */}
            <div className="space-y-1">
              <Label htmlFor="sig-name">Signature Name</Label>
              <Input
                id="sig-name"
                value={formName}
                onChange={(e) => setFormName(e.target.value)}
                placeholder="e.g. Default Signature, Formal Signature"
              />
            </div>

            {/* HTML Content */}
            <div className="space-y-1">
              <Label htmlFor="sig-html">HTML Content</Label>
              <textarea
                id="sig-html"
                value={formHtml}
                onChange={(e) => setFormHtml(e.target.value)}
                className="w-full min-h-[180px] rounded-md border border-input bg-background px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-ring"
                placeholder="<p>Enter HTML signature content...</p>"
              />
            </div>

            {/* Preview */}
            {formHtml && (
              <div className="space-y-1">
                <Label className="text-xs text-muted-foreground">Preview</Label>
                <div
                  className="rounded border bg-muted/30 px-4 py-3 text-sm"
                  dangerouslySetInnerHTML={{ __html: formHtml }}
                />
              </div>
            )}

            {/* Default signature toggle */}
            <div className="flex items-center gap-3">
              <Switch
                id="sig-default"
                checked={formIsDefault}
                onCheckedChange={setFormIsDefault}
              />
              <Label htmlFor="sig-default" className="cursor-pointer">
                Set as default
              </Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? (
                <><Loader2 className="h-4 w-4 mr-2 animate-spin" />Saving...</>
              ) : (
                "Save"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

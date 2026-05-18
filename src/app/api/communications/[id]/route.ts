// src/app/api/communications/[id]/route.ts
// Phase 22b: Server-only fetchCommunicationDetail wrapper for client components
import { NextResponse } from "next/server";
import { fetchCommunicationDetail } from "@/lib/queries/communications";

export async function GET(
  _req: Request,
  ctx: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await ctx.params;
    const data = await fetchCommunicationDetail(id);
    if (!data) {
      return NextResponse.json({ error: "not_found" }, { status: 404 });
    }
    return NextResponse.json({ data });
  } catch (e: any) {
    console.error("[GET /api/communications/:id]", e);
    return NextResponse.json(
      { error: e?.message ?? "internal_error" },
      { status: 500 },
    );
  }
}
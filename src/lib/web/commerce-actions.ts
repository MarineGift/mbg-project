'use server';
// src/lib/web/commerce-actions.ts
// Server actions for shop (cart/order) and crowdfunding (pledge). Anonymous
// carts are keyed by an httpOnly cookie token. Payment is left as a clearly
// marked integration point (Stripe/PG).

import { cookies, headers } from 'next/headers';
import { randomUUID } from 'crypto';
import { createClient } from '@supabase/supabase-js';

function sb() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );
}

const CART_COOKIE = 'mbg_cart';

async function getOrCreateCart(siteId: string): Promise<string> {
  const jar = cookies();
  let token = jar.get(CART_COOKIE)?.value;
  const db = sb();

  if (token) {
    const { data } = await db.schema('web').from('carts' as never)
      .select('id').eq('token', token).eq('status', 'open').maybeSingle();
    if (data) return (data as { id: string }).id;
  }

  token = randomUUID();
  jar.set(CART_COOKIE, token, { httpOnly: true, sameSite: 'lax', path: '/', maxAge: 60 * 60 * 24 * 30 });
  const { data } = await db.schema('web').from('carts' as never)
    .insert({ site_id: siteId, token, status: 'open' } as never)
    .select('id').single();
  const row = data as { id: string } | null;
  if (!row) throw new Error('cart create failed');
  return row.id;
}

export async function addToCart(args: {
  site_id: string; variant_id: string; qty?: number;
}): Promise<{ ok: boolean; count?: number; error?: string }> {
  const db = sb();
  const { data: variant } = await db.schema('web').from('product_variants' as never)
    .select('id,price,stock').eq('id', args.variant_id).maybeSingle();
  if (!variant) return { ok: false, error: 'variant not found' };
  const v = variant as { id: string; price: number; stock: number | null };

  const cartId = await getOrCreateCart(args.site_id);
  const qty = Math.max(1, args.qty ?? 1);

  // upsert line (unique cart_id+variant_id)
  const { data: existing } = await db.schema('web').from('cart_items' as never)
    .select('id,qty').eq('cart_id', cartId).eq('variant_id', v.id).maybeSingle();

  if (existing) {
    const e = existing as { id: string; qty: number };
    await db.schema('web').from('cart_items' as never)
      .update({ qty: e.qty + qty } as never).eq('id', e.id);
  } else {
    await db.schema('web').from('cart_items' as never)
      .insert({ cart_id: cartId, variant_id: v.id, qty, unit_price: v.price } as never);
  }

  const { count } = await db.schema('web').from('cart_items' as never)
    .select('id', { count: 'exact', head: true }).eq('cart_id', cartId);
  return { ok: true, count: count ?? undefined };
}

export interface CheckoutInput {
  site_id: string;
  email: string; name?: string; phone?: string;
  shipping?: Record<string, string>;
}

export async function createOrder(
  input: CheckoutInput,
): Promise<{ ok: boolean; order_no?: string; error?: string }> {
  const db = sb();
  const token = cookies().get(CART_COOKIE)?.value;
  if (!token) return { ok: false, error: 'empty cart' };

  const { data: cart } = await db.schema('web').from('carts' as never)
    .select('id').eq('token', token).eq('status', 'open').maybeSingle();
  if (!cart) return { ok: false, error: 'empty cart' };
  const cartId = (cart as { id: string }).id;

  const { data: items } = await db.schema('web').from('cart_items' as never)
    .select('variant_id,qty,unit_price').eq('cart_id', cartId);
  const lines = (items ?? []) as Array<{ variant_id: string; qty: number; unit_price: number }>;
  if (!lines.length) return { ok: false, error: 'empty cart' };

  const subtotal = lines.reduce((s, l) => s + l.qty * Number(l.unit_price), 0);
  const order_no = 'MBG-' + Date.now().toString(36).toUpperCase();

  const { data: order } = await db.schema('web').from('orders' as never)
    .insert({
      site_id: input.site_id, order_no, email: input.email,
      name: input.name ?? null, phone: input.phone ?? null,
      shipping: input.shipping ?? {}, subtotal, total: subtotal, status: 'pending',
    } as never)
    .select('id').single();
  const orderRow = order as { id: string } | null;
  if (!orderRow) return { ok: false, error: 'could not create order' };
  const orderId = orderRow.id;

  // snapshot line items with product/variant names
  for (const l of lines) {
    const { data: v } = await db.schema('web').from('product_variants' as never)
      .select('sku,name,product_id').eq('id', l.variant_id).maybeSingle();
    const vv = v as { sku: string | null; name: string | null; product_id: string } | null;
    let pname = 'Item';
    if (vv) {
      const { data: p } = await db.schema('web').from('products' as never)
        .select('name').eq('id', vv.product_id).maybeSingle();
      pname = (p as { name: string } | null)?.name ?? pname;
    }
    await db.schema('web').from('order_items' as never).insert({
      order_id: orderId, product_name: pname, variant_name: vv?.name ?? null,
      sku: vv?.sku ?? null, qty: l.qty, unit_price: l.unit_price,
      line_total: l.qty * Number(l.unit_price),
    } as never);
  }

  // ---- PAYMENT integration point --------------------------------------
  // const session = await createStripeCheckout({ order_no, amount: subtotal, ... });
  // return { ok: true, order_no, redirect: session.url };
  // ---------------------------------------------------------------------

  await db.schema('web').from('carts' as never)
    .update({ status: 'converted' } as never).eq('id', cartId);
  return { ok: true, order_no };
}

// Crowdfunding pledge -> records pledge + mirrors into unified inbox.
export async function createPledge(args: {
  campaign_id: string; site_id: string; tier_id?: string;
  name?: string; email: string; country?: string; amount?: number;
}): Promise<{ ok: boolean; error?: string }> {
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(args.email)) {
    return { ok: false, error: 'invalid email' };
  }
  const db = sb();
  const h = headers();

  const { data: sub } = await db.schema('web').from('submissions' as never)
    .insert({
      site_id: args.site_id, form_type: 'pledge',
      name: args.name ?? null, email: args.email,
      interest: 'Crowdfunding', source_host: h.get('host') ?? null,
      data: { campaign_id: args.campaign_id, tier_id: args.tier_id, amount: args.amount, country: args.country },
    } as never)
    .select('id').single();

  const { error } = await db.schema('web').from('pledges' as never).insert({
    campaign_id: args.campaign_id, tier_id: args.tier_id ?? null,
    name: args.name ?? null, email: args.email, country: args.country ?? null,
    amount: args.amount ?? null, submission_id: (sub as { id: string } | null)?.id ?? null,
  } as never);
  if (error) return { ok: false, error: 'could not record pledge' };
  return { ok: true };
}

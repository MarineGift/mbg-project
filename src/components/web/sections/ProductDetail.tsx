'use client';
// src/components/web/sections/ProductDetail.tsx
// Product detail: gallery + variant selector + add to cart. Quote-only
// products (no price) show a contact CTA instead.

import { useState, useTransition } from 'react';
import type { Product } from '@/lib/web/types';
import { addToCart } from '@/lib/web/commerce-actions';

export function ProductDetail({ product, siteId }: { product: Product; siteId: string }) {
  const variants = product.variants ?? [];
  const [variantId, setVariantId] = useState(
    variants.find((v) => v.is_default)?.id ?? variants[0]?.id ?? '',
  );
  const [qty, setQty] = useState(1);
  const [activeImg, setActiveImg] = useState(0);
  const [added, setAdded] = useState(false);
  const [pending, start] = useTransition();

  const variant = variants.find((v) => v.id === variantId);
  const price = variant?.price ?? product.base_price;
  const images = product.images ?? [];
  const mainImg = images[activeImg];
  const cur = (n: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: product.currency }).format(n);

  const add = () => {
    if (!variantId) return;
    start(async () => {
      const r = await addToCart({ site_id: siteId, variant_id: variantId, qty });
      if (r.ok) setAdded(true);
    });
  };

  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      <a href="/shop" className="text-sm text-slate-500 hover:underline">&#8249; Back to shop</a>
      <div className="mt-6 grid gap-10 md:grid-cols-2">
        <div>
          <div className="aspect-square overflow-hidden rounded-2xl bg-slate-100">
            {mainImg?.url ? (
              <img src={mainImg.url} alt={product.name} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full items-center justify-center text-slate-300">No image</div>
            )}
          </div>
          {images.length > 1 && (
            <div className="mt-3 flex gap-2">
              {images.map((im, i) => (
                <button key={im.id} onClick={() => setActiveImg(i)}
                  className={`h-16 w-16 overflow-hidden rounded-lg border-2 ${i === activeImg ? '' : 'border-transparent'}`}
                  style={i === activeImg ? { borderColor: 'var(--site-accent)' } : undefined}>
                  <img src={im.url} alt="" className="h-full w-full object-cover" />
                </button>
              ))}
            </div>
          )}
        </div>

        <div>
          {product.category && (
            <span className="text-xs font-medium uppercase tracking-wide text-slate-400">{product.category}</span>
          )}
          <h1 className="mt-1 text-3xl font-bold text-slate-900">{product.name}</h1>
          {product.subtitle && <p className="mt-2 text-slate-500">{product.subtitle}</p>}

          {price != null ? (
            <p className="mt-4 text-2xl font-extrabold text-slate-900">{cur(price)}</p>
          ) : (
            <p className="mt-4 text-lg font-semibold text-slate-700">Contact for quote</p>
          )}

          {product.description && (
            <p className="mt-4 whitespace-pre-line text-slate-600">{product.description}</p>
          )}

          {variants.length > 1 && (
            <div className="mt-6">
              <label className="mb-1 block text-sm font-medium text-slate-700">Option</label>
              <select value={variantId} onChange={(e) => setVariantId(e.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2">
                {variants.map((v) => (
                  <option key={v.id} value={v.id}>{v.name ?? v.sku ?? 'Variant'} - {cur(v.price)}</option>
                ))}
              </select>
            </div>
          )}

          {price != null ? (
            <div className="mt-6 flex items-center gap-3">
              <input type="number" min={1} value={qty}
                onChange={(e) => setQty(Math.max(1, Number(e.target.value) || 1))}
                className="w-20 rounded-lg border border-slate-300 px-3 py-2" />
              <button onClick={add} disabled={pending || added}
                className="flex-1 rounded-lg px-6 py-3 font-semibold text-white disabled:opacity-60"
                style={{ background: 'var(--site-primary)' }}>
                {added ? 'Added to cart' : pending ? 'Adding...' : 'Add to cart'}
              </button>
            </div>
          ) : (
            <a href="/#contact"
              className="mt-6 inline-block rounded-lg px-6 py-3 font-semibold text-white"
              style={{ background: 'var(--site-primary)' }}>
              Request a quote
            </a>
          )}
        </div>
      </div>
    </div>
  );
}

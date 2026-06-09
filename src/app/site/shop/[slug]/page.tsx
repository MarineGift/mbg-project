// src/app/site/shop/[slug]/page.tsx
// Product detail page (template = product). More specific than the catch-all,
// so it wins for /shop/<slug>. Resolves host -> site -> product.

import { headers } from 'next/headers';
import { notFound } from 'next/navigation';
import { resolveHost, resolveSiteBySlug, loadProduct } from '@/lib/web/tenant';
import { SiteChrome } from '@/components/web/SiteChrome';
import { ProductDetail } from '@/components/web/sections/ProductDetail';

export const dynamic = 'force-dynamic';

export default async function ProductPage(
  { params }: { params: { slug: string } },
) {
  const h = headers();
  const slugOverride = h.get('x-mbg-site');
  const site = slugOverride
    ? await resolveSiteBySlug(slugOverride)
    : (await resolveHost(h.get('host') ?? ''))?.site ?? null;
  if (!site) notFound();

  const product = await loadProduct(site.id, params.slug);
  if (!product) notFound();

  return (
    <SiteChrome site={site}>
      <ProductDetail product={product} siteId={site.id} />
    </SiteChrome>
  );
}

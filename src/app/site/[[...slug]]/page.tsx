// src/app/site/[[...slug]]/page.tsx  (REPLACES Phase 1 version)
// One dynamic route serves every tenant page. Resolves host -> site (+ alias
// landing path) -> page -> sections, wrapped in shared header/footer.

import { headers } from 'next/headers';
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { resolveHost, resolveSiteBySlug, loadPage } from '@/lib/web/tenant';
import { SectionRenderer } from '@/components/web/SectionRenderer';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

async function resolve(slugParts: string[] | undefined) {
  const h = headers();
  const host = h.get('host') ?? '';
  const slugOverride = h.get('x-mbg-site');

  let site = null;
  let landing = '/';
  if (slugOverride) {
    site = await resolveSiteBySlug(slugOverride);
  } else {
    const r = await resolveHost(host);
    if (r) { site = r.site; landing = r.landing_path; }
  }
  if (!site) return null;

  const reqPath = '/' + (slugParts ?? []).join('/');
  // when an aliased host hits '/', serve its landing page (e.g. /crowdfunding)
  const path = reqPath === '/' && landing !== '/' ? landing : reqPath;
  const rendered = await loadPage(site, path);
  return rendered;
}

export async function generateMetadata(
  { params }: { params: { slug?: string[] } },
): Promise<Metadata> {
  const r = await resolve(params.slug);
  if (!r) return { title: 'Not found' };
  const desc = r.page.meta?.description ?? (r.site.meta as { description?: string })?.description;
  return { title: r.page.title ?? r.site.name, description: desc };
}

export default async function TenantPage(
  { params }: { params: { slug?: string[] } },
) {
  const r = await resolve(params.slug);
  if (!r) notFound();

  return (
    <SiteChrome site={r.site}>
      {r.sections.map((section) => (
        <SectionRenderer
          key={section.id}
          section={section}
          collections={r.collections}
          site={r.site}
          page={r.page}
          campaign={r.campaign}
          products={r.products}
        />
      ))}
    </SiteChrome>
  );
}

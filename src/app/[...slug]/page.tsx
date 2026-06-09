import { resolveSiteBySlug, loadPage } from '@/lib/web/tenant';
import { SectionRenderer } from '@/components/web/SectionRenderer';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

export default async function ContentPage({ params }: { params: { slug: string[] } }) {
  const site = await resolveSiteBySlug('marinebiogroup');
  if (!site) return <div>Site not found</div>;

  const path = '/' + (params.slug?.join('/') || '');
  const rendered = await loadPage(site, path);

  if (!rendered) return <div className="text-center p-8">Page not found</div>;

  return (
    <SiteChrome site={site}>
      <div>
        {rendered.sections.map((section) => (
          <SectionRenderer
            key={section.id}
            section={section}
            site={site}
            page={rendered.page}
            collections={{}}
          />
        ))}
      </div>
    </SiteChrome>
  );
}
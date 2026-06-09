import { resolveSiteBySlug, loadPage } from '@/lib/web/tenant';
import { SectionRenderer } from '@/components/web/SectionRenderer';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

export default async function ContentPage({ params }: { params: { slug: string[] } }) {
  const site = await resolveSiteBySlug('marinebiogroup');
  if (!site) return <div>Site not found</div>;

  const path = '/' + (params.slug?.join('/') || '');
  const rendered = await loadPage(site, path);

  if (!rendered) {
    return (
      <SiteChrome site={site}>
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <h1 className="text-2xl font-bold">Page not found</h1>
            <a href="/" className="mt-4 inline-block text-blue-600">Back Home</a>
          </div>
        </div>
      </SiteChrome>
    );
  }

  const { sections } = rendered;

  return (
    <SiteChrome site={site}>
      <div>
        {sections.map((section) => (
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
import { resolveSiteBySlug, loadPage } from '@/lib/web/tenant';
import { SectionRenderer } from '@/components/web/SectionRenderer';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

export default async function ShopPage() {
  // 1. Resolve site by slug
  const site = await resolveSiteBySlug('marinebiogroup');
  if (!site) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Site Not Found</h1>
        </div>
      </div>
    );
  }

  // 2. Load shop page
  const rendered = await loadPage(site, '/shop');
  if (!rendered) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Shop Not Found</h1>
          <a href="/" className="mt-4 inline-block text-blue-600">
            Back Home
          </a>
        </div>
      </div>
    );
  }

  const { sections, products = [] } = rendered;

  return (
    <SiteChrome site={site}>
      <div className="min-h-screen bg-gray-50">
        {sections.map((section) => (
          <SectionRenderer
            key={section.id}
            section={section}
            site={site}
            page={rendered.page}
            collections={{}}
            products={products}
          />
        ))}
      </div>
    </SiteChrome>
  );
}
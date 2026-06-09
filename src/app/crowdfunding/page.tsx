import { resolveSiteBySlug, loadPage } from '@/lib/web/tenant';
import { SectionRenderer } from '@/components/web/SectionRenderer';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

export default async function CrowdfundingPage() {
  const site = await resolveSiteBySlug('marinebiogroup');
  if (!site) return <div>Site not found</div>;

  const rendered = await loadPage(site, '/crowdfunding');
  if (!rendered) return <div>Page not found</div>;

  const { sections, campaign } = rendered;

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
            campaign={campaign}
          />
        ))}
      </div>
    </SiteChrome>
  );
}
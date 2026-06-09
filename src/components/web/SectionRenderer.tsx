// src/components/web/SectionRenderer.tsx
// Maps a stored section to its component, forwarding template-loaded data
// (campaign, products). Every registry type except product_detail (a route,
// not a section) now has a component.

import type {
  Section, Site, Page, CollectionItem, Campaign, Product,
} from '@/lib/web/types';
import { isKnownSection } from '@/lib/web/sections';

import { HeroVideo } from './sections/HeroVideo';
import { Carousel } from './sections/Carousel';
import { ContactForm } from './sections/ContactForm';
import { RewardTiers } from './sections/RewardTiers';
import { Progress } from './sections/Progress';
import { Storefront } from './sections/Storefront';
import { FeatureSteps } from './sections/FeatureSteps';
import { CardGrid } from './sections/CardGrid';
import { StatGrid } from './sections/StatGrid';
import { CtaBanner } from './sections/CtaBanner';
import { Timeline } from './sections/Timeline';
import { Story } from './sections/Story';
import { CertBlock } from './sections/CertBlock';
import { DataTable } from './sections/DataTable';

export interface SectionProps {
  section: Section;
  collections: Record<string, CollectionItem[]>;
  site: Site;
  page: Page;
  campaign?: Campaign;
  products?: Product[];
}

const COMPONENTS: Partial<
  Record<Section['type'], (p: SectionProps) => JSX.Element | null>
> = {
  hero_video: HeroVideo,
  carousel: Carousel,
  contact_form: ContactForm,
  reward_tiers: RewardTiers,
  progress: Progress,
  storefront: Storefront,
  feature_steps: FeatureSteps,
  card_grid: CardGrid,
  stat_grid: StatGrid,
  cta_banner: CtaBanner,
  timeline: Timeline,
  story: Story,
  cert_block: CertBlock,
  data_table: DataTable,
};

export function SectionRenderer(props: SectionProps) {
  const { section } = props;
  const Cmp = COMPONENTS[section.type];
  if (Cmp) return <Cmp {...props} />;

  if (process.env.NODE_ENV !== 'production') {
    const known = isKnownSection(section.type);
    return (
      <div className="my-4 border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500">
        {known
          ? `Section "${section.type}" is registered but has no component (e.g. product_detail is a route).`
          : `Unknown section type "${section.type}".`}
      </div>
    );
  }
  return null;
}

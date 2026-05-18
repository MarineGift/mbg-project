/**
 * components/parties/industry-filler-section.tsx
 *
 * "Supply Footprint" section on the filler-supplier detail page (V11.4 master).
 *
 * Renders:
 *   1. Supplier meta header (market code, supplier_type, market_role, supply_model,
 *      relevant_filler_types, evidence URL hints)
 *   2. Stats strip (5 cells: total linkages / Mill-Specific / Footprint / customers / mills)
 *   3. Mill-Specific deals table (paper company x mill x filler x relationship x confidence)
 *   4. Footprint coverage section (grouped by region/country, mills not confirmed)
 *
 * Sales value:
 *   - Mill-Specific = plant-level confirmed = immediate sales action possible
 *   - Footprint = "deals exist in this region" only -> use for mill discovery priority
 */

import { getFillerSupplierIntel } from '@/lib/queries/industry-link';
import type { FillerLinkageRow } from '@/types/industry-link';
import {
  ConfidenceBadge,
  EvidenceBadge,
  Meta,
  StatCell,
} from './industry-shared';

interface Props {
  fillerSupplierId: number;
}

export async function IndustryFillerSection({ fillerSupplierId }: Props) {
  const intel = await getFillerSupplierIntel(fillerSupplierId);

  if (!intel) {
    return (
      <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
        Could not load industry data (filler_supplier_id={fillerSupplierId}).
      </div>
    );
  }

  const { supplier, millSpecificLinks, footprintLinks, stats } = intel;
  const footprintByRegion = groupFootprintByRegion(footprintLinks);

  return (
    <section className="rounded-lg border border-gray-200 bg-white shadow-sm">
      {/* Header: supplier meta */}
      <header className="border-b border-gray-200 px-5 py-4">
        <div className="flex items-baseline justify-between">
          <h2 className="text-base font-semibold text-gray-900">
            Supply Footprint
            <span className="ml-2 text-xs font-normal text-gray-500">
              V11.4 verified
            </span>
          </h2>
          {supplier.evidenceLevel && <EvidenceBadge level={supplier.evidenceLevel} />}
        </div>

        <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 text-xs sm:grid-cols-4">
          {supplier.marketCode && <Meta label="Market code" value={supplier.marketCode} />}
          {supplier.supplierType && <Meta label="Supplier type" value={supplier.supplierType} />}
          {supplier.marketRole && <Meta label="Market role" value={supplier.marketRole} />}
          {supplier.supplyModel && <Meta label="Supply model" value={supplier.supplyModel} />}
        </dl>

        {supplier.relevantFillerTypes.length > 0 && (
          <div className="mt-3 flex flex-wrap items-center gap-1">
            <span className="mr-1 text-xs text-gray-500">Filler types available:</span>
            {supplier.relevantFillerTypes.map((t) => (
              <span
                key={t}
                className="rounded bg-amber-100 px-1.5 py-0.5 text-xs text-amber-900"
              >
                {t}
              </span>
            ))}
          </div>
        )}

        {(supplier.europePaperEvidence || supplier.onsitePccEvidence) && (
          <div className="mt-3 space-y-1 text-xs text-gray-600">
            {supplier.europePaperEvidence && (
              <p>
                <span className="font-medium text-gray-700">EU paper evidence: </span>
                {supplier.europePaperEvidence}
              </p>
            )}
            {supplier.onsitePccEvidence && (
              <p>
                <span className="font-medium text-gray-700">Onsite PCC evidence: </span>
                {supplier.onsitePccEvidence}
              </p>
            )}
          </div>
        )}
      </header>

      {/* Stats strip */}
      <div className="grid grid-cols-2 divide-x divide-gray-200 border-b border-gray-200 sm:grid-cols-5">
        <StatCell label="Total linkages" value={stats.totalLinks} />
        <StatCell
          label="Mill-Specific"
          value={stats.millSpecificCount}
          accent="emerald"
        />
        <StatCell label="Footprint" value={stats.footprintCount} accent="amber" />
        <StatCell label="Customers (unique)" value={stats.uniquePaperCompanies} />
        <StatCell label="Mills (unique)" value={stats.uniqueMills} />
      </div>

      {/* Mill-Specific deals table */}
      <div>
        <div className="flex items-baseline justify-between px-5 pb-2 pt-4">
          <h3 className="text-sm font-medium text-gray-900">
            Mill-Specific deals
            <span className="ml-2 text-xs font-normal text-gray-500">
              {stats.millSpecificCount} entries &middot; plant-level confirmed
            </span>
          </h3>
        </div>
        {millSpecificLinks.length === 0 ? (
          <div className="px-5 pb-4 text-sm text-gray-500">
            No confirmed mill-level deals.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-y border-gray-200 bg-gray-50 text-xs uppercase tracking-wider text-gray-500">
                <tr>
                  <th className="px-5 py-2 text-left font-medium">Paper company</th>
                  <th className="px-3 py-2 text-left font-medium">Mill</th>
                  <th className="px-3 py-2 text-left font-medium">Location</th>
                  <th className="px-3 py-2 text-left font-medium">Filler / Structure</th>
                  <th className="px-3 py-2 text-left font-medium">Relationship</th>
                  <th className="px-3 py-2 text-center font-medium">Conf.</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {millSpecificLinks.map((l) => (
                  <tr key={l.id} className="hover:bg-gray-50">
                    <td className="px-5 py-2.5 align-top font-medium text-gray-900">
                      {l.paperCompanyName}
                    </td>
                    <td className="px-3 py-2.5 align-top text-gray-700">
                      {l.millName ?? '-'}
                    </td>
                    <td className="px-3 py-2.5 align-top text-xs text-gray-600">
                      {[l.marketCode, l.countryRegion].filter(Boolean).join(' / ') ||
                        '-'}
                    </td>
                    <td className="px-3 py-2.5 align-top text-xs">
                      <div className="font-medium text-gray-700">
                        {l.fillerType ?? '-'}
                      </div>
                      {l.supplyStructure && (
                        <div className="text-gray-500">{l.supplyStructure}</div>
                      )}
                    </td>
                    <td className="px-3 py-2.5 align-top text-xs text-gray-600">
                      <div>{l.relationshipType ?? '-'}</div>
                      {l.confirmationStatus && (
                        <div className="text-gray-400">({l.confirmationStatus})</div>
                      )}
                    </td>
                    <td className="px-3 py-2.5 text-center align-top">
                      {l.confidenceGrade ? (
                        <ConfidenceBadge grade={l.confidenceGrade} />
                      ) : (
                        <span className="text-gray-400">-</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Footprint Coverage */}
      {footprintLinks.length > 0 && (
        <div className="border-t border-gray-200 px-5 py-4">
          <h3 className="mb-2 text-sm font-medium text-gray-900">
            Footprint Coverage
            <span className="ml-2 text-xs font-normal text-gray-500">
              {stats.footprintCount} entries &middot; region-level only (mill not confirmed)
            </span>
          </h3>
          <div className="space-y-2">
            {Object.entries(footprintByRegion).map(([region, items]) => (
              <div
                key={region}
                className="rounded border border-amber-200 bg-amber-50/50 p-2.5 text-sm"
              >
                <div className="mb-1 flex items-baseline justify-between">
                  <span className="font-medium text-amber-900">{region}</span>
                  <span className="text-xs text-amber-700">{items.length} entries</span>
                </div>
                <ul className="space-y-0.5 text-xs text-gray-700">
                  {items.map((l) => (
                    <li key={l.id} className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                      <span className="text-gray-400">|</span>
                      <span className="font-medium">{l.paperCompanyName}</span>
                      {l.fillerType && (
                        <span className="text-gray-500">- {l.fillerType}</span>
                      )}
                      {l.supplyStructure && (
                        <span className="text-gray-500">&middot; {l.supplyStructure}</span>
                      )}
                      {l.confidenceGrade && (
                        <ConfidenceBadge grade={l.confidenceGrade} size="xs" />
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Source footer */}
      {supplier.sourceUrl && (
        <footer className="border-t border-gray-200 bg-gray-50 px-5 py-2 text-xs text-gray-500">
          Source:{' '}
          <a
            href={supplier.sourceUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-600 hover:underline"
          >
            {supplier.sourceUrl}
          </a>
        </footer>
      )}
    </section>
  );
}

/**
 * Group footprint linkages by country_region (preferred) or market_code.
 * Within each region, paper company name order is preserved from the query.
 */
function groupFootprintByRegion(
  links: FillerLinkageRow[],
): Record<string, FillerLinkageRow[]> {
  const out: Record<string, FillerLinkageRow[]> = {};
  for (const l of links) {
    const key = l.countryRegion ?? l.marketCode ?? '(unknown region)';
    (out[key] ??= []).push(l);
  }
  return out;
}
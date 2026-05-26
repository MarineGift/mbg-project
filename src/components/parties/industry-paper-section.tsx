/**
 * components/parties/industry-paper-section.tsx
 *
 * "Mill Operations" section on the paper-mill detail page (V11.4 master).
 *
 * Renders:
 *   1. Company meta header (HQ, market code, filler intensity, known filler types)
 *   2. Stats strip (total mills / confirmed supplier mappings / likely-only / unique supplier count)
 *   3. Mill table (confirmed supplier matrix + likely_* fallback intel column)
 *   4. Supplier summary (sorted by mill count)
 *
 * Sales value:
 *   - "Likely intel only" count = mills without confirmed supplier but with
 *     plant-level inference data. Top sales priority.
 *   - Multi-filler mills (e.g. GCC+PCC) expand to multiple supplier rows
 *     (1 supplier x multiple filler_type).
 */

import { getPaperCompanyIntel } from '@/lib/queries/industry-link';
import {
  ConfidenceBadge,
  EvidenceBadge,
  Meta,
  StatCell,
  truncate,
} from './industry-shared';

interface Props {
  paperCompanyId: number;
}

export async function IndustryPaperSection({ paperCompanyId }: Props) {
  const intel = await getPaperCompanyIntel(paperCompanyId);

  if (!intel) {
    return (
      <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
        Could not load industry data (paper_company_id={paperCompanyId}).
      </div>
    );
  }

  const { company, mills, supplierSummary, stats } = intel;

  return (
    <section className="rounded-lg border border-gray-200 bg-white shadow-sm">
      {/* Header: company meta */}
      <header className="border-b border-gray-200 px-5 py-4">
        <div className="flex items-baseline justify-between">
          <h2 className="text-base font-semibold text-gray-900">
            Mill Operations
            <span className="ml-2 text-xs font-normal text-gray-500">
              V11.4 &middot; industry master
            </span>
          </h2>
          {company.evidenceLevel && <EvidenceBadge level={company.evidenceLevel} />}
        </div>

        <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 text-xs sm:grid-cols-4">
          {company.marketCode && <Meta label="Market code" value={company.marketCode} />}
          {company.headquarters && <Meta label="HQ" value={company.headquarters} />}
          {company.fillerUseIntensity && (
            <Meta label="Filler usage intensity" value={company.fillerUseIntensity} />
          )}
          {company.mainProductCategory && (
            <Meta label="Main product line" value={company.mainProductCategory} />
          )}
        </dl>

        {(company.mainProducts ||
          company.europeMillsFootprint ||
          company.supplyStructureNote) && (
          <div className="mt-3 space-y-1.5 text-xs text-gray-600">
            {company.mainProducts && (
              <p>
                <span className="font-medium text-gray-700">Products: </span>
                {company.mainProducts}
              </p>
            )}
            {company.europeMillsFootprint && (
              <p>
                <span className="font-medium text-gray-700">EU mill distribution: </span>
                {company.europeMillsFootprint}
              </p>
            )}
            {company.supplyStructureNote && (
              <p>
                <span className="font-medium text-gray-700">Supply structure note: </span>
                {company.supplyStructureNote}
              </p>
            )}
          </div>
        )}

        {company.knownFillerTypes.length > 0 && (
          <div className="mt-3 flex flex-wrap items-center gap-1">
            <span className="mr-1 text-xs text-gray-500">Known fillers:</span>
            {company.knownFillerTypes.map((t) => (
              <span
                key={t}
                className="rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-700"
              >
                {t}
              </span>
            ))}
          </div>
        )}
      </header>

      {/* Stats strip */}
      <div className="grid grid-cols-2 divide-x divide-gray-200 border-b border-gray-200 sm:grid-cols-4">
        <StatCell label="Mill count" value={stats.totalMills} />
        <StatCell
          label="Confirmed mappings"
          value={stats.millsWithSuppliers}
          accent="emerald"
        />
        <StatCell
          label="Likely intel only"
          value={stats.millsWithLikelyOnly}
          accent={stats.millsWithLikelyOnly > 0 ? 'amber' : 'gray'}
        />
        <StatCell label="Unique suppliers" value={stats.totalSupplierCount} />
      </div>

      {/* Mill table */}
      {mills.length === 0 ? (
        <div className="px-5 py-6 text-center text-sm text-gray-500">
          No mills registered for this paper company.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-xs uppercase tracking-wider text-gray-500">
              <tr>
                <th className="px-5 py-2 text-left font-medium">Mill</th>
                <th className="px-3 py-2 text-left font-medium">Location</th>
                <th className="px-3 py-2 text-left font-medium">Products</th>
                <th className="px-3 py-2 text-left font-medium">Confirmed suppliers</th>
                <th className="px-3 py-2 text-left font-medium">Likely intel</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {mills.map((m) => (
                <tr key={m.id} className="hover:bg-gray-50">
                  <td className="px-5 py-2.5 align-top font-medium text-gray-900">
                    {m.millName}
                  </td>
                  <td className="px-3 py-2.5 align-top text-xs text-gray-600">
                    {[m.city, m.region, m.marketCode].filter(Boolean).join(' / ') ||
                      '-'}
                  </td>
                  <td className="px-3 py-2.5 align-top text-xs text-gray-600">
                    {m.mainProducts ?? m.mainProductCategory ?? '-'}
                  </td>
                  <td className="px-3 py-2.5 align-top">
                    {m.suppliers.length === 0 ? (
                      <span className="text-xs text-gray-400">-</span>
                    ) : (
                      <div className="flex flex-wrap gap-1">
                        {m.suppliers.map((s, i) => (
                          <span
                            key={`${s.fillerSupplierId ?? 'x'}-${i}`}
                            className="inline-flex items-center gap-1 rounded bg-emerald-50 px-1.5 py-0.5 text-xs text-emerald-900"
                          >
                            <span className="font-medium">{s.supplierName}</span>
                            {s.fillerType && (
                              <span className="text-emerald-700">
                                &middot;{s.fillerType}
                              </span>
                            )}
                            {s.confidenceGrade && (
                              <ConfidenceBadge grade={s.confidenceGrade} size="xs" />
                            )}
                          </span>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="px-3 py-2.5 align-top text-xs text-gray-600">
                    {m.likelyFillerTypes.length === 0 &&
                    !m.likelySupplierNote &&
                    !m.fillerProbability ? (
                      <span className="text-gray-400">-</span>
                    ) : (
                      <div className="space-y-0.5">
                        {m.fillerProbability && (
                          <div className="text-gray-500">
                            prob: {m.fillerProbability}
                          </div>
                        )}
                        {m.likelyFillerTypes.length > 0 && (
                          <div>{m.likelyFillerTypes.join(', ')}</div>
                        )}
                        {m.likelySupplyStructure && (
                          <div className="text-gray-500">
                            Structure: {m.likelySupplyStructure}
                          </div>
                        )}
                        {m.likelySupplierNote && (
                          <div
                            className="italic text-gray-500"
                            title={m.likelySupplierNote}
                          >
                            {truncate(m.likelySupplierNote, 80)}
                          </div>
                        )}
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Supplier summary */}
      {supplierSummary.length > 0 && (
        <div className="border-t border-gray-200 px-5 py-4">
          <h3 className="mb-2 text-sm font-medium text-gray-900">
            Supplier summary
            <span className="ml-2 text-xs font-normal text-gray-500">
              (by mill count)
            </span>
          </h3>
          <ul className="space-y-1.5">
            {supplierSummary.map((s) => (
              <li
                key={s.fillerSupplierId ?? s.supplierName}
                className="flex items-center gap-2 text-sm"
              >
                <span className="inline-block h-4 w-1.5 rounded-sm bg-emerald-400" />
                <span className="font-medium text-gray-900">{s.supplierName}</span>
                <span className="text-gray-500">
                  - {s.millCount} mill{s.millCount > 1 ? 's' : ''}
                </span>
                {s.topConfidence && (
                  <ConfidenceBadge grade={s.topConfidence} size="xs" />
                )}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Source footer */}
      {company.sourceUrl && (
        <footer className="border-t border-gray-200 bg-gray-50 px-5 py-2 text-xs text-gray-500">
          Source:{' '}
          <a
            href={company.sourceUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-600 hover:underline"
          >
            {company.sourceUrl}
          </a>
        </footer>
      )}
    </section>
  );
}
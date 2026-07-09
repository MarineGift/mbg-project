// src/lib/applications/canonical-templates.ts
// Standard question sets per form_type. Creating an application form
// "from template" means: generate application_form_fields rows with these
// canonical_key values, then auto-bind the best-fitting answer_library
// variant (short / medium / long) against each field's max_length.
//
// Keys MUST match app.answer_library.answer_key values. The catalog is
// defined by whatever keys exist in the library - unmatched keys still
// create the field, just with no bound answer (state: empty).

export type TemplateFormType =
  | 'application'
  | 'accelerator'
  | 'grant'
  | 'pitch_event'
  | 'contact_inquiry';

export interface TemplateField {
  canonicalKey: string;
  label: string;
  /** default char limit hint; null = unlimited */
  maxLength: number | null;
  isRequired: boolean;
}

const F = (
  canonicalKey: string,
  label: string,
  maxLength: number | null = null,
  isRequired = true,
): TemplateField => ({ canonicalKey, label, maxLength, isRequired });

export const CANONICAL_TEMPLATES: Record<TemplateFormType, TemplateField[]> = {
  // Generic angel-group / VC application (Dealum-style)
  application: [
    F('company_one_liner', 'One-line company description', 200),
    F('problem', 'What problem are you solving?'),
    F('solution', 'Describe your solution / product'),
    F('market_customers', 'Who are your customers?'),
    F('market_size_musd', 'Market size'),
    F('uvp', 'Unique value proposition'),
    F('competitors', 'Competition and how you differ'),
    F('business_model', 'Business model / how you make money'),
    F('traction', 'Traction to date'),
    F('go_to_market', 'Go-to-market strategy'),
    F('team_management', 'Team and management'),
    F('capital_seeking', 'How much are you raising?', 200),
    F('deal_terms', 'Deal terms / instrument', 500),
    F('use_of_funds', 'Use of funds'),
    F('ip_portfolio', 'Intellectual property'),
  ],

  // Accelerator application (Techstars / SOSV / Third Derivative style)
  accelerator: [
    F('company_one_liner', 'One-line company description', 200),
    F('problem', 'Problem'),
    F('solution', 'Solution / technology'),
    F('market_customers', 'Target customers'),
    F('uvp', 'What makes you different?'),
    F('competitors', 'Competitive landscape'),
    F('traction', 'Traction and milestones achieved'),
    F('team_management', 'Founding team'),
    F('milestones', 'Milestones for the next 12-18 months'),
    F('capital_seeking', 'Current fundraise', 300),
    F('use_of_funds', 'What would you use the program / funds for?'),
  ],

  // Grant / SBIR-style (NSF Project Pitch: 4 x 3500 chars)
  grant: [
    F('company_one_liner', 'Company summary', 500),
    F('solution', 'The technology innovation', 3500),
    F('problem', 'The technical objectives and challenges', 3500),
    F('market_size_musd', 'The market opportunity', 3500),
    F('team_management', 'The company and team', 3500),
    F('ip_portfolio', 'Intellectual property position', 2000, false),
    F('milestones', 'Key R&D milestones', 2000, false),
    F('use_of_funds', 'Budget / use of funds', 2000, false),
    F('risks_mitigations', 'Technical risks and mitigations', 2000, false),
  ],

  // Pitch event / demo day registration
  pitch_event: [
    F('company_one_liner', 'One-line pitch', 200),
    F('problem', 'Problem', 1000),
    F('solution', 'Solution', 1000),
    F('traction', 'Traction', 1000),
    F('deal_terms', 'Round details', 500),
    F('use_of_funds', 'Use of funds', 1000, false),
  ],

  // Mill / supplier contact-us inquiry (reuses the same machinery)
  contact_inquiry: [
    F('company_one_liner', 'Who we are', 300),
    F('solution', 'Product / technology introduction', 2000),
    F('uvp', 'Why it matters to you', 1000),
    F('traction', 'Validation and references', 1000, false),
    F('business_model', 'Commercial model', 1000, false),
  ],
};

export const TEMPLATE_FORM_TYPES: { value: TemplateFormType; label: string }[] = [
  { value: 'application', label: 'Investor application' },
  { value: 'accelerator', label: 'Accelerator application' },
  { value: 'grant', label: 'Grant / SBIR' },
  { value: 'pitch_event', label: 'Pitch event' },
  { value: 'contact_inquiry', label: 'Contact inquiry (mill / supplier)' },
];

// ------------------------------------------------------------
// Variant selection: pick the library row whose effective length
// best fits the field's max_length.
//   effective length = target_length ?? length(body_en)
//   max_length null  -> prefer medium, then long, then short
//   max_length set   -> largest variant that fits; if none fit,
//                       the shortest available (will show over_limit)
// ------------------------------------------------------------

export interface LibraryRowLite {
  id: string;
  answer_key: string;
  variant: 'short' | 'medium' | 'long' | string;
  target_length: number | null;
  body_en: string | null;
  disclosure_level: string;
}

const NO_LIMIT_ORDER: Record<string, number> = { medium: 0, long: 1, short: 2 };

export function pickVariant(
  candidates: LibraryRowLite[],
  maxLength: number | null,
): LibraryRowLite | null {
  if (candidates.length === 0) return null;
  const withLen = candidates.map((c) => ({
    row: c,
    len: c.target_length ?? (c.body_en ? c.body_en.length : 0),
  }));

  if (maxLength == null) {
    return [...withLen].sort(
      (a, b) =>
        (NO_LIMIT_ORDER[a.row.variant] ?? 9) - (NO_LIMIT_ORDER[b.row.variant] ?? 9),
    )[0]?.row ?? null;
  }

  const fitting = withLen.filter((c) => c.len > 0 && c.len <= maxLength);
  if (fitting.length > 0) {
    // largest that still fits
    return fitting.sort((a, b) => b.len - a.len)[0]?.row ?? null;
  }
  // nothing fits: shortest available so the over_limit overshoot is minimal
  return withLen.sort((a, b) => a.len - b.len)[0]?.row ?? null;
}

/**
 * lib/utils/merge-fields.ts
 *
 * Render merge fields like {{name}}, {{company}} inside email templates.
 * Missing/undefined values render as empty string by default.
 * Pass { keepUnknown: true } to leave tokens with no value untouched so a
 * later pass (e.g. server-side renderWithContext) can still fill them.
 */

export type MergeFieldValues = Record<string, string | number | null | undefined>;

export interface RenderMergeFieldsOptions {
  /** When true, tokens whose key is absent from `data` are left as-is
   *  instead of being replaced with an empty string. */
  keepUnknown?: boolean;
}

/**
 * Replace {{field}} tokens with values from the data map.
 *
 * @example
 *   renderMergeFields("Hi {{name}}, from {{company}}", { name: "Anna", company: "Acme" })
 *   // => "Hi Anna, from Acme"
 *
 *   renderMergeFields("Hi {{name}}", {}, { keepUnknown: true })
 *   // => "Hi {{name}}"   (token preserved for a later render pass)
 */
export function renderMergeFields(
  template: string,
  data: MergeFieldValues = {},
  opts: RenderMergeFieldsOptions = {},
): string {
  if (!template) return '';
  return template.replace(/\{\{\s*([a-zA-Z0-9_.-]+)\s*\}\}/g, (match, key) => {
    const has = Object.prototype.hasOwnProperty.call(data, key);
    if (!has) return opts.keepUnknown ? match : '';
    const v = data[key];
    if (v === null || v === undefined) return opts.keepUnknown ? match : '';
    return String(v);
  });
}

/**
 * Extract all merge field keys referenced in a template.
 */
export function extractMergeFields(template: string): string[] {
  if (!template) return [];
  const out = new Set<string>();
  const re = /\{\{\s*([a-zA-Z0-9_.-]+)\s*\}\}/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(template)) !== null) {
    out.add(m[1]!);
  }
  return Array.from(out);
}

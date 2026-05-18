/**
 * lib/utils/merge-fields.ts
 *
 * Render merge fields like {{name}}, {{company}} inside email templates.
 * Missing/undefined values render as empty string.
 */

export type MergeFieldValues = Record<string, string | number | null | undefined>;

/**
 * Replace {{field}} tokens with values from the data map.
 * Unknown fields render as empty string (silent).
 *
 * @example
 *   renderMergeFields("Hi {{name}}, from {{company}}", { name: "Anna", company: "Acme" })
 *   // => "Hi Anna, from Acme"
 */
export function renderMergeFields(
  template: string,
  data: MergeFieldValues = {},
): string {
  if (!template) return '';
  return template.replace(/\{\{\s*([a-zA-Z0-9_.-]+)\s*\}\}/g, (_match, key) => {
    const v = data[key];
    if (v === null || v === undefined) return '';
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
    out.add(m[1]);
  }
  return Array.from(out);
}
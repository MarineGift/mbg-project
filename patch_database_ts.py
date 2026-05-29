#!/usr/bin/env python3
# D9 type patch for src/types/database.ts   usage: python patch_database_ts.py <path>
# Auto-detects encoding via BOM (utf-8 / utf-16-le / utf-16-be / plain utf-8).
# Writes exact-byte backup <path>.bak, then writes result as UTF-8 (no BOM), LF preserved.
import sys, re, codecs

def detect_decode(raw):
    if raw.startswith(codecs.BOM_UTF8):    return raw.decode('utf-8-sig'),  'utf-8-bom'
    if raw.startswith(codecs.BOM_UTF16_LE):return raw.decode('utf-16'),     'utf-16-le'
    if raw.startswith(codecs.BOM_UTF16_BE):return raw.decode('utf-16'),     'utf-16-be'
    return raw.decode('utf-8'), 'utf-8'

def find_block_span(text, header_with_colon):
    m = re.search(r'\n([ \t]*)' + re.escape(header_with_colon) + r'\s*\{', text)
    if not m: return None
    i = text.index('{', m.start()); depth = 0; start = m.start()+1
    while i < len(text):
        c = text[i]
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                j = i+1
                while j < len(text) and text[j] in ', \t': j += 1
                if j < len(text) and text[j] == '\n': j += 1
                return (start, j)
        i += 1
    return None

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else 'src/types/database.ts'
    raw = open(path, 'rb').read()
    text, enc = detect_decode(raw)
    text = text.replace('\r\n', '\n')                  # normalize newlines for matching
    orig = len(text)
    for h in ['contacts:', 'contacts_history:', 'person_firm_history:']:
        if re.search(r'\n[ \t]*' + re.escape(h) + r'\s*\{', text) is None:
            raise SystemExit(f"ERROR: block '{h}' not found - wrong or already-patched file?")

    s, e = find_block_span(text, 'contacts:')
    block = text[s:e]; n = block.count('firm_party_id')
    text = text[:s] + block.replace('firm_party_id', 'party_id') + text[e:]

    removed = []
    for h in ['contacts_history:', 'person_firm_history:']:
        span = find_block_span(text, h)
        if span is None: raise SystemExit(f"ERROR: cannot bound {h}")
        removed.append((h, span[1]-span[0])); text = text[:span[0]] + text[span[1]:]

    leftover = text.count('firm_party_id')
    open(path + '.bak', 'wb').write(raw)                       # exact original bytes
    open(path, 'wb').write(text.encode('utf-8'))               # normalize -> UTF-8 no BOM, LF
    print(f"  source encoding detected: {enc}  ->  written as UTF-8 (no BOM), LF")
    print(f"  contacts: {n} firm_party_id -> party_id")
    for h, sz in removed: print(f"  removed {h} ({sz} bytes)")
    print(f"  leftover firm_party_id (expect investor_partner_profile + p_firm_party_id args): {leftover}")
    print(f"  size {orig} -> {len(text)} chars")

if __name__ == '__main__': main()

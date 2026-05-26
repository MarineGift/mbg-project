#!/usr/bin/env python3
"""
industry.* 한글 데이터 → 영문 번역 스크립트
Usage:
  python translate_industry.py --table market_findings --input mf.csv
  python translate_industry.py --table paper_companies --input pc.csv
  python translate_industry.py --all --input-dir ./csv_exports/

출력: UPDATE SQL 파일 (apply_translations_<table>.sql)
"""

import csv
import json
import re
import sys
import time
import argparse
import os
from pathlib import Path

# Anthropic SDK
try:
    import anthropic
except ImportError:
    print("pip install anthropic")
    sys.exit(1)

# ── 테이블별 번역 컬럼 정의 ──────────────────────────────────────────────
TABLE_COLUMNS = {
    "market_findings": ["description", "finding_category", "evidence_source"],
    "paper_companies": ["notes", "main_products", "supply_structure_note", "onsite_pcc_evidence"],
    "paper_mills":     ["notes", "main_products", "filler_probability", "basis_for_filler", "likely_supplier_note"],
    "filler_suppliers":["notes", "europe_paper_evidence", "onsite_pcc_evidence"],
    "supplier_mill_linkages": ["notes"],
    "filler_plants":   ["notes", "product_focus"],
    "verification_queue": ["notes", "hypothesized_relationship", "why_needs_verification"],
}

KOREAN_RE = re.compile(r'[가-힣]')

def has_korean(text: str) -> bool:
    return bool(text) and bool(KOREAN_RE.search(text))

def translate_batch(client, texts: list[str]) -> list[str]:
    """최대 20개 텍스트를 한 번의 API 호출로 번역"""
    if not texts:
        return []
    
    numbered = "\n".join(f"[{i+1}] {t}" for i, t in enumerate(texts))
    prompt = f"""Translate the following Korean texts to English.
These are B2B paper industry data fields (mills, filler suppliers, market findings).
Keep technical terms (GCC, PCC, CaCO3, etc.) as-is.
Respond with ONLY a JSON array of translated strings, same order, no extra text.
Example: ["translated text 1", "translated text 2"]

Texts to translate:
{numbered}"""

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    
    raw = response.content[0].text.strip()
    # JSON 파싱
    raw = re.sub(r'^```json\s*', '', raw)
    raw = re.sub(r'```\s*$', '', raw)
    result = json.loads(raw)
    assert len(result) == len(texts), f"Length mismatch: {len(result)} vs {len(texts)}"
    return result

def sql_escape(s: str) -> str:
    return s.replace("'", "''")

def process_table(table: str, input_csv: str, output_sql: str, dry_run: bool = False):
    cols = TABLE_COLUMNS.get(table)
    if not cols:
        print(f"[WARN] Unknown table: {table}")
        return

    client = anthropic.Anthropic()  # ANTHROPIC_API_KEY env var
    
    rows = []
    with open(input_csv, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"[{table}] {len(rows)} rows loaded, columns: {cols}")

    # 번역 필요한 (row_idx, col) 수집
    pending = []  # (row_idx, col, original_text)
    for i, row in enumerate(rows):
        for col in cols:
            val = row.get(col, "") or ""
            if has_korean(val):
                pending.append((i, col, val))

    print(f"[{table}] {len(pending)} Korean cells to translate")
    if not pending:
        print(f"[{table}] Nothing to translate.")
        return

    if dry_run:
        for i, col, val in pending[:5]:
            print(f"  row {rows[i]['id']} [{col}]: {val[:80]}")
        return

    # 배치 번역 (20개씩)
    BATCH = 15
    translated_map = {}  # (row_idx, col) -> translated text

    for start in range(0, len(pending), BATCH):
        batch = pending[start:start+BATCH]
        texts = [item[2] for item in batch]
        print(f"  Translating batch {start//BATCH + 1}/{(len(pending)-1)//BATCH + 1} ({len(texts)} cells)...")
        
        try:
            results = translate_batch(client, texts)
            for (row_idx, col, _), translated in zip(batch, results):
                translated_map[(row_idx, col)] = translated
            time.sleep(0.3)  # rate limit 완충
        except Exception as e:
            print(f"  [ERROR] batch {start}: {e}")
            # 실패한 배치는 원본 유지
            for row_idx, col, orig in batch:
                translated_map[(row_idx, col)] = orig

    # UPDATE SQL 생성
    sql_lines = [
        f"-- Auto-generated translation: industry.{table}",
        f"-- Generated: {__import__('datetime').datetime.utcnow().isoformat()}Z",
        f"-- Total updates: {len(translated_map)}",
        "",
        "BEGIN;",
        "",
    ]

    # row_idx별로 그룹화
    from collections import defaultdict
    row_updates = defaultdict(dict)
    for (row_idx, col), translated in translated_map.items():
        row_updates[row_idx][col] = translated

    for row_idx, col_vals in sorted(row_updates.items()):
        row_id = rows[row_idx]['id']
        set_clauses = ", ".join(
            f"{col} = '{sql_escape(val)}'" 
            for col, val in col_vals.items()
        )
        sql_lines.append(
            f"UPDATE industry.{table} SET {set_clauses} WHERE id = {row_id};"
        )

    sql_lines += ["", "COMMIT;", ""]

    with open(output_sql, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_lines))

    print(f"[{table}] Done. SQL -> {output_sql}")
    print(f"[{table}] {len(row_updates)} rows will be updated")

def main():
    parser = argparse.ArgumentParser(description="Translate Korean industry data to English")
    parser.add_argument("--table", help="Table name (e.g. market_findings)")
    parser.add_argument("--input", help="Input CSV file")
    parser.add_argument("--output", help="Output SQL file (default: translate_<table>.sql)")
    parser.add_argument("--input-dir", help="Directory with CSV files named <table>.csv")
    parser.add_argument("--all", action="store_true", help="Process all tables in --input-dir")
    parser.add_argument("--dry-run", action="store_true", help="Preview only, no API calls")
    args = parser.parse_args()

    if args.all and args.input_dir:
        for table in TABLE_COLUMNS:
            csv_path = os.path.join(args.input_dir, f"{table}.csv")
            if os.path.exists(csv_path):
                out_sql = os.path.join(args.input_dir, f"translate_{table}.sql")
                process_table(table, csv_path, out_sql, args.dry_run)
            else:
                print(f"[SKIP] {csv_path} not found")
    elif args.table and args.input:
        out = args.output or f"translate_{args.table}.sql"
        process_table(args.table, args.input, out, args.dry_run)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

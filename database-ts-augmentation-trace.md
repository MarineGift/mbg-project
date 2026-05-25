# database.ts manual augmentation trace
Generated: 2026-05-25 17:10:58

## 1. Current size

- file: `src\types\database.ts`
- lines: 12632
- expected from `supabase gen types`: ~12,072
- gap to explain: ~560

## 2. Schema sections present

Top-level schema keys appearing in the Database type tree.

```
L609: app: {
L10297: public: {
L10767: urm: {
L12420: app: {
L12633: public: {
L12638: urm: {
```

## 3. Manual-edit markers

```
L10061: | "manual_entry"
L10073: | "manual_merged"
L10222: task_status: "todo" | "in_progress" | "blocked" | "done" | "cancelled"
L10724: save_manual_email: {
L12445: "manual_entry",
L12459: "manual_merged",
L12625: task_status: ["todo", "in_progress", "blocked", "done", "cancelled"],
```

## 4. Top-level exports

`supabase gen types` produces ONE top-level export (`Database`) plus a fixed set
of helper aliases (`Tables`, `TablesInsert`, etc.). Anything else here is manual.

```
L1: export type Json =
L9: export type Database = {
L12279: export type Tables<
L12308: export type TablesInsert<
L12333: export type TablesUpdate<
L12358: export type Enums<
L12375: export type CompositeTypes<
L12392: export const Constants = {
```

## 5. Functions / RPC blocks

`Functions: { ... }` keys per schema are a common manual-augmentation target
when the regen output omits or under-types an RPC.

```
L554: (Functions block start)
L9866: (Functions block start)
L10287: (Functions block start)
L10304: (Functions block start)
L12263: (Functions block start)
```

## 6. Recent commits touching database.ts (last 30)

```
e943d6e stage29c-cleanup: launch prep
3506d2a stage29c: regen database.ts with urm schema
1120d82 Stage 27 WIP: typed RPC wrapper + database unification (suspended for Stage 30 industry migration)
167b620 refactor(parties): align PartyDetail with DB schema
```

## 7. Diff stats per commit (last 30)

Big +line counts on isolated commits often indicate manual augmentation events.

```
e943d6e stage29c-cleanup: launch prep
 1 file changed, 0 insertions(+), 0 deletions(-)

3506d2a stage29c: regen database.ts with urm schema
 1 file changed, 0 insertions(+), 0 deletions(-)

1120d82 Stage 27 WIP: typed RPC wrapper + database unification (suspended for Stage 30 industry migration)
 1 file changed, 0 insertions(+), 0 deletions(-)

167b620 refactor(parties): align PartyDetail with DB schema
 1 file changed, 93 insertions(+)
```

## 8. Suggested triage

1. Run a clean regen into a side file (do NOT overwrite):
   ```powershell
   supabase gen types typescript --linked --schema 'public,app,urm,industry' > src\types\database.regen.ts
   ```
2. Diff:
   ```powershell
   git --no-pager diff --no-index --stat src\types\database.regen.ts src\types\database.ts
   ```
3. For every block present in `database.ts` but absent in `database.regen.ts`,
   decide:
   - Is it a missing schema in the regen flags? --- fix the `--schema` arg.
   - Is it a hand-typed RPC? --- preserve it (port into a sibling file or comment).
   - Is it dead? --- drop it.

4. Only after the augmentation surface is catalogued should Step 3 regen run.

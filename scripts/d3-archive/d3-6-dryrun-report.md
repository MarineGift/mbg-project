# D3-6 Label change report - 2026-05-26 11:26:49

- **Mode**: DRY-RUN
- **Scope**: src/**/*.{ts,tsx} (excluded: __tests__, database.ts)
- **Files**: 322

## Replacement rules

| Before | After |
|---|---|
| `'All modules'` | `'All'` |
| `"All modules"` | `"All"` |
| `>All modules<` | `>All<` |
| `'Module'` | `'Party type'` |
| `"Module"` | `"Party type"` |
| `>Module<` | `>Party type<` |

## Matches by file

### `src\components\settings\email-templates\template-form-modal.tsx`
- `[x1]` JSX text >Module< -> `>Party type<`

### `src\components\settings\bulk-enroll-dialog.tsx`
- `[x1]` single-quoted 'All modules' -> `'All'`
- `[x1]` JSX text >Module< -> `>Party type<`

### `src\components\settings\quick-campaign-dialog.tsx`
- `[x1]` single-quoted 'All modules' -> `'All'`
- `[x1]` JSX text >Module< -> `>Party type<`


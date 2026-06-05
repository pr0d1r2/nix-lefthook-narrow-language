# SPEC — nix-lefthook-narrow-language

## §G GOAL

Lefthook-compatible narrow-language vocabulary checks, packaged as Nix flake. Enforce controlled vocabulary per file type via per-language dictionary files. Unknown words fail check. Compact removes unused entries. Freeze prevents dictionary growth. Suggest finds known synonyms via WordNet.

## §C CONSTRAINTS

- C1: Nix flake, pinned `nixos-25.11`, four packages (check, compact, freeze, suggest)
- C2: Shell scripts sourced by `writeShellApplication` — no shebang, no `set` needed
- C3: GNU coreutils, grep, sed, gawk — portable macOS + Linux
- C4: Lefthook remote — consumers add `lefthook-remote.yml` to their `lefthook.yml`
- C5: Per-language dictionaries: `.narrow-language-<lang>.dic` (one word per line, sorted)
- C6: Word extraction: `grep -oE '[A-Za-z]+'`, camelCase split, lowercase, min 3 chars, must contain vowel
- C7: Check runs on staged/push files only (priority 2)
- C8: Compact runs on all tracked files scoped by `NARROW_LANGUAGE_GLOB_INCLUDE` (priority 1, before check)
- C9: Freeze rejects new dictionary entries when `NARROW_LANGUAGE_FROZEN=true`
- C10: Suggest uses WordNet to find known synonyms for unknown words
- C11: `NARROW_LANGUAGE_EXCLUDE_FILES` — colon-separated patterns to skip in check

## §I INTERFACES

- I.check: `lefthook-narrow-language <files>` — report unknown words per file
- I.compact: `lefthook-narrow-language-compact` — remove unused dic entries, `git add` result
- I.freeze: `lefthook-narrow-language-freeze` — reject new dic entries when frozen
- I.suggest: `lefthook-narrow-language-suggest <files>` — print synonyms for unknown words
- I.remote: `lefthook-remote.yml` — pre-commit + pre-push hook definitions
- I.env.DICT: `NARROW_LANGUAGE_DICT` — path to dictionary file
- I.env.GLOB: `NARROW_LANGUAGE_GLOB_INCLUDE` — regex scoping compact file scan
- I.env.FROZEN: `NARROW_LANGUAGE_FROZEN` — `true` to freeze dictionary
- I.env.EXCLUDE: `NARROW_LANGUAGE_EXCLUDE_FILES` — colon-separated exclude patterns for check

## §V INVARIANTS

- V1: Check and compact use identical word extraction pipeline (grep → sed camelCase → lowercase → awk filter)
- V2: Compact never removes words that appear in files matching GLOB_INCLUDE
- V3: Compact auto-stages modified dictionary (`git add`)
- V4: Compact runs at priority 1 (before check at priority 2) — dictionary clean before validation
- V5: Other-language category covers all file types not claimed by a specific language
- V6: GLOB_INCLUDE in compact must match same file extensions as check's glob/exclude for same language
- V7: Freeze only blocks additions — removals (via compact) still allowed
- V8: Word filter: length >= 3, must contain at least one vowel (a/e/i/o/u)

## §T TASKS

| id | st | task | cites |
|----|-----|------|-------|
| T1 | x | check script: report unknown words per file | C6,V1,I.check |
| T2 | x | compact script: remove unused dic entries | C8,V2,V3,I.compact |
| T3 | x | freeze script: reject new entries when frozen | C9,V7,I.freeze |
| T4 | x | suggest script: WordNet synonym lookup | C10,I.suggest |
| T5 | x | flake.nix: four packages + devShell | C1,C2,C3 |
| T6 | x | lefthook-remote.yml: per-language hooks | C4,C7,C8,V4 |
| T7 | x | Add `.jsonc` to other-compact GLOB_INCLUDE | B1,V6 |
| T8 | x | Consumer glob override propagates to compact GLOB_INCLUDE | B2,V6 |

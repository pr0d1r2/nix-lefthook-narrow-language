# nix-lefthook-narrow-language

[![CI](https://github.com/pr0d1r2/nix-lefthook-narrow-language/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-narrow-language/actions/workflows/ci.yml)

Lefthook-compatible narrow-language vocabulary checks, packaged as a Nix flake.

Enforces a controlled vocabulary per file type by checking words against per-language dictionary files. Unknown words fail the check. Includes compaction (removing unused dictionary entries) and synonym suggestion (via WordNet).

## Usage

### As a lefthook remote

Add to your `lefthook.yml`:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-narrow-language
    ref: main
    configs:
      - lefthook-remote.yml
```

Create per-language dictionary files in your repo root:

```bash
touch .narrow-language-nix.dic
touch .narrow-language-shell.dic
touch .narrow-language-python.dic
touch .narrow-language-ruby.dic
touch .narrow-language-javascript.dic
touch .narrow-language-typescript.dic
touch .narrow-language-erb.dic
touch .narrow-language-hcl.dic
touch .narrow-language-terraform.dic
touch .narrow-language-css.dic
touch .narrow-language-scss.dic
touch .narrow-language-markdown.dic
touch .narrow-language-other.dic
```

### As a Nix package

```nix
{
  inputs.nix-lefthook-narrow-language.url = "github:pr0d1r2/nix-lefthook-narrow-language";
}
```

Five packages available:

- `check` — fail on unknown words (`lefthook-narrow-language`)
- `compact` — remove unused dictionary entries (`lefthook-narrow-language-compact`)
- `freeze` — reject new dictionary entries when frozen (`lefthook-narrow-language-freeze`)
- `suggest` — suggest known synonyms for unknown words (`lefthook-narrow-language-suggest`)
- `default` — all four combined

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NARROW_LANGUAGE_DICT` | `.narrow-language.dic` | Path to dictionary file |
| `NARROW_LANGUAGE_GLOB_INCLUDE` | (all files) | Regex to scope compact to matching files |
| `NARROW_LANGUAGE_FROZEN` | (unset) | Set to `true` to freeze a dictionary |

### Freezing dictionaries

Once a dictionary is mature, freeze it to prevent growth. Set `NARROW_LANGUAGE_FROZEN=true` per-language in your `lefthook.yml`:

```yaml
pre-commit:
  commands:
    narrow-language-ruby:
      env:
        NARROW_LANGUAGE_DICT: .narrow-language-ruby.dic
        NARROW_LANGUAGE_FROZEN: "true"
      run: lefthook-narrow-language {staged_files}
```

When frozen, adding new words to the dictionary is rejected. Unknown words must be replaced with known synonyms. Use `lefthook-narrow-language-suggest` to find alternatives.

## How it works

1. Extracts words from source files
2. Splits camelCase and snake_case into individual words
3. Filters short words (< 3 chars) and consonant-only tokens
4. Checks remaining words against the dictionary using hunspell
5. Reports unknown words with counts

The compact script removes dictionary entries no longer used in the codebase. The suggest script uses WordNet to find known synonyms for unknown words.

## Development

```bash
nix develop    # or: direnv allow
bats tests/    # run tests
```

## License

MIT

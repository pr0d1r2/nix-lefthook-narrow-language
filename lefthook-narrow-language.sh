# shellcheck shell=bash
# Lefthook-compatible narrow-language check wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DICT="${NARROW_LANGUAGE_DICT:-.narrow-language.dic}"

if [ ! -f "$DICT" ]; then
    echo "narrow-language: dictionary not found: $DICT" >&2
    echo "  create with: touch $DICT" >&2
    exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'SET UTF-8\n' >"$tmpdir/nl.aff"
printf '0\n' >"$tmpdir/nl.dic"

exit_code=0
total_unknown=0

for file in "$@"; do
    [ -f "$file" ] || continue

    words=$(
        grep -oE '[A-Za-z]+' "$file" |
            sed 's/\([a-z0-9]\)\([A-Z]\)/\1\n\2/g' |
            tr '[:upper:]' '[:lower:]' |
            awk 'length >= 3 && (/a/ || /e/ || /i/ || /o/ || /u/)' |
            sort -u
    ) || true

    [ -z "$words" ] && continue

    unknown=$(
        echo "$words" |
            hunspell -d "$tmpdir/nl" -p "$DICT" -l |
            sort -u
    ) || true

    if [ -n "$unknown" ]; then
        count=$(echo "$unknown" | wc -l | tr -d ' ')
        total_unknown=$((total_unknown + count))
        echo "narrow-language: $file ($count unknown):"
        while IFS= read -r w; do printf '  %s\n' "$w"; done <<<"$unknown"
        exit_code=1
    fi
done

if [ $exit_code -ne 0 ]; then
    echo ""
    echo "narrow-language: $total_unknown unknown word(s) total"
    if [ "${NARROW_LANGUAGE_FROZEN:-}" = "true" ]; then
        echo "  dictionary is FROZEN — replace with known synonyms only"
    else
        echo "  add to $DICT or replace with known synonyms"
    fi
fi

exit $exit_code

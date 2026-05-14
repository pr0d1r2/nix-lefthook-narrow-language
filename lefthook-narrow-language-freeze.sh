# shellcheck shell=bash
# Lefthook-compatible narrow-language freeze guard.
# Fails if dictionary has new words added in staged changes.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DICT="${NARROW_LANGUAGE_DICT:-.narrow-language.dic}"

if [ "${NARROW_LANGUAGE_FROZEN:-}" != "true" ]; then
    exit 0
fi

if [ ! -f "$DICT" ]; then
    exit 0
fi

added=$(git diff --cached -- "$DICT" | grep '^+[^+]' | sed 's/^+//' | sort -u)

if [ -z "$added" ]; then
    exit 0
fi

count=$(echo "$added" | wc -l | tr -d ' ')
echo "narrow-language-freeze: $DICT is FROZEN — $count new word(s) rejected:"
while IFS= read -r w; do printf '  %s\n' "$w"; done <<<"$added"
echo ""
echo "  replace unknown words with known synonyms instead"
echo "  run: lefthook-narrow-language-suggest <files>"
exit 1

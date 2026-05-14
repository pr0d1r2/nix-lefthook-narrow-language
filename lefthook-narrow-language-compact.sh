# shellcheck shell=bash
# Lefthook-compatible narrow-language-compact wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DICT="${NARROW_LANGUAGE_DICT:-.narrow-language.dic}"
if [ ! -f "$DICT" ]; then
    exit 0
fi

dict_basename=$(basename "$DICT")

repo_words=$(
    {
        git ls-files --cached
        git diff --cached --name-only
    } |
        sort -u |
        grep -v "^${dict_basename}$" |
        grep -v '^flake\.lock$' |
        if [ -n "${NARROW_LANGUAGE_GLOB_INCLUDE:-}" ]; then
            grep -E "$NARROW_LANGUAGE_GLOB_INCLUDE"
        else
            cat
        fi |
        while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done |
        xargs grep -ohE '[A-Za-z]+' 2>/dev/null |
        sed 's/\([a-z0-9]\)\([A-Z]\)/\1\n\2/g' |
        tr '[:upper:]' '[:lower:]' |
        awk 'length >= 3 && (/a/ || /e/ || /i/ || /o/ || /u/)' |
        sort -u
)

unused=$(comm -23 <(sort "$DICT") <(echo "$repo_words"))

if [ -z "$unused" ]; then
    exit 0
fi

count=$(echo "$unused" | wc -l | tr -d ' ')
echo "narrow-language-compact: removing $count unused word(s) from $DICT:"
while IFS= read -r w; do printf '  %s\n' "$w"; done <<<"$unused"

grep -vxF "$unused" "$DICT" >"${DICT}.tmp"
mv "${DICT}.tmp" "$DICT"
git add "$DICT"

# shellcheck shell=bash
# Lefthook-compatible narrow-language-suggest wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DICT="${NARROW_LANGUAGE_DICT:-.narrow-language.dic}"

if [ ! -f "$DICT" ]; then
  echo "narrow-language-suggest: dictionary not found: $DICT" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  exit 0
fi

known=$(sort -u "$DICT")

all_unknown=""

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

  unknown=$(comm -23 <(echo "$words") <(echo "$known")) || true

  if [ -n "$unknown" ]; then
    all_unknown=$(printf '%s\n%s' "$all_unknown" "$unknown")
  fi
done

all_unknown=$(echo "$all_unknown" | sort -u | sed '/^$/d')

if [ -z "$all_unknown" ]; then
  exit 0
fi

dict_words=$(sort "$DICT")

while IFS= read -r word; do
  synonyms=""
  for pos in -synsn -synsv -synsa -synsr; do
    raw=$(wn "$word" "$pos" 2>/dev/null) || true
    [ -z "$raw" ] && continue
    found=$(
      echo "$raw" |
        grep -oE '[a-z_]+' |
        tr '_' '\n' |
        tr '[:upper:]' '[:lower:]' |
        awk 'length >= 3 && (/a/ || /e/ || /i/ || /o/ || /u/)' |
        sort -u
    ) || true
    [ -n "$found" ] && synonyms=$(printf '%s\n%s' "$synonyms" "$found")
  done

  matches=$(echo "$synonyms" | sort -u | sed '/^$/d' | comm -12 - <(echo "$dict_words")) || true

  if [ -n "$matches" ]; then
    list=$(echo "$matches" | paste -sd ',' - | sed 's/,/, /g')
    printf '  %s -> %s\n' "$word" "$list"
  else
    printf '  %s (no known synonyms)\n' "$word"
  fi
done <<<"$all_unknown"

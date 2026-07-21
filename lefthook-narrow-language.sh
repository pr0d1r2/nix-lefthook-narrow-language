# shellcheck shell=bash
# Lefthook-compatible narrow-language check wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DICT="${NARROW_LANGUAGE_DICT:-.narrow-language.dic}"

if [ ! -f "$DICT" ]; then
  echo "narrow-language: dictionary not found: $DICT" >&2
  echo "  create with: touch $DICT" >&2
  exit 1
fi

known=$(sort -u "$DICT")

exit_code=0
total_unknown=0

IFS=':' read -ra _nl_exclude_patterns <<<"${NARROW_LANGUAGE_EXCLUDE_FILES:-}"

for file in "$@"; do
  [ -f "$file" ] || continue

  _nl_skip=0
  for _nl_pat in "${_nl_exclude_patterns[@]}"; do
    [ -z "$_nl_pat" ] && continue
    # shellcheck disable=SC2254
    case "$file" in
      $_nl_pat)
        _nl_skip=1
        break
        ;;
    esac
  done
  [ "$_nl_skip" -eq 1 ] && continue

  words=$(
    sed -E 's/[0-9a-f]{40,64}//g' "$file" |
      grep -oE '[A-Za-z]+' |
      sed 's/\([a-z0-9]\)\([A-Z]\)/\1\n\2/g' |
      tr '[:upper:]' '[:lower:]' |
      awk 'length >= 3 && (/a/ || /e/ || /i/ || /o/ || /u/)' |
      sort -u
  ) || true

  [ -z "$words" ] && continue

  unknown=$(comm -23 <(echo "$words") <(echo "$known")) || true

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

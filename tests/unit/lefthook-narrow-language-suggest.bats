#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-narrow-language-suggest.sh"
    TMPDIR="$BATS_TEST_TMPDIR"
    DICT="$TMPDIR/.narrow-language.dic"
    touch "$DICT"
}

require_wordnet() {
    command -v wn >/dev/null 2>&1 || skip "wordnet not available"
}

@test "exits 0 with no arguments" {
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT"
    assert_success
}

@test "exits 1 when dictionary is missing" {
    run env NARROW_LANGUAGE_DICT="$TMPDIR/nonexistent.dic" bash "$SCRIPT" "$TMPDIR/any.sh"
    assert_failure
    assert_output --partial "dictionary not found"
}

@test "exits 0 when all words are known" {
    echo "hello world" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" "world" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_success
    refute_output --partial "->"
}

@test "suggests known synonym for unknown word" {
    require_wordnet
    echo "terse" > "$TMPDIR/sample.sh"
    printf '%s\n' "concise" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_success
    assert_output --partial "terse -> concise"
}

@test "reports no known synonyms when none match" {
    require_wordnet
    echo "xylophone" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_success
    assert_output --partial "no known synonyms"
}

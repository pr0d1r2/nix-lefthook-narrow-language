#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-narrow-language.sh"
    TMPDIR="$BATS_TEST_TMPDIR"
    DICT="$TMPDIR/.narrow-language.dic"
    touch "$DICT"
}

@test "exits 1 when dictionary file is missing" {
    run env NARROW_LANGUAGE_DICT="$TMPDIR/nonexistent.dic" bash "$SCRIPT" "$TMPDIR/any.sh"
    assert_failure
    assert_output --partial "dictionary not found"
}

@test "passes when all words are in dictionary" {
    echo "hello world" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" "world" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_success
}

@test "fails when words are not in dictionary" {
    echo "hello unknown" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
    assert_output --partial "unknown"
}

@test "splits camelCase into separate words" {
    echo "helloWorld" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
    assert_output --partial "world"
}

@test "filters words shorter than 3 characters" {
    echo "if do xy" > "$TMPDIR/sample.sh"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_success
}

@test "skips non-existent file arguments" {
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/no-such-file.sh"
    assert_success
}

@test "reports count of unknown words" {
    echo "alpha bravo charlie" > "$TMPDIR/sample.sh"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
    assert_output --partial "3 unknown"
}

@test "handles snake_case by splitting on underscores" {
    echo "hello_world" > "$TMPDIR/sample.sh"
    printf '%s\n' "hello" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
    assert_output --partial "world"
}

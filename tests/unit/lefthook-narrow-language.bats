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

@test "NARROW_LANGUAGE_EXCLUDE_FILES skips matching file" {
    echo "unknown_word" > "$TMPDIR/baseline.txt"
    run env NARROW_LANGUAGE_DICT="$DICT" \
        NARROW_LANGUAGE_EXCLUDE_FILES="$TMPDIR/baseline.txt" \
        bash "$SCRIPT" "$TMPDIR/baseline.txt"
    assert_success
}

@test "NARROW_LANGUAGE_EXCLUDE_FILES with glob pattern" {
    echo "unknown_word" > "$TMPDIR/baseline.txt"
    run env NARROW_LANGUAGE_DICT="$DICT" \
        NARROW_LANGUAGE_EXCLUDE_FILES="*baseline*" \
        bash "$SCRIPT" "$TMPDIR/baseline.txt"
    assert_success
}

@test "NARROW_LANGUAGE_EXCLUDE_FILES colon-separated patterns" {
    echo "unknown_word" > "$TMPDIR/skip-me.txt"
    echo "hello world" > "$TMPDIR/check-me.sh"
    printf '%s\n' "hello" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" \
        NARROW_LANGUAGE_EXCLUDE_FILES="*skip-me*:*other*" \
        bash "$SCRIPT" "$TMPDIR/skip-me.txt" "$TMPDIR/check-me.sh"
    assert_failure
    refute_output --partial "skip-me"
    assert_output --partial "world"
}

@test "NARROW_LANGUAGE_EXCLUDE_FILES empty means no exclusions" {
    echo "unknown_word" > "$TMPDIR/sample.sh"
    run env NARROW_LANGUAGE_DICT="$DICT" \
        NARROW_LANGUAGE_EXCLUDE_FILES="" \
        bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
}

@test "ignores 40-char SHA-1 hex strings" {
    echo "uses: repo@311740298599dab21f2dc0f83f1d8c974215d197" > "$TMPDIR/ci.yml"
    printf '%s\n' "repo" "uses" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/ci.yml"
    assert_success
}

@test "ignores 64-char SHA-256 hex strings" {
    echo "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" > "$TMPDIR/lock.nix"
    printf '%s\n' "sha" > "$DICT"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/lock.nix"
    assert_success
}

@test "does not strip shorter hex-like words" {
    echo "cafe babe dead" > "$TMPDIR/sample.sh"
    run env NARROW_LANGUAGE_DICT="$DICT" bash "$SCRIPT" "$TMPDIR/sample.sh"
    assert_failure
    assert_output --partial "cafe"
    assert_output --partial "babe"
    assert_output --partial "dead"
}

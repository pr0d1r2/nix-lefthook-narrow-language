#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    REMOTE="$REPO_ROOT/lefthook-remote.yml"
    PRE_COMMIT="$BATS_TEST_TMPDIR/pre-commit.yml"
    awk '/^pre-commit:/{on=1; next} /^[a-z]/{on=0} on' "$REMOTE" > "$PRE_COMMIT"
}

@test "pre-commit has no separate add jobs" {
    run grep -E '^    narrow-language-[a-z]+-add:' "$PRE_COMMIT"
    assert_failure
}

@test "pre-commit has no separate compact jobs" {
    run grep -E '^    narrow-language-[a-z]+-compact:' "$PRE_COMMIT"
    assert_failure
}

@test "every pre-commit check runs compact, then add, then check" {
    checks=$(grep -cE '^    narrow-language-[a-z]+:$' "$PRE_COMMIT")
    chained=$(grep -cF 'run: lefthook-narrow-language-compact && lefthook-narrow-language-add && lefthook-narrow-language {staged_files}' "$PRE_COMMIT")
    [ "$checks" -gt 0 ]
    [ "$checks" -eq "$chained" ]
}

@test "pre-commit checks scope compact and add by GLOB_INCLUDE" {
    checks=$(grep -cE '^    narrow-language-[a-z]+:$' "$PRE_COMMIT")
    scoped=$(grep -cE '^        NARROW_LANGUAGE_GLOB_INCLUDE:' "$PRE_COMMIT")
    [ "$checks" -eq "$scoped" ]
}

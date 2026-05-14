#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-narrow-language-freeze.sh"

    WORK="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$WORK"
    git -C "$WORK" init -q
    git -C "$WORK" config user.email "test@test"
    git -C "$WORK" config user.name "Test"
}

@test "exits 0 when NARROW_LANGUAGE_FROZEN is not set" {
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add .narrow-language.dic

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
}

@test "exits 0 when NARROW_LANGUAGE_FROZEN is false" {
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add .narrow-language.dic

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=false bash '$SCRIPT'"
    assert_success
}

@test "exits 0 when frozen but dictionary missing" {
    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true bash '$SCRIPT'"
    assert_success
}

@test "exits 0 when frozen but no staged dict changes" {
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true bash '$SCRIPT'"
    assert_success
}

@test "fails when frozen and new words staged" {
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add .narrow-language.dic

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true bash '$SCRIPT'"
    assert_failure
    assert_output --partial "FROZEN"
    assert_output --partial "world"
    assert_output --partial "1 new word"
}

@test "exits 0 when frozen and words only removed" {
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add .narrow-language.dic

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true bash '$SCRIPT'"
    assert_success
}

@test "respects per-language NARROW_LANGUAGE_DICT" {
    printf '%s\n' "hello" > "$WORK/.narrow-language-ruby.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language-ruby.dic"
    git -C "$WORK" add .narrow-language-ruby.dic

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true NARROW_LANGUAGE_DICT=.narrow-language-ruby.dic bash '$SCRIPT'"
    assert_failure
    assert_output --partial "FROZEN"
    assert_output --partial ".narrow-language-ruby.dic"
}

@test "suggests using suggest script in output" {
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add .narrow-language.dic

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_FROZEN=true bash '$SCRIPT'"
    assert_failure
    assert_output --partial "lefthook-narrow-language-suggest"
}

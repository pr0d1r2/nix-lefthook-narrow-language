#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-narrow-language-add.sh"

    WORK="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$WORK"
    git -C "$WORK" init -q
    git -C "$WORK" config user.email "test@test"
    git -C "$WORK" config user.name "Test"
}

@test "creates dictionary when missing" {
    echo "hello world" > "$WORK/file.sh"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    [ -f "$WORK/.narrow-language.dic" ]
}

@test "exits 0 when no unknown words" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    refute_output --partial "appending"
}

@test "appends unknown words to dictionary" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "appending 1 word(s)"
    assert_output --partial "world"

    run cat "$WORK/.narrow-language.dic"
    assert_output --partial "hello"
    assert_output --partial "world"
}

@test "does not count dictionary file as word source" {
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "hello" "only_in_dict" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language.dic bash '$SCRIPT'"
    assert_success
    refute_output --partial "appending"
}

@test "excludes flake.lock from word sources" {
    printf '%s\n' "unique" > "$WORK/flake.lock"
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    refute_output --partial "unique"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE scopes to matching files" {
    echo "hello" > "$WORK/file.nix"
    echo "world" > "$WORK/file.sh"
    printf '%s\n' "" > "$WORK/.narrow-language-nix.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-nix.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.nix$' bash '$SCRIPT'"
    assert_success
    assert_output --partial "appending"
    assert_output --partial "hello"
    refute_output --partial "world"
}

@test "without NARROW_LANGUAGE_GLOB_INCLUDE scans all files" {
    echo "hello" > "$WORK/file.nix"
    echo "world" > "$WORK/file.sh"
    printf '%s\n' "" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "hello"
    assert_output --partial "world"
}

@test "auto-excludes own dictionary from word sources" {
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "hello" > "$WORK/.narrow-language-shell.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-shell.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.(sh|bats)$' bash '$SCRIPT'"
    assert_success
    refute_output --partial "appending"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA appends to GLOB_INCLUDE" {
    echo "hello" > "$WORK/file.yml"
    echo "extra" > "$WORK/file.jsonc"
    printf '%s\n' "" > "$WORK/.narrow-language-other.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-other.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.yml\$' NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA='\.jsonc\$' bash '$SCRIPT'"
    assert_success
    assert_output --partial "hello"
    assert_output --partial "extra"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA without GLOB_INCLUDE is ignored" {
    echo "hello" > "$WORK/file.yml"
    echo "extra" > "$WORK/file.jsonc"
    printf '%s\n' "" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA='\.jsonc\$' bash '$SCRIPT'"
    assert_success
    assert_output --partial "hello"
    assert_output --partial "extra"
}

@test "stages dictionary after modification" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    bash -c "cd '$WORK' && bash '$SCRIPT'"

    run git -C "$WORK" diff --cached --name-only
    assert_output --partial ".narrow-language.dic"
}

@test "SHA fragments from 40-char hex strings are not treated as repo words" {
    echo "uses: repo@311740298599dab21f2dc0f83f1d8c974215d197" > "$WORK/ci.yml"
    printf '%s\n' "repo" "uses" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    refute_output --partial "appending"
}

@test "keeps dictionary sorted after adding" {
    echo "zebra apple" > "$WORK/file.sh"
    printf '%s\n' "mango" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    bash -c "cd '$WORK' && bash '$SCRIPT'"

    run cat "$WORK/.narrow-language.dic"
    assert_line --index 0 "apple"
    assert_line --index 1 "mango"
    assert_line --index 2 "zebra"
}

@test "handles staged new files" {
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    echo "world" > "$WORK/new.sh"
    git -C "$WORK" add new.sh

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "world"
}

#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-narrow-language-compact.sh"

    WORK="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$WORK"
    git -C "$WORK" init -q
    git -C "$WORK" config user.email "test@test"
    git -C "$WORK" config user.name "Test"
}

@test "exits 0 when dictionary is missing" {
    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
}

@test "exits 0 when no unused words" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    refute_output --partial "removing"
}

@test "removes unused words from dictionary" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" "orphan" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing 1 unused"
    assert_output --partial "orphan"

    run cat "$WORK/.narrow-language.dic"
    refute_output --partial "orphan"
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
    assert_output --partial "removing"
    assert_output --partial "only"
}

@test "excludes flake.lock from word sources" {
    printf '%s\n' "unique" > "$WORK/flake.lock"
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "hello" "unique" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing"
    assert_output --partial "unique"
}

@test "handles staged file deletions" {
    echo "hello world" > "$WORK/file.sh"
    echo "orphan content" > "$WORK/extra.sh"
    printf '%s\n' "content" "hello" "orphan" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    git -C "$WORK" rm -q extra.sh

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing"
    assert_output --partial "orphan"
    assert_output --partial "content"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE scopes to matching files" {
    echo "hello" > "$WORK/file.nix"
    echo "world" > "$WORK/file.sh"
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language-nix.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-nix.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.nix$' bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing 1 unused"
    assert_output --partial "world"

    run cat "$WORK/.narrow-language-nix.dic"
    assert_output "hello"
}

@test "without NARROW_LANGUAGE_GLOB_INCLUDE scans all files" {
    echo "hello" > "$WORK/file.nix"
    echo "world" > "$WORK/file.sh"
    printf '%s\n' "hello" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    refute_output --partial "removing"
}

@test "auto-excludes own dictionary from word sources" {
    echo "hello" > "$WORK/file.sh"
    printf '%s\n' "hello" "only" > "$WORK/.narrow-language-shell.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-shell.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.(sh|bats)$' bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing"
    assert_output --partial "only"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA appends to GLOB_INCLUDE" {
    echo "hello" > "$WORK/file.yml"
    echo "extra" > "$WORK/file.jsonc"
    printf '%s\n' "extra" "hello" > "$WORK/.narrow-language-other.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_DICT=.narrow-language-other.dic NARROW_LANGUAGE_GLOB_INCLUDE='\.yml\$' NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA='\.jsonc\$' bash '$SCRIPT'"
    assert_success
    refute_output --partial "removing"
}

@test "NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA without GLOB_INCLUDE is ignored" {
    echo "hello" > "$WORK/file.yml"
    echo "extra" > "$WORK/file.jsonc"
    printf '%s\n' "extra" "hello" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && NARROW_LANGUAGE_GLOB_INCLUDE_EXTRA='\.jsonc\$' bash '$SCRIPT'"
    assert_success
    refute_output --partial "removing"
}

@test "stages dictionary after modification" {
    echo "hello world" > "$WORK/file.sh"
    printf '%s\n' "hello" "orphan" "world" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    bash -c "cd '$WORK' && bash '$SCRIPT'"

    run git -C "$WORK" diff --cached --name-only
    assert_output --partial ".narrow-language.dic"
}

@test "SHA fragments from 40-char hex strings are not treated as repo words" {
    echo "uses: repo@311740298599dab21f2dc0f83f1d8c974215d197" > "$WORK/ci.yml"
    printf '%s\n' "dab" "repo" "uses" > "$WORK/.narrow-language.dic"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m init

    run bash -c "cd '$WORK' && bash '$SCRIPT'"
    assert_success
    assert_output --partial "removing 1 unused"
    assert_output --partial "dab"
}

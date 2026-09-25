#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "dev.sh sets BATS_LIB_PATH" {
    run grep 'BATS_LIB_PATH' "$REPO_ROOT/dev.sh"
    assert_success
}

@test "dev.sh installs lefthook when hooks missing" {
    run grep 'lefthook install' "$REPO_ROOT/dev.sh"
    assert_success
}

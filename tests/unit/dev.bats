#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
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

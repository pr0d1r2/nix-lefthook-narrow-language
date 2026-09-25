# The tools this repository ships. The referenced standard only wraps the
# `check` entry point, so the others must come from here: the repo-local
# hooks in lefthook-repo.yml call `-add` and `-compact`.
pkgs:
let
  tool =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ../${name}.sh;
    };
in
rec {
  check = tool "lefthook-narrow-language" (
    with pkgs;
    [
      coreutils
      gnugrep
      gnused
      gawk
    ]
  );
  compact = tool "lefthook-narrow-language-compact" (
    with pkgs;
    [
      coreutils
      gnugrep
      gnused
      gawk
      git
    ]
  );
  add = tool "lefthook-narrow-language-add" (
    with pkgs;
    [
      coreutils
      gnugrep
      gnused
      gawk
      git
    ]
  );
  freeze = tool "lefthook-narrow-language-freeze" (
    with pkgs;
    [
      coreutils
      gnugrep
      gnused
      git
    ]
  );
  suggest = tool "lefthook-narrow-language-suggest" (
    with pkgs;
    [
      coreutils
      gnugrep
      gnused
      gawk
      wordnet
    ]
  );
  # Keep the conventional default package executable so `nix run` works.
  # The other tools remain available through their named package outputs.
  default = check;
}

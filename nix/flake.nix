# Outputs for this flake: the set-and-setting consumer standard plus the
# tools this repository ships (packages.nix). flake.nix only delegates here,
# as the flake-manifest check requires.
{
  self,
  nixpkgs,
  set-and-setting,
  ...
}:
let
  fragments = [
    "base"
    "actions"
    "nix"
    "shell"
    "ascii"
    "bats"
    "markdown"
    "yaml"
  ];
  # set-and-setting's actionlint check still calls sourceByRegex with a
  # scalar regex, while the pinned nixpkgs API accepts a list of regexes.
  compatNixpkgs = nixpkgs // {
    legacyPackages = nixpkgs.lib.mapAttrs (
      _system: pkgs:
      pkgs
      // {
        lib = nixpkgs.lib // {
          sources = nixpkgs.lib.sources // {
            sourceByRegex = src: regex: nixpkgs.lib.sources.sourceByRegex src [ regex ];
          };
        };
      }
    ) nixpkgs.legacyPackages;
  };
  base = set-and-setting.lib.mkConsumerFlake {
    inherit self set-and-setting fragments;
    nixpkgs = compatNixpkgs;
    extraPackages = import ./packages.nix;
    extraChecks = pkgs: {
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    src = ../.;
  };
  # The repo-local hooks (lefthook-repo.yml) run these; the standard's
  # shells and confirm app only carry the fragment wrappers, so the
  # coherence check reports them as not on PATH.
  repoTools =
    system: with self.packages.${system}; [
      add
      compact
      freeze
      suggest
    ];
in
base
// {
  devShells = nixpkgs.lib.mapAttrs (
    system:
    nixpkgs.lib.mapAttrs (
      _name: shell:
      shell.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ repoTools system;
      })
    )
  ) base.devShells;
  apps = nixpkgs.lib.mapAttrs (
    system: apps:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      materialization = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
    in
    apps
    // {
      confirm = set-and-setting.lib.mkConfirmApp {
        inherit pkgs;
        standard = set-and-setting;
        setting = self.packages.${system}.setting;
        materialization = materialization // {
          packages = materialization.packages ++ repoTools system;
        };
        confirmRev = set-and-setting.rev or set-and-setting.dirtyRev or "unknown";
      };
    }
  ) base.apps;
}

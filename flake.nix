{
  description = "Lefthook-compatible narrow-language vocabulary checks";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";
    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-bats-unit = {
      url = "github:pr0d1r2/nix-lefthook-bats-unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-bats-parse = {
      url = "github:pr0d1r2/nix-lefthook-bats-parse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-nix-flake-check = {
      url = "github:pr0d1r2/nix-lefthook-nix-flake-check";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-dev-shell-agentic,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.symlinkJoin {
          name = "lefthook-narrow-language-all";
          paths = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.check
            self.packages.${pkgs.stdenv.hostPlatform.system}.compact
            self.packages.${pkgs.stdenv.hostPlatform.system}.add
            self.packages.${pkgs.stdenv.hostPlatform.system}.suggest
            self.packages.${pkgs.stdenv.hostPlatform.system}.freeze
          ];
        };

        check = pkgs.writeShellApplication {
          name = "lefthook-narrow-language";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gnused
            gawk
          ];
          text = builtins.readFile ./lefthook-narrow-language.sh;
        };

        compact = pkgs.writeShellApplication {
          name = "lefthook-narrow-language-compact";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gnused
            gawk
            git
          ];
          text = builtins.readFile ./lefthook-narrow-language-compact.sh;
        };

        add = pkgs.writeShellApplication {
          name = "lefthook-narrow-language-add";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gnused
            gawk
            git
          ];
          text = builtins.readFile ./lefthook-narrow-language-add.sh;
        };

        freeze = pkgs.writeShellApplication {
          name = "lefthook-narrow-language-freeze";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gnused
            git
          ];
          text = builtins.readFile ./lefthook-narrow-language-freeze.sh;
        };

        suggest = pkgs.writeShellApplication {
          name = "lefthook-narrow-language-suggest";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gnused
            gawk
            wordnet
          ];
          text = builtins.readFile ./lefthook-narrow-language-suggest.sh;
        };
      });

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          shells = nix-dev-shell-agentic.lib.mkShells {
            inherit pkgs inputs;
            ciPackages = [
              self.packages.${system}.check
              self.packages.${system}.compact
              self.packages.${system}.add
              self.packages.${system}.freeze
              self.packages.${system}.suggest
              pkgs.wordnet
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${shells.batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        in
        shells
      );
    };
}

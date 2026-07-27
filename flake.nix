{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs = {
        nixpkgs-lock.follows = "nixpkgs-lock";
      };
    };

    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs = {
        nix-lefthook.follows = "set-and-setting/nix-lefthook";
        nix-lefthook-ascii-only-src.follows = "set-and-setting/nix-lefthook-ascii-only-src";
        nix-lefthook-deadnix-src.follows = "set-and-setting/nix-lefthook-deadnix-src";
        nix-lefthook-editorconfig-checker-src.follows = "set-and-setting/nix-lefthook-editorconfig-checker-src";
        nix-lefthook-execute-permissions-src.follows = "set-and-setting/nix-lefthook-execute-permissions-src";
        nix-lefthook-file-size-check-src.follows = "set-and-setting/nix-lefthook-file-size-check-src";
        nix-lefthook-git-conflict-markers-src.follows = "set-and-setting/nix-lefthook-git-conflict-markers-src";
        nix-lefthook-git-no-local-paths-src.follows = "set-and-setting/nix-lefthook-git-no-local-paths-src";
        nix-lefthook-gitleaks-src.follows = "set-and-setting/nix-lefthook-gitleaks-src";
        nix-lefthook-markdownlint-src.follows = "set-and-setting/nix-lefthook-markdownlint-src";
        nix-lefthook-missing-final-newline-src.follows = "set-and-setting/nix-lefthook-missing-final-newline-src";
        nix-lefthook-nix-no-embedded-shell-src.follows = "set-and-setting/nix-lefthook-nix-no-embedded-shell-src";
        nix-lefthook-nixfmt-src.follows = "set-and-setting/nix-lefthook-nixfmt-src";
        nix-lefthook-shellcheck-src.follows = "set-and-setting/nix-lefthook-shellcheck-src";
        nix-lefthook-shfmt-src.follows = "set-and-setting/nix-lefthook-shfmt-src";
        nix-lefthook-statix-src.follows = "set-and-setting/nix-lefthook-statix-src";
        nix-lefthook-trailing-whitespace-src.follows = "set-and-setting/nix-lefthook-trailing-whitespace-src";
        nix-lefthook-typos-src.follows = "set-and-setting/nix-lefthook-typos-src";
        nix-lefthook-unicode-lint-src.follows = "set-and-setting/nix-lefthook-unicode-lint-src";
        nix-lefthook-yamllint-src.follows = "set-and-setting/nix-lefthook-yamllint-src";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-lock.follows = "nixpkgs-lock";
      };
    };
    nix-lefthook-bats-parse = {
      url = "github:pr0d1r2/nix-lefthook-bats-parse";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-lock.follows = "nixpkgs-lock";
        set-and-setting.follows = "set-and-setting";
      };
    };
    nix-lefthook-bats-unit = {
      url = "github:pr0d1r2/nix-lefthook-bats-unit";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-lock.follows = "nixpkgs-lock";
      };
    };
    nix-lefthook-nix-flake-check = {
      url = "github:pr0d1r2/nix-lefthook-nix-flake-check";
      inputs = {
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic";
        nix-lefthook-bats-unit.follows = "nix-lefthook-bats-unit";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-lock.follows = "nixpkgs-lock";
        set-and-setting.follows = "set-and-setting";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
      });

      devShells = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
          sys = pkgs.stdenv.hostPlatform.system;
        in
        set-and-setting.lib.mkDevShells {
          inherit pkgs;
          basePackages = mat.packages;
          settingHook = ''
            ${self.packages.${sys}.setting}/bin/sync-setting .
            _assemble_out="$(mktemp -d)"
            FRAGMENTS="${builtins.concatStringsSep " " fragments}" \
              out="$_assemble_out" \
              FRAGMENTS_DIR="${set-and-setting}/setting/integrations/lefthook" \
              bash "${set-and-setting}/setting/lib/assemble-lefthook.sh"
            cp -f "$_assemble_out/lefthook.yml" lefthook.yml
            rm -rf "$_assemble_out"
          '';
        }
      );

      checks = forAllSystems (
        pkgs:
        (set-and-setting.lib.checksFor {
          inherit pkgs fragments;
          src = ./.;
        })
        // {
          dep-graph = set-and-setting.lib.mkDepGraphCheck {
            inherit pkgs;
            projectRoot = ./.;
          };
          default = pkgs.runCommand "checks" { } "touch $out";
        }
      );

      apps = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
        in
        {
          confirm = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "confirm";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.diffutils
                  pkgs.findutils
                  pkgs.gawk
                  pkgs.git
                  pkgs.gnugrep
                ]
                ++ mat.packages;
                text =
                  builtins.replaceStrings
                    [
                      "@FRAGMENTS_DIR@"
                      "@ASSEMBLE_SCRIPT@"
                      "@DETECT_SCRIPT@"
                      "@SETTING_SRC@"
                      "@CONFIRM_SCRIPT@"
                      "@CONFIRM_REV@"
                    ]
                    [
                      "${set-and-setting}/setting/integrations/lefthook"
                      "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                      "${set-and-setting}/setting/lib/detect-fragments.sh"
                      "${self.packages.${pkgs.stdenv.hostPlatform.system}.setting}"
                      "${set-and-setting}/lib/confirm.sh"
                      (set-and-setting.rev or "unknown")
                    ]
                    (builtins.readFile ./nix/confirm.sh);
              }
            }/bin/confirm";
          };
        }
      );
    };
}

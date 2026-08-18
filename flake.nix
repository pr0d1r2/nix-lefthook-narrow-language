{
  description = "Lefthook-compatible narrow-language vocabulary checks";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self set-and-setting;
      # set-and-setting's actionlint check still calls sourceByRegex with a
      # scalar regex, while the pinned nixpkgs API accepts a list of regexes.
      nixpkgs = nixpkgs // {
        legacyPackages =
          nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ]
            (
              system:
              nixpkgs.legacyPackages.${system}
              // {
                lib = nixpkgs.lib // {
                  sources = nixpkgs.lib.sources // {
                    sourceByRegex = src: regex: nixpkgs.lib.sources.sourceByRegex src [ regex ];
                  };
                };
              }
            );
      };
      fragments = [
        "base"
        "actions"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      src = ./.;
    };
}

{
  description = "use ~/.config/nvim/ within nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    nightly.url = "github:nix-community/neovim-nightly-overlay";
    flake-compat.url = "github:nix-community/flake-compat";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: function nixpkgs.legacyPackages.${system});
  in rec {
    packages = forAllSystems (pkgs: {
      nightly = inputs.nightly.packages.${pkgs.system}.neovim.overrideAttrs (old: {
        patches = old.pactches or [] ++ [./PATCH.patch];
      });

      stable = pkgs.neovim-unwrapped.overrideAttrs (old: {
        patches = old.pactches or [] ++ [./PATCH.patch];
      });
    });

    makeNightlyNeovimConfig = appname: args: makeNeovimConfig appname (args // {package = packages.${args.pkgs.system}.nightly;});

    makeNeovimConfig = appname: {
      pkgs,
      config,
      package ? null,
      buildInputs ? [],
      doCheck ? true,
      path ? [],
      src,
      ...
    }: let
      _config = pkgs.neovimUtils.makeNeovimConfig (config // {wrapRc = false;});
      _package =
        if package == null
        then packages.${pkgs.system}.stable
        else package;
      wrappedPackage =
        pkgs.wrapNeovimUnstable _package
        _config;
    in
      wrappedPackage
      .overrideAttrs (old: {
        generatedWrapperArgs =
          old.generatedWrapperArgs
          or []
          ++ [
            "--set"
            "NVIM_APPNAME"
            appname
            "--set"
            "NIX_ABS_CONFIG"
            src
            "--prefix"
            "PATH"
            ":"
            (pkgs.lib.makeBinPath path)
          ];
        buildInputs = old.buildInputs or [] ++ buildInputs;
        inherit doCheck;
        nativeCheckInputs = [pkgs.luajitPackages.luacheck];
        checkPhase = ''
          luacheck ${src}/${appname} --only 0

          TOLERABLE_CHECK=1 $out/bin/nvim \
            --headless \
            --cmd "source ${./pre-check.lua}" \
            -c "source ${./post-check.lua}" || (>&2 cat stderr.txt && exit 1)
        '';
      });

    templates = let
      welcomeText = ''
        Rename the `example/` directory, and references to it in `flake.nix`, to something unique for your neovim configuration.

        Read more about configuring neovim with `:h config`.

        Run your neovim configuration with `nix run .#neovim`.
      '';
    in {
      stable = {
        inherit welcomeText;
        path = ./templates/stable;
        description = "A simple stable neovim configuration flake";
      };

      nightly = {
        inherit welcomeText;
        path = ./templates/nightly;
        description = "A simple nightly neovim configuration flake";
      };
    };
  };
}

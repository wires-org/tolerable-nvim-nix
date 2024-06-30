{
  description = "use ~/.config/nvim/ within nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    nightly.url = "github:nix-community/neovim-nightly-overlay";
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
      unstable = inputs.nightly.packages.${pkgs.system}.neovim.overrideAttrs (old: {
        patches = old.pactches or [] ++ [./0001-NIX_ABS_PATH.patch];
      });

      stable = pkgs.neovim.overrideAttrs (old: {
        patches = old.pactches or [] ++ [./0001-NIX_ABS_PATH.patch];
      });
    });

    makeNightlyNeovimConfig = appname: args: makeNeovimConfig appname (args // {package = packages.${args.pkgs.system}.unstable;});

    makeNeovimConfig = appname: {
      pkgs,
      config,
      package ? null,
      buildInputs ? [],
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
          ];
        buildInputs = old.buildInputs or [] ++ buildInputs;
        doCheck = true;
        nativeCheckInputs = [pkgs.luajitPackages.luacheck];
        checkPhase = ''
          luacheck ${src}/${appname} --only 0

          TOLERABLE_CHECK=1 $out/bin/nvim \
            --headless \
            --cmd "source ${./pre-check.lua}" \
            -c "source ${./post-check.lua}" || (>&2 cat stderr.txt && exit 1)
        '';
      });
  };
}

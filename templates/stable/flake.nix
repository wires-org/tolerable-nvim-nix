{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

  inputs.tolerable.url = "github:wires-org/tolerable-nvim-nix";
  inputs.tolerable.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-linux"
          "aarch64-darwin"
        ] (system: function nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          tolerable = {
            inherit pkgs;
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = ./example;
            };
            config = {
              plugins = with pkgs.vimPlugins; [
                catppuccin-nvim
              ];
            };
            path = with pkgs; [
              lua-language-server
            ];
          };
        in
        {
          neovim = inputs.tolerable.makeNeovimConfig "example" tolerable;
          testing = inputs.tolerable.makeNightlyNeovimConfig "example" (
            tolerable
            // {
              testing = true;
            }
          );
        }
      );
    };
}

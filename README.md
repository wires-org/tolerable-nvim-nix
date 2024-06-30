# tolerable-nvim-nix

## Example

```
~/my/neovim/config/
├── MY_APPNAME
│  ├── after
│  │  └── ...
│  ├── ftplugin
│  │  └── ...
│  ├── lua
│  │  └── ...
│  ├── queries
│  │  └── ...
│  └── init.lua
└── flake.nix
```

```nix
{
  description = "my neovim config flake!";

  nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

  inputs.tolerable.url = "path:/home/marsh/projects/tolerable-neovim-nix";
  inputs.tolerable.inputs.nixpkgs.follows = "nixpkgs";

  # Include if you want nightly neovim...
  inputs.nightly.url = "github:nix-community/neovim-nightly-overlay";
  inputs.tolerable.inputs.nightly.follows = "nightly";

  outputs = {
    self,
    nixpkgs,
  } @ inputs: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: {
      # use makeNightlyNeovimConfig for nightly neovim
      neovim = inputs.tolerable.makeNeovimConfig "MY_APPNAME" {
        inherit pkgs;
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = ./MY_APPNAME;
        };
        buildInputs = [
          # runtime accessible packages
          # ... formatters / lsp servers
        ];
        config = {
          # passed to pkgs.neovimUtils.makeNeovimConfig
          plugins = with pkgs.vimPlugins; [
            # ...
          ];
        };
      };
    });
  };
}
```

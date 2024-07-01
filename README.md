# tolerable-nvim-nix

Make your `~/.config/nvim/` portable with nix! This flake patches neovim to support absolute configuration paths, and exposes a nix function to create a package with your configuration baked in.

Read `:h config` for how to configure neovim.

## Getting Started

> [!TIP]
> Add `https://wires.cachix.org` & `wires.cachix.org-1:7XQoG91Bh+Aj01mAJi77Ui5AYyM1uEyV0h1wOomqjpk=` to your `nix.conf` file to prevent building neovim from scratch.

```sh
nix flake init -t github:wires-org/tolerable-nvim-nix#stable

nix flake init -t github:wires-org/tolerable-nvim-nix#nightly
```

You can now alter the `example` directory and use it exactly as you would your normal `~/.config/nvim/`.

## Example

Your configuration directory structure should look something like this:

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

You should change MY_APPNAME to something unique for your neovim configuration. This prevents any collisions with other neovim configurations on systems.

```nix
# use makeNightlyNeovimConfig for nightly neovim
neovim = inputs.tolerable.makeNeovimConfig "MY_APPNAME" {
  inherit pkgs;
  # Use a fileset to prevent rebuilding neovim when files irrelevant to your configuration change.
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./MY_APPNAME;
  };
  buildInputs = [
    # runtime accessible packages
    # ... formatters / lsp servers
  ];
  # passed to pkgs.neovimUtils.makeNeovimConfig
  config = {
    plugins = with pkgs.vimPlugins; [
      # ...
    ];
  };
};
```

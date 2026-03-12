{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    imports = [
      inputs.lazyvim.homeManagerModules.default
    ];

    programs.lazyvim = {
      enable = true;

      extras = {
        lang.nix.enable = true;
        lang.python = {
          enable = true;
        };
        lang.go = {
          enable = true;
          installDependencies = true;        # Install gopls, gofumpt, etc.
          installRuntimeDependencies = true; # Install go compiler
        };
      };

      # Additional packages (optional)
      extraPackages = with pkgs; [
        nil       # Nix LSP
        alejandra      # Nix formatter
      ];

      # Only needed for languages not covered by LazyVim extras
      treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
        wgsl      # WebGPU Shading Language
        templ     # Go templ files
      ];
    };
  };
}

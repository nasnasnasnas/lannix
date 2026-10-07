{inputs, ...}: let
  username = "lavender";
in {
  flake.modules.darwin."${username}" = {
    pkgs,
    lib,
    ...
  }:
    let
      agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in {
    programs.direnv.enable = true;

    environment.systemPackages = with pkgs; [
      _1password-gui
      _1password-cli
      unstable.bun
      git
      ghostty-bin
      unstable.obsidian
      vscode
      nil
      nodejs

      agents.claude-code
      inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default
      agents.opencode2
      agents.junie
      agents.herdr

      prismlauncher
      vesktop

      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rust-rover

      hyfetch
      fastfetch

      tailscale-gui

      jujutsu
    ];
  };
}

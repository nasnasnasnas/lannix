{inputs, ...}: let
  username = "lavender";
in {
  flake.modules.darwin."${username}" = {
    pkgs,
    lib,
    ...
  }: {
    nixpkgs.overlays = [
      inputs.llm-agents.overlays.shared-nixpkgs
    ];

    environment.systemPackages = with pkgs; [
      _1password-gui
      _1password-cli
      unstable.bun
      git
      ghostty-bin
      unstable.obsidian
      fresh-editor
      vscode
      nil
      nodejs

      llm-agents.claude-code
      llm-agents.omp
      llm-agents.opencode
      llm-agents.junie
      llm-agents.herdr

      prismlauncher
      vesktop

      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rust-rover

      hyfetch
      fastfetch
    ];
  };
}

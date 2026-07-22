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
      obsidian
      fresh-editor
      vscode
      nil
      
      llm-agents.claude-code
      llm-agents.omp
      llm-agents.opencode
      llm-agents.junie
      llm-agents.herdr
    ];
  };
}

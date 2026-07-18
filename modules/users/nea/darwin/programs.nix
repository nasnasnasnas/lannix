{inputs, ...}: let
  username = "nea";
in {
  flake.modules.darwin."${username}" = {
    pkgs,
    lib,
    ...
  }: {
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
    ];
  };
}

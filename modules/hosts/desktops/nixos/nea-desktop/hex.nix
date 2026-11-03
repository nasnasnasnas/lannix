{inputs, ...}: {
  # Hex local voice dictation (https://anoma.ly/hex). Update by bumping the tag
  # on the `hex` input; the in-app updater never touches a Nix install.
  flake.modules.homeManager.nea-desktop = {
    imports = [inputs.hex.homeManagerModules.hex];

    programs.hex = {
      enable = true;
      # hex.service starts with niri's graphical-session.target.
      autostart = true;
      # Alt+Space (Hex's default) is the Noctalia launcher in niri.kdl.
      shortcut = "control+option+space";
    };
  };
}

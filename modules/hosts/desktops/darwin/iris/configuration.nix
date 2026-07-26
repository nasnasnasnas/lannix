{inputs, ...}: {
  flake.modules.darwin.iris = {pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      lavender # (adds lavender user + leah's home manager config)
      determinate # using determinate nix; also bridges nix-cache settings into nix.custom.conf
      nea
      inputs.nix-homebrew.darwinModules.nix-homebrew
    ];

    environment.systemPackages = with pkgs; [
      git
      ghostty-bin
    ];

    system.primaryUser = "lavender";

    nix-homebrew = {
      # Install Homebrew under the default prefix
      enable = true;

      # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
      enableRosetta = true;

      # User owning the Homebrew prefix
      user = "lavender";

      # Automatically migrate existing Homebrew installations
      autoMigrate = true;

      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };

      # Optional: Enable fully-declarative tap management
      #
      # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
      mutableTaps = false;
    };

    # nix-darwin equivalent of NixOS system.stateVersion; don't change after install
    system.stateVersion = 6;
  };
}

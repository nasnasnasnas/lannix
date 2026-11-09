{ inputs, ... }: {
  flake.modules.homeManager.leah-desktop-linux = { pkgs, ... }: {
    home.packages = with pkgs; [
      unstable.vscode-fhs
      alacritty
      unstable.element-desktop
      unstable.nheko
      microsoft-edge
      prismlauncher
      lunar-client
      epiphany
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      unstable.floorp-bin
      unstable.ollama
      unstable.kdePackages.kamoso
      cheese
      wl-clipboard
      libreoffice-fresh
      onlyoffice-desktopeditors
      github-desktop
      fuzzel
      waybar
      swayidle
      xeyes
      gimp3
      android-studio
      brightnessctl
      kdePackages.ark
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.kate
      kdePackages.ktexteditor
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      nautilus
      unstable.protonup-qt
      unstable.protontricks
      libnotify
      gpu-screen-recorder
      whitesur-icon-theme
      unstable.flameshot
      bottles
      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rider
      unstable.jetbrains.rust-rover
      unstable.jetbrains.clion
      unstable.jetbrains.phpstorm
      unstable.jetbrains.goland
      unstable.antigravity-ide-fhs
      zotero
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.radaromega
      (unstable.vivaldi.override {
        enableWidevine = true;
        proprietaryCodecs = true;
        inherit widevine-cdm vivaldi-ffmpeg-codecs;
      })
      unstable.obsidian
      inputs.cider.packages.${pkgs.stdenv.hostPlatform.system}.cider
      freecad
      unstable.signal-desktop
    ];
  };
}

{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {
    pkgs,
    lib,
    ...
  }: let
    # The upstream package only patches DT_NEEDED libraries into the rpath.
    # ANGLE dlopens libEGL.so.1 at runtime; without it the GPU process falls
    # back to --use-gl=disabled and WebGL is unavailable.
    helium = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram $out/bin/helium \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.unstable.libGL]}:${pkgs.addDriverRunpath.driverLink}/lib
        '';
    });
    # The locked package omits its zstd and SQLite build dependencies.
    kache = pkgs.unstable.kache.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.unstable.pkg-config];
      buildInputs = (old.buildInputs or []) ++ [pkgs.unstable.zstd pkgs.unstable.sqlite];
    });
    # The latest release is newer than the locked nixpkgs package.
    obsidian = pkgs.unstable.obsidian.overrideAttrs (_: rec {
      version = "1.15.1";
      src = pkgs.fetchurl {
        url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
        hash = "sha256-CQdPBjXs82YwfYCND+wGwBqHoLzGbabTQSbO7ODrhRk=";
      };
    });
  in {
    environment.systemPackages = with pkgs; [
      git
      gh
      unstable.bun
      unstable.nodejs_24
      unstable.vscode-fhs
      alacritty
      # Stable's Toolbox 3.1.0 archive is unavailable; use the locked newer release.
      unstable.jetbrains-toolbox
      unstable.jetbrains.rust-rover
      # Stable predates --repair; keep Vencord recovery available on the desktop.
      unstable.vesktop
      unstable.element-desktop
      unstable.telegram-desktop
      unstable.signal-desktop
      microsoft-edge
      fastfetch
      prismlauncher
      lunar-client
      powertop
      rustup
      # Install only the binaries; compiler wrappers remain opt-in.
      kache.out
      obsidian
      epiphany
      seahorse
      unstable.kdePackages.kamoso
      cheese
      wl-clipboard
      libreoffice-fresh
      clang
      github-desktop
      nvs
      dnsmasq
      inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps
      inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps-launcher
      curl
      dialog
      iproute2
      libnotify
      netcat-openbsd
      unstable.freerdp
      unstable.feishin
      nil
      nixd
      powershell
      xwayland-satellite
      swayidle
      xeyes
      gimp3
      android-studio
      brightnessctl
      ddcutil
      polkit_gnome
      kdePackages.ark
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.kate
      kdePackages.ktexteditor
      nautilus
      unstable.protonup-qt
      unstable.protontricks
      flyctl
      kdePackages.breeze
      kdePackages.qt6ct
      qt6Packages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
      helium
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omp
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    ];
  };
}

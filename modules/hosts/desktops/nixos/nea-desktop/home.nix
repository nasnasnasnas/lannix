{inputs, ...}: {
  flake.modules.homeManager.nea-desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.noctalia.homeModules.default];

    home.stateVersion = lib.mkForce "25.05";
    home.pointerCursor = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze;
      size = 24;
      gtk.enable = true;
    };
    programs.git.signing.key = lib.mkForce "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA24bYEOA0Y0wtbXsra/gG5YXWnFSbnSpmBXp86JmC/";
    programs.git.settings.core.askPass = "";
    programs.gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
    programs.zsh.enable = true;
    programs.ghostty = {
      enable = true;
      systemd.enable = false;
      settings = {
        theme = "noctalia";
        window-theme = "light";
        font-family = "SF Mono";
      };
    };
    programs.fish = {
      interactiveShellInit = ''
        set -U fish_greeting
        # Running terminal/compositor processes can retain pre-rebuild helpers.
        set -gx GIT_ASKPASS ""
        set -gx SSH_ASKPASS ""
        set -gx SSH_ASKPASS_REQUIRE never
      '';
      plugins = [
        {
          name = "nvm";
          src = pkgs.fishPlugins.nvm.src;
        }
      ];
      shellAliases.lannix-rebuild = "sudo nixos-rebuild switch --flake /home/nea/lannix#nea-desktop";
    };
    xdg.configFile."niri/config.kdl".source = ./niri.kdl;
    # Preserve the existing machine-local WinApps credentials when retiring nasnix.
    home.activation.preserveWinapps = lib.hm.dag.entryBefore ["writeBoundary"] ''
      file="${config.xdg.configHome}/winapps/winapps.conf"
      if [ -L "$file" ] && [ -f "$file" ]; then
        run install -m600 "$(readlink -f "$file")" "$file.migrated"
        run mv -f "$file.migrated" "$file"
      fi
    '';
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["helium.desktop"];
        "application/xhtml+xml" = ["helium.desktop"];
        "application/x-extension-htm" = ["helium.desktop"];
        "application/x-extension-html" = ["helium.desktop"];
        "application/x-extension-shtml" = ["helium.desktop"];
        "application/x-extension-xhtml" = ["helium.desktop"];
        "application/x-extension-xht" = ["helium.desktop"];
        "x-scheme-handler/http" = ["helium.desktop"];
        "x-scheme-handler/https" = ["helium.desktop"];
        "x-scheme-handler/about" = ["helium.desktop"];
        "x-scheme-handler/unknown" = ["helium.desktop"];
        "x-scheme-handler/discord" = ["vesktop.desktop"];
        "inode/directory" = ["org.gnome.Nautilus.desktop"];
      };
    };
    # MacTahoe replaces Noctalia's palette-generated GTK and Qt colors; see
    # README.md for what that gives up.
    gtk = {
      enable = true;
      colorScheme = "light";
      # Apple fonts come from fonts.packages in configuration.nix.
      font = {
        name = "SF Pro Text";
        size = 10;
      };
      theme = {
        # MacTahoe's purple variant, rebuilt with the lilac accent.
        name = "MacTahoe-Light-purple";
        package = pkgs.mactahoe-gtk-theme;
      };
      # GTK 4/libadwaita ignores gtk-theme-name; Home Manager imports the
      # theme's gtk-4.0/gtk.css from the user gtk.css instead.
      gtk4.theme = config.gtk.theme;
      # GTK rejects the numeric gtk-interface-color-scheme Home Manager writes
      # and warns on every launch; libadwaita follows the dconf preference.
      gtk4.colorScheme = null;
      # Owning gtk-3.0/gtk.css drops the stale Matugen/Noctalia color
      # overrides that would otherwise repaint MacTahoe.
      gtk3.extraCss = "/* MacTahoe is selected by gtk-theme-name; no overrides. */";
      # macOS window controls: close, minimize, maximize on the left.
      gtk3.extraConfig.gtk-decoration-layout = "close,minimize,maximize:";
      gtk4.extraConfig.gtk-decoration-layout = "close,minimize,maximize:";
    };
    dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "close,minimize,maximize:";
    dconf.settings."org/gnome/desktop/interface" = {
      # GTK on Wayland reads these instead of fontconfig; keep them in sync
      # with fonts.fontconfig in configuration.nix.
      font-antialiasing = "rgba";
      font-rgba-order = "rgb";
      font-hinting = "slight";
      document-font-name = "SF Pro Text 10";
      monospace-font-name = "SF Mono 10";
    };

    # Qt and KDE apps use the MacTahoe Kvantum style (QT_STYLE_OVERRIDE in
    # configuration.nix), with its own palette instead of a qt6ct one.
    qt.kvantum = {
      enable = true;
      themes = [pkgs.mactahoe-kde];
      settings.General.theme = "MacTahoe";
    };
    xdg.configFile."qt6ct/qt6ct.conf".text = lib.generators.toINI {} {
      Appearance = {
        style = "kvantum";
        custom_palette = false;
        # macOS27, packaged in icons.nix.
        icon_theme = config.gtk.iconTheme.name;
      };
      Fonts = {
        general = ''"SF Pro Text,10"'';
        fixed = ''"SF Mono,10"'';
      };
    };
    # KDE apps also read KColorScheme roles (views, selections, headers) from
    # kdeglobals, so merge the matching MacTahoe scheme into it. kdeglobals
    # stays a mutable file because KDE apps store their own settings there.
    home.activation.mactahoeKdeColorScheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      scheme=${pkgs.mactahoe-kde}/share/color-schemes/MacTahoeLight.colors
      kdeglobals="${config.xdg.configHome}/kdeglobals"
      groups=()
      while IFS= read -r line || [ -n "$line" ]; do
        case $line in
          "" | "#"*) ;;
          "["*"]")
            # "[Colors:Header][Inactive]" is a nested group.
            section=''${line#\[}
            section=''${section%\]}
            IFS=$'\x1f' read -r -a parts <<<"''${section//\]\[/$'\x1f'}"
            groups=()
            for part in "''${parts[@]}"; do
              groups+=(--group "$part")
            done
            ;;
          *=*)
            run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$kdeglobals" \
              "''${groups[@]}" --key "''${line%%=*}" -- "''${line#*=}"
            ;;
        esac
      done <"$scheme"
      # Running KDE apps reload their palette (0 = PaletteChanged).
      run ${pkgs.dbus}/bin/dbus-send --session --type=signal /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:0 int32:0 || true
    '';

    # Runtime dependencies of the vn1k/icons Noctalia plugin.
    home.packages = [pkgs.python3 pkgs.zenity];

    programs.noctalia = {
      enable = true;
      # Tooltips follow shell.panel.transparency_mode instead of being opaque;
      # dock.dot_color overrides the theme-colored running-window dots.
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ./noctalia-translucent-tooltips.patch
            ./noctalia-dock-dot-color.patch
          ];
      });
      checkConfig = true;
      settings = {
        shell = {
          font_family = "SF Pro Text";
          time_format = "{:%I:%M %p}";
          clipboard_enabled = true;
          greeter_sync.auto_sync = true;
          panel = {
            transparency_mode = "soft";
            # Attached panels inherit the bar's intentionally low opacity.
            control_center_placement = "floating";
            control_center_position = "top_right";
          };
        };
        location.address = "Indianapolis, IN";
        weather = {
          enabled = true;
          unit = "imperial";
        };
        control_center.calendar.show_week_numbers = true;
        nightlight = {
          enabled = true;
          temperature_night = 4525;
        };
        wallpaper = {
          directory = "/home/nea/Pictures/Wallpapers";
          fill_color = "#b89cff";
        };
        theme = {
          mode = "light";
          source = "community";
          community_palette = "Lilac AMOLED";
          templates.builtin_ids = ["ghostty" "niri"];
        };
        bar.main = {
          position = "top";
          thickness = 48;
          background_opacity = 0.45;
          font_weight = 500;
          color = "#00000099";
          compositor_blur = true;
          margin_edge = 4;
          # Match the windows' outer gap (niri `layout.gaps`).
          margin_ends = 8;
          capsule = false;
          capsule_opacity = 0.15;
          start = ["launcher" "workspaces" "active_window"];
          center = [];
          end = ["media" "privacy" "bluetooth" "volume" "tray" "notifications" "clock" "control-center"];
        };
        widget = {
          active_window = {
            max_length = 240;
            title_scroll = "on_hover";
          };
          clock = {
            format = "{:%a %b %d · %I:%M %p}";
            actions.left = "panel-toggle control-center calendar";
          };
          media = {
            hide_when_no_media = true;
            hide_when_idle = true;
            hide_artist = true;
            max_length = 180;
          };
          bluetooth.show_label = false;
          notifications.hide_when_no_unread = true;
          privacy.hide_inactive = true;
          tray.hidden = ["nm-applet"];
          # Neutral macOS dark grays instead of palette colors. Noctalia picks
          # pill text by fill luminance, so these stay dark enough for white.
          workspaces = {
            hide_when_empty = true;
            change_color_on_hover = false;
            focused_color = "#636366";
            occupied_color = "#48484A";
            empty_color = "#3A3A3C";
          };
        };
        plugins.enabled = ["noctalia/screen_recorder" "noctalia/timer" "vn1k/icons"];
        # macOS-style dock: always visible at the bottom like the macOS default,
        # floating above the screen edge with convex corners, a hairline border,
        # and running-app dots.
        dock = {
          enabled = true;
          position = "bottom";
          background_opacity = 0.35;
          compositor_blur = true;
          border = "#FFFFFF40";
          border_width = 1.0;
          radius = 20;
          concave_edge_corners = false;
          margin_edge = 6;
          main_axis_padding = 8;
          # Every icon also gets a fixed 6 px cell pad on each side, so no
          # extra gap between items.
          icon_size = 60;
          item_spacing = 0;
          auto_hide = false;
          # Windows stop above the visible dock, as with macOS maximized windows.
          reserve_space = true;
          # Show every running app on each output's dock, not just that output's.
          active_monitor_only = false;
          active_scale = 1.0;
          inactive_scale = 1.0;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          magnification = false;
          show_running = true;
          show_dots = true;
          dot_color = "#000000";
          show_instance_count = false;
          # GNOME Files stands in for Finder.
          pinned = ["org.gnome.Nautilus" "com.mitchellh.ghostty" "helium"];
        };
        osd = {
          hide_delay_ms = 2500;
          background_opacity = 0.5;
          position = "bottom_center";
        };
        system.monitor.network_poll_seconds = 1.5;
      };
    };
  };
}

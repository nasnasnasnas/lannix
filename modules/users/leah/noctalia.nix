{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    imports = [
      inputs.noctalia.homeModules.default
    ];

    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON {
        defaultWallpaper = ./nas-flag-wallpaper.png;
        wallpapers = {
          "DP-1" = ./nas-flag-wallpaper.png;
        };
      };
    };

    programs.noctalia-shell.enable = true;
    programs.noctalia-shell.settings = {
      settingsVersion = 53;

      general = {
        avatarImage = ./pfp.jpg;
        lockScreenAnimations = true;
        showHibernateOnLockScreen = true;
        autoStartAuth = true;
        allowPasswordWithFprintd = true;
        passwordChars = true;
      };

      ui = {
        fontDefault = "Sans Serif";
        fontFixed = "JetBrainsMono Nerd Font";
      };

      location = {
        name = "Indianapolis, IN";
        useFahrenheit = true;
        use12hourFormat = true;
        showWeekNumberInCalendar = true;
      };

      wallpaper = {
        overviewEnabled = true;
        directory = "/home/leah/Pictures/Wallpapers";
        fillColor = "#b89cff";
      };

      appLauncher = {
        enableClipboardHistory = true;
        terminalCommand = "ghostty --";
      };

      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };

      dock = {
        floatingRatio = 1.5;
        size = 1.35;
        monitors = ["eDP-1"];
        pinnedApps = ["com.mitchellh.ghostty"];
      };

      osd = {
        location = "bottom";
        autoHideMs = 2500;
        backgroundOpacity = 0.5;
        enabledTypes = [0 1 2 3];
      };

      audio = {
        visualizerType = "wave";
      };

      brightness = {
        enableDdcSupport = true;
      };

      colorSchemes = {
        predefinedScheme = "Tokyo Night";
        darkMode = false;
        schedulingMode = "location";
        matugenSchemeType = "scheme-content";
        generateTemplatesForPredefined = true;
      };

      nightLight = {
        enabled = true;
        nightTemp = "4525";
      };

      plugins = {
        autoUpdate = true;
      };

      idle = {
        enabled = true;
        screenOffTimeout = 300;
        lockTimeout = 360;
      };

      bar = {
        backgroundOpacity = 0.1;
        density = "comfortable";
        outerCorners = false;
        widgets = {
          left = [
            {
              icon = "rocket";
              id = "CustomButton";
              leftClickExec = "noctalia-shell ipc call launcher toggle";
            }
            {
              focusedColor = "secondary";
              hideUnoccupied = true;
              iconScale = 0.9;
              id = "Workspace";
              labelMode = "index";
              pillSize = 0.6;
              showLabelsOnlyWhenOccupied = true;
              showApplications = true;
            }
            {
              compactMode = false;
              iconColor = "secondary";
              id = "SystemMonitor";
              showCpuFreq = true;
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskUsage = true;
              showLoadAverage = true;
              showMemoryUsage = true;
              showNetworkStats = true;
              textColor = "secondary";
              useMonospaceFont = true;
            }
            {
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 250;
              scrollingMode = "hover";
              showIcon = true;
            }
            {
              hideMode = "hidden";
              id = "MediaMini";
              maxWidth = 200;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = true;
              visualizerType = "linear";
            }
          ];
          right = [
            {
              blacklist = [];
              colorizeIcons = false;
              drawerEnabled = false;
              id = "Tray";
              pinned = [];
            }
            {
              hideWhenZero = true;
              id = "NotificationHistory";
              showUnreadBadge = true;
            }
            {
              displayMode = "alwaysShow";
              hideIfNotDetected = true;
              id = "Battery";
            }
            {id = "PowerProfile";}
            {
              displayMode = "alwaysShow";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
            }
            {
              displayMode = "alwaysShow";
              id = "Brightness";
            }
            {
              formatHorizontal = "h:mm:ss AP";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
            }
            {
              formatHorizontal = "ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
            }
            {
              colorizeDistroLogo = false;
              colorizeSystemIcon = "none";
              customIconPath = "";
              enableColorization = false;
              icon = "noctalia";
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {id = "plugin:model-usage";}
            {id = "plugin:privacy-indicator";}
          ];
          center = [];
        };
      };
    };
  };
}

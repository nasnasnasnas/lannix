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
      settingsVersion = 26;

      general = {
        avatarImage = ./pfp.jpg;
        showHibernateOnLockScreen = true;
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

      calendar = {
        cards = [
          {
            enabled = true;
            id = "calendar-header-card";
          }
          {
            enabled = true;
            id = "calendar-month-card";
          }
          {
            enabled = true;
            id = "timer-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
        ];
      };

      screenRecorder = {
        directory = "/home/leah/Videos";
      };

      wallpaper = {
        enabled = true;
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

      systemMonitor = {
        networkPollingInterval = 1500;
      };

      dock = {
        enabled = true;
        displayMode = "auto_hide";
        floatingRatio = 1.5;
        size = 1.35;
        onlySameOutput = true;
        monitors = ["eDP-1"];
        pinnedApps = ["com.mitchellh.ghostty"];
      };

      osd = {
        autoHideMs = 2500;
        backgroundOpacity = 0.5;
        location = "bottom";
        enabledTypes = [0 1 2 3];
      };

      colorSchemes = {
        predefinedScheme = "Tokyo Night";
        darkMode = false;
        schedulingMode = "location";
        matugenSchemeType = "scheme-content";
        generateTemplatesForPredefined = true;
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
              colorizeIcons = false;
              hideUnoccupied = true;
              id = "TaskbarGrouped";
              labelMode = "index";
              showLabelsOnlyWhenOccupied = false;
            }
            {
              diskPath = "/";
              id = "SystemMonitor";
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskUsage = true;
              showMemoryAsPercent = false;
              showMemoryUsage = true;
              showNetworkStats = true;
              usePrimaryColor = true;
              compactMode = false;
              showLoadAverage = true;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 250;
              scrollingMode = "hover";
              showIcon = true;
              useFixedWidth = false;
            }
            {
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 200;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = true;
              useFixedWidth = false;
              visualizerType = "linear";
            }
          ];
          right = [
            {id = "ScreenRecorder";}
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
              deviceNativePath = "";
              displayMode = "alwaysShow";
              id = "Battery";
              warningThreshold = 30;
            }
            {id = "PowerProfile";}
            {
              displayMode = "alwaysShow";
              id = "Volume";
            }
            {
              displayMode = "alwaysShow";
              id = "Brightness";
            }
            {
              formatHorizontal = "h:mm:ss AP";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              useCustomFont = false;
              usePrimaryColor = false;
            }
            {
              formatHorizontal = "ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              useCustomFont = false;
              usePrimaryColor = false;
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
          ];
          center = [];
        };
      };

      nightLight = {
        enabled = true;
        autoSchedule = true;
        nightTemp = "4525";
      };
    };
  };
}

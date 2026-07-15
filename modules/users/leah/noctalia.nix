{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}-linux" = {
    imports = [
      inputs.noctalia.homeModules.default
    ];

    programs.noctalia.enable = true;
    programs.noctalia.settings = {
      backdrop = {
        enabled = true;
      };

      bar = {
        order = ["widgets"];
        widgets = {
          center = [];
          end = [
            "media"
            "tray"
            "notifications"
            "clipboard"
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "group:g1"
            "clock"
            "control-center"
            "session"
          ];
          scale = 1.05;
          start = ["launcher" "workspaces" "active_window"];
          thickness = 36;
          widget_spacing = 8;
          capsule_group = [
            {
              fill = "surface_variant";
              id = "g1";
              members = ["battery" "power_profile"];
              opacity = 1.0;
              padding = 6.0;
            }
          ];
        };
      };

      calendar = {
        enabled = true;
        refresh_minutes = 5;
        account.fastmail = {
          color = "primary";
          name = "Fastmail";
          provider = "custom";
          server_url = "https://caldav.fastmail.com/dav/calendars/user/catgirl@catgirlin.space/4CBFA88C-345D-11EF-8764-EE226724C8BD";
          type = "caldav";
          username = "catgirl@catgirlin.space";
        };
      };

      control_center = {
        shortcuts = [
          {type = "wifi";}
          {type = "bluetooth";}
          {type = "caffeine";}
          {type = "nightlight";}
          {type = "notification";}
          {type = "dark_mode";}
        ];
      };

      desktop_widgets = {
        schema_version = 2;
        widget_order = [
          "desktop-widget-01"
          "desktop-widget-02"
          "desktop-widget-03"
          "desktop-widget-04"
        ];
        grid = {
          cell_size = 64;
          major_interval = 4;
          visible = true;
        };
        widget = {
          "desktop-widget-01" = {
            box_height = 256.0;
            box_width = 576.0;
            cx = 303.0;
            cy = 276.5;
            output = "eDP-1";
            rotation = 0.0;
            type = "weather";
            settings = {
              shadow = false;
            };
          };
          "desktop-widget-02" = {
            box_height = 256.0;
            box_width = 448.0;
            cx = 1455.0;
            cy = 276.5;
            output = "eDP-1";
            rotation = 0.0;
            type = "sysmon";
            settings = {
              shadow = false;
              stat2 = "ram_pct";
            };
          };
          "desktop-widget-03" = {
            box_height = 256.0;
            box_width = 576.0;
            cx = 911.0;
            cy = 276.5;
            output = "eDP-1";
            rotation = 0.0;
            type = "media_player";
            settings = {
              layout = "horizontal";
              shadow = false;
            };
          };
          "desktop-widget-04" = {
            box_height = 128.0;
            box_width = 576.0;
            cx = 911.0;
            cy = 500.5;
            output = "eDP-1";
            rotation = 0.0;
            type = "audio_visualizer";
            settings = {
              aspect_ratio = 6.0;
              bands = 32;
              show_when_idle = true;
            };
          };
        };
      };

      location = {
        auto_locate = true;
        showWeekNumberInCalendar = true;
        use12hourFormat = true;
        useFahrenheit = true;
      };

      lockscreen_widgets = {
        schema_version = 2;
        widget_order = [
          "lockscreen-login-box@DP-7"
          "lockscreen-login-box@eDP-1"
          "lockscreen-login-box@DP-2"
        ];
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
        widget = {
          "lockscreen-login-box@DP-2" = {
            box_height = 0.0;
            box_width = 0.0;
            cx = 1280.0;
            cy = 1317.0;
            output = "DP-2";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_login_button = true;
            };
          };
          "lockscreen-login-box@DP-7" = {
            box_height = 0.0;
            box_width = 0.0;
            cx = 1280.0;
            cy = 1317.0;
            output = "DP-7";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_login_button = true;
            };
          };
          "lockscreen-login-box@eDP-1" = {
            box_height = 0.0;
            box_width = 0.0;
            cx = 847.0;
            cy = 1006.0;
            output = "eDP-1";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_login_button = true;
            };
          };
        };
      };

      nightLight = {
        enabled = true;
        nightTemp = "4525";
      };

      plugins = {
        enabled = ["noctalia/bongocat" "noctalia/screen_recorder" "noctalia/timer"];
      };

      shell = {
        avatar_path = ./pfp.jpg;
        niri_overview_type_to_launch_enabled = true;
        password_style = "random";
        polkit_agent = true;
        screen_time_enabled = true;
        settings_show_advanced = true;
        telemetry_enabled = true;
        ui_scale = 1.05;
        panel = {
          clipboard_placement = "attached";
          launcher_placement = "attached";
          launcher_session_search = true;
          transparency_mode = "glass";
        };
      };

      theme = {
        builtin = "Tokyo-Night";
        mode = "auto";
        wallpaper_scheme = "m3-content";
        templates = {
          builtin_ids = ["btop" "gtk3" "gtk4" "ghostty" "niri" "qt"];
          community_ids = ["zen-browser" "obsidian" "discord" "steam"];
        };
      };

      wallpaper = {
        directory = "/home/leah/Pictures/Wallpapers";
        fillColor = "#b89cff";
        overviewEnabled = true;
        default = {
          path = ./nas-flag-wallpaper.png;
        };
      };

      weather = {
        refresh_minutes = 5;
        unit = "imperial";
      };

      widget = {
        active_window = {
          capsule = true;
        };
        media = {
          capsule = true;
        };
        network = {
          show_label = false;
        };
        workspaces = {
          hide_when_empty = true;
        };
        clock = {
          format = "{:%H:%M:%S}";
        };
      };
    };
  };
}

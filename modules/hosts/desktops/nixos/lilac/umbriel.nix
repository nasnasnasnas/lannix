{ inputs, ... }: {
  flake.modules.nixos.lilac = { config, ... }: {
    imports = [ inputs.umbriel.nixosModules.default ];
    programs.umbriel.enable = true;

    # Rebuild with --flake path:.#lilac while this file is untracked, then
    # select Umbriel in Noctalia Greeter. Niri remains the default session.
    home-manager.users.leah = { pkgs, lib, ... }@hm:
    let
      umbriel = config.programs.umbriel.package;
      ternLauncher = pkgs.writeShellApplication {
        name = "umbriel-tern";
        runtimeInputs = [ pkgs.jq umbriel ];
        text = builtins.readFile ./_umbriel-tern.sh;
      };
      scratchpadLauncher = pkgs.writeShellApplication {
        name = "umbriel-scratchpad-tern";
        runtimeInputs = [ pkgs.coreutils pkgs.tern ];
        text = builtins.readFile ./_umbriel-scratchpad-tern.sh;
      };
      # Keep packaged appearance/shell rules, but discard its shortcut table:
      # merging it would retain conflicting Niri and Umbriel defaults.
      defaults = pkgs.runCommand "umbriel-defaults.toml" { } ''
        ${pkgs.remarshal}/bin/toml2json \
          < ${umbriel}/share/umbriel/config.toml \
          | ${pkgs.jq}/bin/jq 'del(.keybinds)' \
          | ${pkgs.remarshal}/bin/json2toml > "$out"
      '';
    in {
      home.packages = [ ternLauncher ];
      xdg.configFile."umbriel/config.toml".source = (pkgs.formats.toml { }).generate "umbriel-config.toml" {
        include.files = [ "${defaults}" ];
        include.optional.files = [ "${hm.config.xdg.configHome}/umbriel/noctalia.toml" ];
        general.autostart = [ "noctalia" "kdeconnect-indicator" ];
        # Named pads support launch-on-empty. A separate Tern frontend preserves
        # the launch token so its window maps directly into the terminal pad.
        scratchpad = [
          # Named pads replace Umbriel's implicit default. Keep a general
          # scratchpad on Mod+Space, separate from the gear-key terminal pad.
          { name = "general"; }
          {
            name = "terminal";
            spawn_when_empty = lib.getExe scratchpadLauncher;
          }
        ];
        keybinds = import ./_umbriel-keybinds.nix {
          inherit lib;
          ternLauncher = lib.getExe ternLauncher;
        };
        output = {
          eDP-1 = {
            mode = "2880x1920@60.001";
            scale = 1.7;
            position = [ 2560 1100 ];
          };
          "ASUSTek COMPUTER INC ASUS PA279CV W2LMTR019526".position = [ 0 0 ];
          "LG Electronics LG HDR 4K 0x00045AC9".position = [ 2560 (-340) ];
        };
        input = {
          keyboard.numlock_toggle = true;
          touchpad = {
            tap = true;
            disable_while_typing = true;
            natural_scroll = true;
            sensitivity = 0.3;
            click_method = "clickfinger";
            tap_and_drag = false;
          };
          mouse.sensitivity = 0.4;
        };
        layout = {
          mode = "scrolling";
          gap = 16;
          extent_presets = [ 0.33333 0.5 0.66667 0.75 0.9 ];
          scrolling = {
            default_extent_fraction = 0.5;
            center_focused = "never";
          };
        };
        appearance = {
          corner_radius = 0;
          border_width = 4;
          prefer_no_csd = false;
          shadow = {
            softness = 0;
            offset_x = 5;
            offset_y = 5;
          };
          blur = {
            enabled = true;
            optimized = true;
            radius = 3;
            passes = 1;
            saturation = 1.25;
            brightness = 1;
          };
        };
        colors.border = {
          focused = "#b89cff";
          unfocused = "#505050";
        };
        # Preserve Niri's 1Password capture protection using upstream Umbriel.
        window_rule = [{
          match.app_id = "^1password$";
          block_capture = true;
        }];
        # Shortcuts follow Leah's niri.kdl; Umbriel-specific approximations
        # are documented beside their bindings in _umbriel-keybinds.nix.
      };
    };
  };
}

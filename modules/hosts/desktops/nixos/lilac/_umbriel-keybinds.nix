{ lib, ternLauncher }:
let
  once = action: { inherit action; repeat = false; };
  wheel = action: { inherit action; cooldown_ms = 150; };
in
{
  "Mod+Shift+Slash" = once "cheatsheet-toggle";
  "Mod+T" = once "spawn ${ternLauncher} tab";
  "Mod+Shift+T" = once "spawn ${ternLauncher} window";
  "Super+Alt+S" = { action = "spawn pkill orca || exec orca"; allow_when_locked = true; repeat = false; };
  "Mod+O" = once "overview-toggle";
  "Mod+Q" = once "window-close";

  "Mod+Left" = "window-focus-left";
  "Mod+Down" = "window-focus-or-workspace-down";
  "Mod+Up" = "window-focus-or-workspace-up";
  "Mod+Right" = "window-focus-right";
  "Mod+H" = "window-focus-left";
  "Mod+J" = "window-focus-or-workspace-down";
  "Mod+K" = "window-focus-or-workspace-up";
  "Mod+L" = "window-focus-right";
  "Mod+Ctrl+Left" = "column-move-left";
  "Mod+Ctrl+Down" = "window-move-down";
  "Mod+Ctrl+Up" = "window-move-up";
  "Mod+Ctrl+Right" = "column-move-right";
  "Mod+Ctrl+H" = "column-move-left";
  "Mod+Ctrl+J" = "window-move-down";
  "Mod+Ctrl+K" = "window-move-up";
  "Mod+Ctrl+L" = "column-move-right";
  "Mod+Home" = "column-focus-first";
  "Mod+End" = "column-focus-last";
  "Mod+Ctrl+Home" = "column-move-to-first";
  "Mod+Ctrl+End" = "column-move-to-last";

  "Mod+Shift+Left" = "output-focus-left";
  "Mod+Shift+Down" = "output-focus-down";
  "Mod+Shift+Up" = "output-focus-up";
  "Mod+Shift+Right" = "output-focus-right";
  "Mod+Shift+H" = "output-focus-left";
  "Mod+Shift+J" = "output-focus-down";
  "Mod+Shift+K" = "output-focus-up";
  "Mod+Shift+Ctrl+Left" = "column-move-to-output-left";
  "Mod+Shift+Ctrl+Down" = "column-move-to-output-down";
  "Mod+Shift+Ctrl+Up" = "column-move-to-output-up";
  "Mod+Shift+Ctrl+Right" = "column-move-to-output-right";
  "Mod+Shift+Ctrl+H" = "column-move-to-output-left";
  "Mod+Shift+Ctrl+J" = "column-move-to-output-down";
  "Mod+Shift+Ctrl+K" = "column-move-to-output-up";
  "Mod+Shift+Ctrl+L" = "column-move-to-output-right";

  "Mod+Page_Down" = "workspace-next";
  "Mod+Page_Up" = "workspace-previous";
  "Mod+U" = "workspace-next";
  "Mod+I" = "workspace-previous";
  "Mod+Ctrl+Page_Down" = "column-move-to-workspace-next";
  "Mod+Ctrl+Page_Up" = "column-move-to-workspace-previous";
  "Mod+Ctrl+U" = "column-move-to-workspace-next";
  "Mod+Ctrl+I" = "column-move-to-workspace-previous";
  "Mod+Shift+Page_Down" = "workspace-move-down";
  "Mod+Shift+Page_Up" = "workspace-move-up";
  "Mod+Shift+U" = "workspace-move-down";
  "Mod+Shift+I" = "workspace-move-up";

  "Mod+WheelDown" = wheel "workspace-next";
  "Mod+WheelUp" = wheel "workspace-previous";
  "Mod+Ctrl+WheelDown" = wheel "column-move-to-workspace-next";
  "Mod+Ctrl+WheelUp" = wheel "column-move-to-workspace-previous";
  "Mod+WheelRight" = "window-focus-right";
  "Mod+WheelLeft" = "window-focus-left";
  "Mod+Ctrl+WheelRight" = "column-move-right";
  "Mod+Ctrl+WheelLeft" = "column-move-left";
  "Mod+Shift+WheelDown" = "window-focus-right";
  "Mod+Shift+WheelUp" = "window-focus-left";
  "Mod+Ctrl+Shift+WheelDown" = "column-move-right";
  "Mod+Ctrl+Shift+WheelUp" = "column-move-left";

  "Mod+BracketLeft" = "window-consume-or-expel-left";
  "Mod+BracketRight" = "window-consume-or-expel-right";
  # Unlike Niri's expel-bottom action, this acts on the focused window.
  "Mod+Period" = "window-consume-or-expel-right";
  "Mod+R" = "window-cycle-primary-extent";
  "Mod+Shift+R" = "window-cycle-secondary-extent";
  # Umbriel has no automatic height reset or expand-to-available-width action.
  "Mod+Ctrl+R" = "window-set-secondary-extent 0.5";
  "Mod+F" = once "window-toggle-maximize";
  "Mod+Shift+F" = once "window-toggle-fullscreen";
  "Mod+Ctrl+F" = once "window-toggle-maximize-to-edges";
  # No center-visible-columns action: center just the focused column.
  "Mod+Ctrl+C" = "column-center";
  "Mod+Minus" = "window-modify-primary-extent -0.1";
  "Mod+Equal" = "window-modify-primary-extent +0.1";
  "Mod+Shift+Minus" = "window-modify-secondary-extent -0.1";
  "Mod+Shift+Equal" = "window-modify-secondary-extent +0.1";
  "Mod+Ctrl+V" = once "window-toggle-floating";
  "Mod+Shift+V" = once "window-focus-switch-floating";
  "Mod+W" = once "column-toggle-tabbed";

  # Umbriel-specific additions, without replacing Niri-style shortcuts.
  "Mod+Space" = once "scratchpad-toggle general";
  "Mod+Ctrl+Space" = once "window-toggle-scratchpad general";
  "Mod+Alt+D" = once "workspace-set-layout toggle scrolling dwindle master";
  "Mod+Alt+Left" = "column-focus-tab-previous";
  "Mod+Alt+Right" = "column-focus-tab-next";

  # Use Noctalia's capture UI instead of Niri's built-in screenshot UI.
  "Print" = once "spawn noctalia msg screenshot-region";
  "Ctrl+Print" = once "spawn noctalia msg screenshot-fullscreen";
  "Alt+Print" = once "spawn noctalia msg screenshot-window";
  "Mod+Escape" = { action = "shortcuts-inhibit-toggle"; allow_when_inhibited = true; repeat = false; };
  "Mod+Shift+E" = once "session-quit";
  "Ctrl+Alt+Delete" = once "session-quit";
  "Mod+Shift+P" = once "dpms-off";

  "Mod" = once "spawn noctalia msg panel-toggle launcher";
  "Mod+S" = once "spawn noctalia msg panel-toggle control-center";
  "Mod+Comma" = once "spawn noctalia msg settings-toggle";
  "Mod+V" = once "spawn noctalia msg panel-toggle clipboard";
  "Mod+Shift+L" = once "spawn noctalia msg session lock";
  "Mod+Shift+Space" = once "spawn 1password --quick-access";
  "Ctrl+Shift+Space" = once "spawn 1password --quick-access";
  "Alt+Tab" = once "spawn noctalia msg window-switcher hold";
  # Framework gear key controls the auto-launching terminal scratchpad.
  "XF86AudioMedia" = once "scratchpad-toggle terminal";
  "Ctrl+XF86AudioMedia" = once "window-toggle-scratchpad terminal";
  "XF86AudioRaiseVolume" = { action = "spawn noctalia msg volume-up"; allow_when_locked = true; };
  "XF86AudioLowerVolume" = { action = "spawn noctalia msg volume-down"; allow_when_locked = true; };
  "XF86AudioMute" = { action = "spawn noctalia msg volume-mute"; allow_when_locked = true; repeat = false; };
  "XF86AudioPlay" = { action = "spawn noctalia msg media toggle"; allow_when_locked = true; repeat = false; };
  "XF86AudioNext" = { action = "spawn noctalia msg media next"; allow_when_locked = true; };
  "XF86AudioPrev" = { action = "spawn noctalia msg media previous"; allow_when_locked = true; };
  "XF86MonBrightnessUp" = { action = "spawn noctalia msg brightness-up"; allow_when_locked = true; };
  "XF86MonBrightnessDown" = { action = "spawn noctalia msg brightness-down"; allow_when_locked = true; };
  
  "Super+P" = once "spawn noctalia msg caffeine-toggle";
}
// lib.listToAttrs (lib.concatMap (n:
  let number = toString n; in [
    { name = "Mod+${number}"; value = "workspace-switch ${number}"; }
    { name = "Mod+Ctrl+${number}"; value = "column-move-to-workspace ${number}"; }
  ]) (lib.range 1 9))

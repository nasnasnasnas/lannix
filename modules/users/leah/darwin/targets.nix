{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}-darwin" = {lib, ...}: {
      targets.darwin = {
        search = "Ecosia";
        defaults."com.apple.Safari" = {
          IncludeDevelopMenu = true;
          AutoFillPasswords = false;
          ShowOverlayStatusBar = true;
        };

        defaults.NSGlobalDomain = {
          NSAutomaticCapitalizationEnabled = false;
          AppleShowAllExtensions = true;
        };
        defaults."com.apple.menuextra.clock".ShowSeconds = true;
        defaults."com.apple.dock".autohide = true;
        defaults."com.apple.finder".ShowPathBar = true;

        currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
      };
  };
}
